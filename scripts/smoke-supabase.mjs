import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const config=JSON.parse(await readFile(new URL('../config/supabase.local.json',import.meta.url),'utf8'));
const url=config.SUPABASE_URL,headers={apikey:config.SUPABASE_PUBLISHABLE_KEY,'Content-Type':'application/json'};
for(const table of ['profiles','posts','notifications','user_roles']){
 const r=await fetch(`${url}/rest/v1/${table}?select=*`,{headers});
 assert(r.status===401 || r.status===403,`${table} exposed anonymously (${r.status})`);
 console.log(`PASS anonymous access denied: ${table}`);
}
for(const name of ['campus-media','delete-account','dispatch-push']){
 const r=await fetch(`${url}/functions/v1/${name}`,{method:'POST',headers,body:'{}'});
 assert(r.status>=400 && r.status<500,`${name} must reject missing credentials (${r.status})`);
 console.log(`PASS unauthenticated function denied: ${name}`);
}
const result=await fetch(`${url}/auth/v1/signup`,{method:'POST',headers,body:JSON.stringify({email:'student-connect-security-check@example.test',password:crypto.randomUUID()+'Aa1!'})});
const body=await result.json();
assert(result.status===403 && String(body.msg??body.message??'').includes('university'),`Domain hook did not reject request (${result.status} ${JSON.stringify(body)})`);
console.log('PASS server rejects registration outside approved university domain');
