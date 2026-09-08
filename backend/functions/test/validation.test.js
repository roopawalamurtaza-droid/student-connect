import {test} from 'node:test';
import assert from 'node:assert/strict';
import {universityEmail,profileSchema,postSchema,eventSchema} from '../validation.js';
test('university domain matching is exact and closed by default',()=>{
  assert.equal(universityEmail('student@university.edu',['university.edu']),true);
  assert.equal(universityEmail('student@university.edu.attacker.com',['university.edu']),false);
  assert.equal(universityEmail('student@university.edu',[]),false);
  assert.equal(universityEmail('student@evil.com',['university.edu']),false);
});
test('profiles reject role injection, invalid semester and unbounded content',()=>{
  const data={name:'Student',enrollment:'123',department:'Engineering',semester:1,bio:'',skills:[]};
  assert.equal(profileSchema.safeParse(data).success,true);
  assert.equal(profileSchema.safeParse({...data,role:'administrator'}).success,false);
  assert.equal(profileSchema.safeParse({...data,semester:0}).success,false);
  assert.equal(profileSchema.safeParse({...data,bio:'a'.repeat(501)}).success,false);
});
test('posts reject empty text, path injection and excessive content',()=>{
  assert.equal(postSchema.safeParse({body:'   '}).success,false);
  assert.equal(postSchema.safeParse({body:'Hello',communityId:'../admin'}).success,false);
  assert.equal(postSchema.safeParse({body:'a'.repeat(3001)}).success,false);
});
test('events reject past dates',()=>{
  assert.equal(eventSchema.safeParse({title:'Meetup',description:'Join us',location:'Campus',startsAt:Date.now()-1000}).success,false);
});
