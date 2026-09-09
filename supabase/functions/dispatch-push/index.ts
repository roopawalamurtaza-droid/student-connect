import {createClient} from 'npm:@supabase/supabase-js@2';
import {json} from '../_shared/http.ts';
const b64=(bytes:Uint8Array)=>btoa(String.fromCharCode(...bytes)).replace(/=/g,'').replace(/\+/g,'-').replace(/\//g,'_');
const encoded=(o:unknown)=>b64(new TextEncoder().encode(JSON.stringify(o)));
async function accessToken(account:{client_email:string;private_key:string}) {
 const now=Math.floor(Date.now()/1000);
 const input=encoded({alg:'RS256',typ:'JWT'})+'.'+encoded({iss:account.client_email,scope:'https://www.googleapis.com/auth/firebase.messaging',aud:'https://oauth2.googleapis.com/token',iat:now,exp:now+3600});
 const der=Uint8Array.from(atob(account.private_key.replace(/-----[^-]+-----|\s/g,'')),c=>c.charCodeAt(0));
 const key=await crypto.subtle.importKey('pkcs8',der,{name:'RSASSA-PKCS1-v1_5',hash:'SHA-256'},false,['sign']);
 const sig=new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5',key,new TextEncoder().encode(input)));
 const response=await fetch('https://oauth2.googleapis.com/token',{method:'POST',body:new URLSearchParams({grant_type:'urn:ietf:params:oauth:grant-type:jwt-bearer',assertion:input+'.'+b64(sig)})});
 if(!response.ok)throw new Error('Push provider authorization failed');
 return (await response.json()).access_token as string;
}
Deno.serve(async(req)=>{
 const secret=Deno.env.get('PUSH_DISPATCH_SECRET');
 if(!secret || req.headers.get('Authorization')!==`Bearer ${secret}`)return json({error:'Unauthorized'},401);
 if(req.method!=='POST')return json({error:'Method not allowed'},405);
 const raw=Deno.env.get('FCM_SERVICE_ACCOUNT');if(!raw)return json({error:'Push delivery is not configured'},503);
 try {
  const account=JSON.parse(raw) as {client_email:string;private_key:string;project_id:string};
  const token=await accessToken(account);
  const admin=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false}});
  const {data:jobs,error}=await admin.rpc('pending_pushes');if(error)throw error;
  let delivered=0;
  for(const job of jobs as {id:string;title:string;body:string;tokens:string[]}[]){
   let successful=true;
   for(const device of job.tokens){
    // Keep message contents private on lock screens; details remain in the app.
    const response=await fetch(`https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,{method:'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:JSON.stringify({message:{token:device,notification:{title:'Student Connect',body:'You have a new campus notification.'}}})});
    if(!response.ok){const problem=await response.json();const expired=problem.error?.details?.some((d:{errorCode?:string})=>d.errorCode==='UNREGISTERED');if(expired){await admin.from('device_tokens').delete().eq('token',device);}else successful=false;}
   }
   const {error}=await admin.rpc('finish_push',{p_id:job.id,p_delivered:successful});if(error)throw error;
   if(successful)delivered++;
  }
  return json({delivered});
 }catch{return json({error:'Push delivery failed; queued notifications remain available for retry.'},500);}
});
