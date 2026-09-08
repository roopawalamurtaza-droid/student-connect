import {readFile} from 'node:fs/promises';
import {test,before,after} from 'node:test';
import {initializeTestEnvironment,assertFails,assertSucceeds} from '@firebase/rules-unit-testing';
import {doc,getDoc,setDoc,collection,getDocs} from 'firebase/firestore';
let env;
before(async()=>{
  env=await initializeTestEnvironment({projectId:'demo-student-connect',firestore:{rules:await readFile('../firestore.rules','utf8')}});
  await env.withSecurityRulesDisabled(async context=>{
    const db=context.firestore();
    await setDoc(doc(db,'users/student'),{name:'Student',role:'student',suspended:false});
    await setDoc(doc(db,'users/staff'),{name:'Moderator',role:'moderator',suspended:false});
    await setDoc(doc(db,'users/suspended'),{name:'Suspended',role:'student',suspended:true});
    await setDoc(doc(db,'posts/post1'),{body:'Campus post'});
    await setDoc(doc(db,'reports/report1'),{reason:'Test concern'});
    await setDoc(doc(db,'users/student/notifications/n1'),{title:'Private'});
    await setDoc(doc(db,'events/event1/registrations/student'),{createdAt:1});
  });
});
after(async()=>env?.cleanup());
test('guests and unverified accounts cannot read campus content',async()=>{
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'posts/post1')));
  await assertFails(getDoc(doc(env.authenticatedContext('student',{email_verified:false}).firestore(),'posts/post1')));
});
test('active member reads feed but cannot write or promote themselves',async()=>{
  const db=env.authenticatedContext('student',{email_verified:true,role:'administrator'}).firestore();
  await assertSucceeds(getDoc(doc(db,'posts/post1')));
  await assertFails(setDoc(doc(db,'users/student'),{role:'administrator'}));
  await assertFails(setDoc(doc(db,'posts/forged'),{authorId:'staff',body:'Forged'}));
  await assertFails(getDoc(doc(db,'reports/report1')));
});
test('server profile role grants moderation visibility; suspended members lose read access',async()=>{
  await assertSucceeds(getDoc(doc(env.authenticatedContext('staff',{email_verified:true}).firestore(),'reports/report1')));
  await assertFails(getDoc(doc(env.authenticatedContext('suspended',{email_verified:true}).firestore(),'posts/post1')));
});
test('notifications and event registrations are private',async()=>{
  const db=env.authenticatedContext('staff',{email_verified:true}).firestore();
  await assertFails(getDoc(doc(db,'users/student/notifications/n1')));
  const member=env.authenticatedContext('student',{email_verified:true}).firestore();
  await assertSucceeds(getDoc(doc(member,'events/event1/registrations/student')));
  await assertFails(getDocs(collection(member,'events/event1/registrations')));
});
