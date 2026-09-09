import { PGlite } from '@electric-sql/pglite';
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
import { test, before, after } from 'node:test';
let db;
const alice='00000000-0000-0000-0000-000000000001', bob='00000000-0000-0000-0000-000000000002', outsider='00000000-0000-0000-0000-000000000003', unverified='00000000-0000-0000-0000-000000000004';
async function as(uid,sql,args=[]) {
 await db.exec(`reset role; set role authenticated; select set_config('request.jwt.claim.sub','${uid}',false)`);
 try {return await db.query(sql,args);} finally {await db.exec('reset role');}
}
const mutate=(uid,action,payload)=>as(uid,'select campus_mutate($1,$2::jsonb) as result',[action,JSON.stringify(payload)]);
before(async()=>{
 db=new PGlite();
 await db.exec(`create role anon;create role authenticated;create role service_role bypassrls;create role supabase_auth_admin;
 create schema auth;create table auth.users(id uuid primary key,email text,email_confirmed_at timestamptz,banned_until timestamptz);
 create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
 grant usage on schema auth to authenticated;grant execute on function auth.uid() to authenticated;
 create schema storage;create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
 create table storage.objects(id uuid primary key,bucket_id text,name text);alter table storage.objects enable row level security;
 create publication supabase_realtime;
 `);
 for(const file of ['202609090001_core.sql','202609090002_mutations.sql','202609090003_storage_realtime.sql','202609090005_signup_hook.sql','202609090006_media_and_reminders.sql','202609090007_media_privacy.sql','202609090008_admin_integrity.sql']) {
  const sql=await readFile(new URL('../migrations/'+file,import.meta.url),'utf8');
  // PGlite runs PostgreSQL but not the pg_cron extension; cloud scheduling is checked separately.
  await db.exec(file.includes('006_')?sql.split('-- This database-only')[0]:sql);
 }
 await db.exec(`insert into private.allowed_email_domains values('campus.test');
 insert into auth.users values('${alice}','alice@campus.test',now(),null),('${bob}','bob@campus.test',now(),null),('${outsider}','outside@example.test',now(),null),('${unverified}','pending@campus.test',null,null);`);
 for(const [id,name] of [[alice,'Alice'],[bob,'Bob']]) await mutate(id,'saveProfile',{name,enrollment:name,department:'Engineering',semester:1,bio:'',skills:[]});
});
after(async()=>{await db?.close();});
test('verified domain is required even when bypassing the client',async()=>{
 for(const id of [outsider,unverified]) await assert.rejects(mutate(id,'saveProfile',{name:'Bad',enrollment:id,department:'X',semester:1,skills:[]}),/verified university/);
});
test('client cannot directly write profiles or promote itself',async()=>{
 await assert.rejects(as(alice,`update user_roles set role='super_admin'`),/permission denied/);
 await assert.rejects(mutate(alice,'moderateUser',{id:bob,role:'admin',suspended:false}),/Administrator/);
 await assert.rejects(mutate(alice,'saveProfile',{name:'Alice',role:'admin'}),/Unexpected/);
});
test('post ownership, comments, notifications and blocking',async()=>{
 const post=(await mutate(alice,'createPost',{body:'A real database post'})).rows[0].result.id;
 await assert.rejects(mutate(bob,'editPost',{id:post,post:{body:'Hijack'}}),/own posts/);
 await mutate(bob,'likePost',{id:post});await mutate(bob,'comment',{id:post,body:'Hello'});
 assert.equal((await as(alice,'select * from notifications')).rows.length,2);
 assert.equal((await as(bob,'select * from notifications')).rows.length,0);
 await mutate(bob,'blockUser',{id:alice});assert.equal((await as(bob,'select * from posts')).rows.length,0);
 await assert.rejects(mutate(bob,'comment',{id:post,body:'Blocked'}),/unavailable/);
 await mutate(bob,'unblockUser',{id:alice});await mutate(alice,'deletePost',{id:post});
 assert.equal((await db.query('select * from comments')).rows.length,0);
});
test('event management and private registration',async()=>{
 await assert.rejects(mutate(bob,'saveCommunity',{name:'Bad',description:'Denied',kind:'Club'}),/manager/);
 await db.exec(`update user_roles set role='club_admin' where user_id='${alice}'`);
 const event=(await mutate(alice,'saveEvent',{event:{title:'Workshop',description:'Build together',location:'Library',startsAt:Date.now()+1800000}})).rows[0].result.id;
 await mutate(bob,'registerEvent',{id:event});
 assert.equal((await as(alice,'select * from event_registrations')).rows.length,0);
 assert.equal((await as(bob,'select * from event_registrations')).rows.length,1);
 await db.query('select create_event_reminders()');await db.query('select create_event_reminders()');
 assert.equal((await as(bob,"select * from notifications where kind='event'")).rows.length,1);
});
test('suspension applies immediately to reads and writes',async()=>{
 await db.exec(`update profiles set suspended=true where id='${bob}'`);
 assert.equal((await as(bob,'select * from events')).rows.length,0);
 await assert.rejects(mutate(bob,'createPost',{body:'Bypass'}),/suspended/);
 await db.exec(`update profiles set suspended=false where id='${bob}'`);
});
test('private server RPCs cannot be called by students',async()=>{
 await assert.rejects(as(bob,'select pending_pushes()'),/permission denied/);
 await assert.rejects(as(bob,"select register_media($1,'bad','post',10)",[bob]),/permission denied/);
 await assert.rejects(as(bob,'select * from private.allowed_email_domains'),/permission denied/);
});
test('draft media stays private until attached to a visible post',async()=>{
 const path=alice+'/post/draft.jpg';
 await db.query('select register_media($1,$2,$3,100)',[alice,path,'post']);
 assert.equal((await as(bob,'select * from media_assets')).rows.length,0);
 const post=(await mutate(alice,'createPost',{body:'Shared photo',imagePath:path})).rows[0].result.id;
 assert.equal((await as(bob,'select * from media_assets')).rows.length,1);
 await mutate(alice,'deletePost',{id:post});
 assert.equal((await as(bob,'select * from media_assets')).rows.length,0);
});
test('signup hook rejects unapproved and subdomain spoofing',async()=>{
 for(const email of ['user@evilcampus.test','user@campus.test.evil.test','user@example.test']){
  const result=await db.query('select before_user_created($1) as result',[JSON.stringify({user:{email}})]);
  assert.equal(result.rows[0].result.error.http_code,403);
 }
 const result=await db.query('select before_user_created($1) as result',[JSON.stringify({user:{email:'USER@CAMPUS.TEST'}})]);
 assert.deepEqual(result.rows[0].result,{});
});

test('administrator hierarchy and last-admin guard',async()=>{
 await db.exec(`update user_roles set role='super_admin' where user_id='${alice}'`);
 await mutate(alice,'moderateUser',{id:bob,role:'admin',suspended:false});
 await assert.rejects(mutate(bob,'moderateUser',{id:alice,role:'student',suspended:false}),/super administrator/);
 await assert.rejects(mutate(alice,'moderateUser',{id:alice,role:'student',suspended:false}),/own access/);
 await assert.rejects(db.exec(`update user_roles set role='student' where user_id='${alice}'`),/at least one/);
});
