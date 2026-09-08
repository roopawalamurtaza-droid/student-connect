import {initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore, FieldValue, Timestamp} from 'firebase-admin/firestore';
import {getStorage} from 'firebase-admin/storage';
import {getMessaging} from 'firebase-admin/messaging';
import {onCall, HttpsError} from 'firebase-functions/v2/https';
import {onSchedule} from 'firebase-functions/v2/scheduler';
import {defineString} from 'firebase-functions/params';
import sharp from 'sharp';
import {z} from 'zod';
import {roles,id,profileSchema,postSchema,eventSchema,communitySchema,universityEmail} from './validation.js';
initializeApp();
const db = getFirestore();
const domains = defineString('UNIVERSITY_EMAIL_DOMAINS', {description:'Comma-separated approved university email domains. No wildcard.'});
const now = () => Timestamp.now();
const fail = (message,code='permission-denied') => {throw new HttpsError(code,message);};
const docId = value => id.parse(value);
const moderator = p => ['moderator','administrator'].includes(p.role);
const manager = p => ['representative','moderator','administrator'].includes(p.role);
async function rate(uid) {
  const ref = db.doc(`rateLimits/${uid}`);
  await db.runTransaction(async t => {
    const data = (await t.get(ref)).data();
    const current = Date.now();
    const reset = !data || current-data.since > 60000;
    if (!reset && data.count >= 30) fail('Too many requests. Try again in a minute.','resource-exhausted');
    t.set(ref,{since:reset?current:data.since,count:reset?1:data.count+1,expiresAt:Timestamp.fromMillis(current+86400000)});
  });
}
async function member(request, provision=false) {
  if (!request.auth) fail('Please sign in.','unauthenticated');
  const user = await getAuth().getUser(request.auth.uid);
  if (user.disabled || !user.emailVerified || !universityEmail(user.email,domains.value().split(','))) fail('A verified university email is required.');
  const profile = (await db.doc(`users/${user.uid}`).get()).data();
  if (profile?.suspended) fail('Your account is suspended. Contact your university.');
  if (!profile && !provision) fail('Complete your profile first.','failed-precondition');
  await rate(user.uid);
  return {uid:user.uid, profile, user};
}
async function notify(uid,title,body,link='') {
  await db.collection(`users/${uid}/notifications`).add({title,body,link,read:false,createdAt:now()});
}
async function existing(collection,key) {
  const ref = db.doc(`${collection}/${docId(key)}`);
  const snapshot = await ref.get();
  if (!snapshot.exists) fail('This item no longer exists.','not-found');
  return {ref,data:snapshot.data()};
}
async function ownedCommunity(communityId,uid,p) {
  if (!communityId) return;
  const {data} = await existing('communities',communityId);
  if (!moderator(p) && data.ownerId !== uid) fail('Only the community owner or a moderator can manage its events.');
}
export const mutate = onCall({region:'asia-south1',enforceAppCheck:true,memory:'512MiB',maxInstances:10},async request => {
  try {
    const {action,payload={}}=request.data || {};
    const {uid,profile:p}=await member(request,action==='saveProfile');
    if (action==='saveProfile') {
      const data=profileSchema.parse(payload);
      await db.runTransaction(async t=>{
        const ref=db.doc(`users/${uid}`); const old=(await t.get(ref)).data();
        t.set(ref,{...data,updatedAt:now(),...(!old?{role:'student',suspended:false,photoPath:'',createdAt:now()}: {})},{merge:true});
      });
      return {ok:true};
    }
    if (action==='uploadImage') {
      const input=z.object({base64:z.string().max(4200000),purpose:z.enum(['post','avatar'])}).strict().parse(payload);
      const bytes=Buffer.from(input.base64,'base64');
      if(bytes.length>3*1024*1024) fail('Images must be under 3 MB.','invalid-argument');
      let metadata;
      try { metadata=await sharp(bytes,{limitInputPixels:16000000}).metadata(); }
      catch { fail('Choose a valid JPEG, PNG, or WebP up to 16 megapixels.','invalid-argument'); }
      if(!['jpeg','png','webp'].includes(metadata.format)) fail('Use a JPEG, PNG, or WebP image.','invalid-argument');
      const output=await sharp(bytes,{limitInputPixels:16000000}).rotate().resize({width:1600,height:1600,fit:'inside',withoutEnlargement:true}).jpeg({quality:85}).toBuffer();
      const path=`images/${uid}/${db.collection('uploads').doc().id}.jpg`;
      await getStorage().bucket().file(path).save(output,{contentType:'image/jpeg',resumable:false});
      if(input.purpose==='avatar') await db.doc(`users/${uid}`).update({photoPath:path});
      return {path};
    }
    if(action==='createPost' || action==='editPost') {
      const data=postSchema.parse(action==='editPost'?payload.post:payload);
      if(data.imagePath && !data.imagePath.startsWith(`images/${uid}/`)) fail('Invalid image owner.');
      if(data.communityId && !(await db.doc(`communities/${data.communityId}/members/${uid}`).get()).exists) fail('Join this community before posting.');
      if(action==='editPost') {
        const {ref,data:old}=await existing('posts',payload.id);
        if(old.authorId!==uid) fail('You can only edit your own posts.');
        await ref.update({...data,updatedAt:now()});
      } else await db.collection('posts').add({...data,authorId:uid,authorName:p.name,department:p.department,createdAt:now()});
    } else if(action==='deletePost') {
      const {ref,data}=await existing('posts',payload.id);
      if(data.authorId!==uid && !moderator(p)) fail('You cannot delete this post.');
      await db.recursiveDelete(ref);
    } else if(action==='likePost') {
      const {ref,data}=await existing('posts',payload.id);
      const liked=await db.runTransaction(async t=>{
        const like=ref.collection('likes').doc(uid); const snapshot=await t.get(like);
        if(snapshot.exists) t.delete(like); else t.set(like,{createdAt:now()});
        return !snapshot.exists;
      });
      if(liked && data.authorId!==uid) await notify(data.authorId,'New like',`${p.name} liked your post.`,ref.id);
    } else if(action==='comment') {
      const {ref,data}=await existing('posts',payload.id);
      const body=z.string().trim().min(1).max(1000).parse(payload.body);
      await ref.collection('comments').add({body,authorId:uid,authorName:p.name,createdAt:now()});
      if(data.authorId!==uid) await notify(data.authorId,'New comment',`${p.name} commented on your post.`,ref.id);
    } else if(action==='report') {
      const input=z.object({id,kind:z.enum(['posts','users','events','communities']),reason:z.string().trim().min(5).max(1000)}).strict().parse(payload);
      const {data:target}=await existing(input.kind,input.id);
      await db.collection('reports').add({...input,targetSummary:target.body || target.title || target.name || '',reporterId:uid,status:'open',createdAt:now()});
    } else if(action==='joinCommunity') {
      const {ref}=await existing('communities',payload.id);
      await db.runTransaction(async t=>{const r=ref.collection('members').doc(uid);if((await t.get(r)).exists)t.delete(r);else t.set(r,{createdAt:now()});});
    } else if(action==='saveCommunity') {
      if(!manager(p)) fail('A representative role is required.');
      await db.collection('communities').add({...communitySchema.parse(payload),ownerId:uid,createdAt:now()});
    } else if(action==='saveEvent') {
      if(!manager(p)) fail('An event manager role is required.');
      const event=eventSchema.parse(payload.event); await ownedCommunity(event.communityId,uid,p);
      const data={...event,startsAt:Timestamp.fromMillis(event.startsAt),updatedAt:now()};
      if(payload.id) {
        const {ref,data:old}=await existing('events',payload.id);
        if(old.ownerId!==uid && !moderator(p)) fail('You cannot edit this event.');
        await ref.update(data);
      } else await db.collection('events').add({...data,ownerId:uid,createdAt:now()});
    } else if(action==='deleteEvent') {
      const {ref,data}=await existing('events',payload.id);
      if(data.ownerId!==uid && !moderator(p)) fail('You cannot delete this event.');
      await db.recursiveDelete(ref);
    } else if(action==='registerEvent') {
      const {ref,data}=await existing('events',payload.id);
      if(data.startsAt.toMillis()<=Date.now()) fail('Registration for this event has closed.','failed-precondition');
      await db.runTransaction(async t=>{const r=ref.collection('registrations').doc(uid);if((await t.get(r)).exists)t.delete(r);else t.set(r,{reminderSent:false,createdAt:now()});});
    } else if(action==='readNotification') {
      await db.doc(`users/${uid}/notifications/${docId(payload.id)}`).update({read:true});
    } else if(action==='saveToken') {
      const token=z.string().min(20).max(4096).parse(payload.token);
      const key=Buffer.from(token).toString('base64url').slice(0,1200);
      await db.doc(`users/${uid}/tokens/${key}`).set({token,updatedAt:now()});
    } else if(action==='removeToken') {
      const token=z.string().min(20).max(4096).parse(payload.token);
      await db.doc(`users/${uid}/tokens/${Buffer.from(token).toString('base64url').slice(0,1200)}`).delete();
    } else if(action==='moderateUser') {
      if(p.role!=='administrator') fail('Administrator access required.');
      const input=z.object({id,role:z.enum(roles),suspended:z.boolean()}).strict().parse(payload);
      if(input.id===uid) fail('An administrator cannot change their own access.');
      const {ref}=await existing('users',input.id);
      await db.runTransaction(async t=>{t.update(ref,{role:input.role,suspended:input.suspended});t.set(db.collection('audit').doc(),{actor:uid,action,target:input.id,role:input.role,suspended:input.suspended,createdAt:now()});});
      await getAuth().updateUser(input.id,{disabled:input.suspended});
      if(input.suspended) await getAuth().revokeRefreshTokens(input.id);
    } else if(action==='resolveReport') {
      if(!moderator(p)) fail('Moderator access required.');
      const {ref}=await existing('reports',payload.id);
      await ref.update({status:'resolved',resolvedBy:uid,resolvedAt:now()});
    } else if(action==='announce') {
      if(!moderator(p)) fail('Moderator access required.');
      const input=z.object({title:z.string().trim().min(1).max(120),body:z.string().trim().min(1).max(3000)}).strict().parse(payload);
      await db.collection('announcements').add({...input,authorId:uid,createdAt:now()});
    } else if(action==='deleteAnnouncement') {
      if(!moderator(p)) fail('Moderator access required.');
      const {ref}=await existing('announcements',payload.id);await ref.delete();
    } else fail('Unknown action.','invalid-argument');
    return {ok:true};
  } catch(error) {
    if(error instanceof HttpsError) throw error;
    if(error instanceof z.ZodError) throw new HttpsError('invalid-argument',error.issues.map(i=>i.message).join(', '));
    console.error('Mutation failed',error);
    throw new HttpsError('internal','The request could not be completed. Please try again.');
  }
});
// Persistent in-app reminders plus push delivery when a device has opted in.
export const eventReminders=onSchedule({schedule:'every 15 minutes',region:'asia-south1',maxInstances:1},async()=>{
  const events=await db.collection('events').where('startsAt','>',now()).where('startsAt','<=',Timestamp.fromMillis(Date.now()+3600000)).get();
  for(const event of events.docs) {
    const attendees=await event.ref.collection('registrations').where('reminderSent','==',false).limit(400).get();
    for(const attendee of attendees.docs) {
      const notification=db.doc(`users/${attendee.id}/notifications/event_${event.id}`);
      const claimed=await db.runTransaction(async t=>{const current=await t.get(attendee.ref);if(!current.exists || current.data().reminderSent)return false;t.set(notification,{title:'Event starting soon',body:event.data().title,link:event.id,read:false,createdAt:now()});t.update(attendee.ref,{reminderSent:true});return true;});
      if(!claimed)continue;
      const tokens=await db.collection(`users/${attendee.id}/tokens`).limit(20).get();
      if(tokens.empty)continue;
      try {await getMessaging().sendEachForMulticast({tokens:tokens.docs.map(d=>d.data().token),notification:{title:'Event starting soon',body:event.data().title}});} catch(error){console.error('Push delivery failed',error);}
    }
  }
});
