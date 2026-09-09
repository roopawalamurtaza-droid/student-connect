import {createClient} from 'npm:@supabase/supabase-js@2';
import {boundedBody,cors,identity,json} from '../_shared/http.ts';
Deno.serve(async(req)=>{
 if(req.method==='OPTIONS')return new Response('ok',{headers:cors});
 if(req.method!=='POST')return json({error:'Method not allowed'},405);
 try {
  const {admin,user}=await identity(req);const body=await boundedBody(req,4096);
  if(body.confirmDelete!==true || typeof body.password!=='string' || !user.email)throw new Error('Confirm deletion with your password.');
  const verifier=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_ANON_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});
  const {data,error}=await verifier.auth.signInWithPassword({email:user.email,password:body.password});
  if(error || data.user?.id!==user.id)throw new Error('Password verification failed.');
  await verifier.auth.signOut({scope:'local'});
  const {data:role,error:roleError}=await admin.from('user_roles').select('role').eq('user_id',user.id).maybeSingle();if(roleError)throw roleError;
  if(role?.role==='super_admin'){
   const {count,error}=await admin.from('user_roles').select('user_id',{count:'exact',head:true}).eq('role','super_admin');
   if(error || (count??0)<2)throw new Error('Assign another super administrator before deleting this account.');
  }
  // Read the complete asset set in pages; cleanup remains safe to retry.
  let offset=0;const paths:string[]=[];
  while(true){const {data:assets,error}=await admin.from('media_assets').select('path').eq('owner_id',user.id).order('id').range(offset,offset+499);if(error)throw error;paths.push(...assets.map(a=>a.path as string));if(assets.length<500)break;offset+=500;}
  for(let i=0;i<paths.length;i+=100){const {error}=await admin.storage.from('campus-media').remove(paths.slice(i,i+100));if(error)throw error;}
  const {error:deleted}=await admin.auth.admin.deleteUser(user.id);if(deleted)throw deleted;
  return json({ok:true});
 }catch(error){return json({error:error instanceof Error?error.message:'Account deletion could not be completed.'},400);}
});
