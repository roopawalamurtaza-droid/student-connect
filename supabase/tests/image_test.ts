import {Image} from 'https://deno.land/x/imagescript@1.3.0/mod.ts';
import {sanitizeImage} from '../functions/campus-media/image.ts';
function assert(ok:boolean,message:string){if(!ok)throw new Error(message);}
Deno.test('valid PNG is decoded, resized and re-encoded as JPEG',async()=>{
 const original=new Image(2000,1000);original.fill(0xff9900ff);
 const output=await sanitizeImage(await original.encode());
 assert(output[0]===255 && output[1]===216,'Expected JPEG');
 const decoded=await Image.decode(output);assert(decoded.width===1600 && decoded.height===800,'Expected bounded dimensions');
});
Deno.test('malformed and oversized images are rejected',async()=>{
 for(const input of [new Uint8Array(0),new Uint8Array(3*1024*1024+1),new TextEncoder().encode('<svg onload=alert(1)>')]){
  let rejected=false;try{await sanitizeImage(input);}catch{rejected=true;}assert(rejected,'Unsafe image accepted');
 }
 const bomb=new Uint8Array(24);const view=new DataView(bomb.buffer);view.setUint32(0,0x89504e47);view.setUint32(4,0x0d0a1a0a);view.setUint32(16,100000);view.setUint32(20,100000);
 let rejected=false;try{await sanitizeImage(bomb);}catch{rejected=true;}assert(rejected,'Dimensions should be rejected before decode');
});
