// ARCHIVED: Supabase owns roles. Do not run this old Firebase admin bootstrap.
throw new Error("Use the Supabase administrator setup in supabase/README.md instead.");
// Run only in a trusted environment using Application Default Credentials.
// Never put a service account private key in the Flutter application.
import {createRequire} from 'node:module';
const require=createRequire(new URL('../backend/functions/package.json',import.meta.url));
const {initializeApp,applicationDefault}=require('firebase-admin/app');
const {getAuth}=require('firebase-admin/auth');
const {getFirestore}=require('firebase-admin/firestore');
const [projectId,uid]=process.argv.slice(2);
if(!projectId || !uid)throw new Error('Usage: node scripts/bootstrap-admin.mjs PROJECT_ID VERIFIED_USER_UID');
initializeApp({credential:applicationDefault(),projectId});
const user=await getAuth().getUser(uid);
if(!user.emailVerified || user.disabled)throw new Error('The initial administrator must have a verified, active account.');
const ref=getFirestore().doc(`users/${uid}`);
if(!(await ref.get()).exists)throw new Error('Complete onboarding in the app before assigning administrator access.');
await ref.update({role:'administrator',suspended:false});
console.log('Initial administrator assigned.');
