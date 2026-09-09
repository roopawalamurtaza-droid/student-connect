import { Image } from 'https://deno.land/x/imagescript@1.3.0/mod.ts';
export function dimensions(bytes:Uint8Array):[number,number] {
 const view=new DataView(bytes.buffer,bytes.byteOffset,bytes.byteLength);
 if(bytes.length>=24 && view.getUint32(0)===0x89504e47 && view.getUint32(4)===0x0d0a1a0a)return [view.getUint32(16),view.getUint32(20)];
 if(bytes[0]===255 && bytes[1]===216){
  let p=2;
  while(p+4<bytes.length){
   if(bytes[p++]!==255)throw new Error('Invalid JPEG');
   while(bytes[p]===255)p++;
   const marker=bytes[p++];if(marker===0xd9 || marker===0xda)break;
   if(marker===0x01 || (marker>=0xd0 && marker<=0xd7))continue;
   if(p+2>bytes.length)break;const len=view.getUint16(p);
   if(len<2 || p+len>bytes.length)break;
   if([0xc0,0xc1,0xc2].includes(marker) && len>=7)return [view.getUint16(p+5),view.getUint16(p+3)];
   p+=len;
  }
 }
 throw new Error('Choose a JPEG or PNG image.');
}
export async function sanitizeImage(bytes:Uint8Array):Promise<Uint8Array> {
 if(bytes.length>3*1024*1024 || !bytes.length)throw new Error('Choose an image smaller than 3 MB.');
 const [w,h]=dimensions(bytes);if(w<1 || h<1 || w*h>16_000_000)throw new Error('Image must be at most 16 megapixels.');
 const image=await Image.decode(bytes);
 if(image.width!==w || image.height!==h)throw new Error('Invalid image dimensions');
 if(Math.max(w,h)>1600)image.resize(Math.max(1,Math.round(w*1600/Math.max(w,h))),Math.max(1,Math.round(h*1600/Math.max(w,h))));
 const result=await image.encodeJPEG(82);
 if(result.length>3*1024*1024)throw new Error('Image is too large after compression');
 return result;
}
