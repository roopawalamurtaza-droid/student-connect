import {boundedBody,cors,identity,json} from '../_shared/http.ts';
import {sanitizeImage} from './image.ts';
Deno.serve(async(req)=>{
 if(req.method==='OPTIONS')return new Response('ok',{headers:cors});
 if(req.method!=='POST')return json({error:'Method not allowed'},405);
 try {
  const {client,admin,user}=await identity(req);
  const {error:gate}=await client.rpc('campus_mutate',{action:'prepareUpload',payload:{}});if(gate)throw gate;
  const body=await boundedBody(req);const purpose=body.purpose;
  if(typeof purpose!=='string' || !['avatar','post','community','club','event'].includes(purpose))throw new Error('Invalid image purpose');
  if(typeof body.base64!=='string')throw new Error('Missing image');
  const bytes=Uint8Array.from(atob(body.base64),c=>c.charCodeAt(0));
  const image=await sanitizeImage(bytes);const path=`${user.id}/${purpose}/${crypto.randomUUID()}.jpg`;
  const {error:upload}=await admin.storage.from('campus-media').upload(path,image,{contentType:'image/jpeg',upsert:false});if(upload)throw upload;
  const {error:record}=await admin.rpc('register_media',{p_user_id:user.id,p_path:path,p_purpose:purpose,p_size:image.length});
  if(record){await admin.storage.from('campus-media').remove([path]);throw record;}
  return json({path});
 }catch(error){return json({error:error instanceof Error?error.message:'The image could not be saved.'},400);}
});
