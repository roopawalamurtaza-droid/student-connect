import { createClient } from 'npm:@supabase/supabase-js@2';
export const cors = {'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS'};
export const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,'Content-Type':'application/json'}});
export async function boundedBody(req:Request,max=4_200_000):Promise<Record<string,unknown>> {
 if(Number(req.headers.get('content-length'))>max)throw new Error('Request too large');
 const reader=req.body?.getReader();if(!reader)throw new Error('Missing request body');
 const chunks:Uint8Array[]=[];let size=0;
 while(true){const {done,value}=await reader.read();if(done)break;size+=value.length;if(size>max){await reader.cancel();throw new Error('Request too large');}chunks.push(value);}
 const bytes=new Uint8Array(size);let offset=0;for(const c of chunks){bytes.set(c,offset);offset+=c.length;}
 const body:unknown=JSON.parse(new TextDecoder().decode(bytes));
 if(!body || typeof body!=='object' || Array.isArray(body))throw new Error('Invalid request');
 return body as Record<string,unknown>;
}
export async function identity(req:Request) {
 const authorization=req.headers.get('Authorization');if(!authorization?.startsWith('Bearer '))throw new Error('Sign in to continue');
 const client=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_ANON_KEY')!,{global:{headers:{Authorization:authorization}},auth:{persistSession:false,autoRefreshToken:false}});
 const {data,error}=await client.auth.getUser();if(error || !data.user)throw new Error('Your session has expired. Sign in again.');
 const admin=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});
 return {client,admin,user:data.user};
}
