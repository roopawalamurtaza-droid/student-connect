import {createRequire} from 'node:module';
import {readFile,writeFile} from 'node:fs/promises';
const require=createRequire(new URL('../backend/functions/package.json',import.meta.url));
const sharp=require('sharp');
const root=new URL('../',import.meta.url);
const svg=await readFile(new URL('assets/brand/student-connect.svg',root));
async function render(path,size){await sharp(svg).resize(size,size).png().toFile(new URL(path,root).pathname.replace(/^\/([A-Za-z]:)/,'$1'));}
await render('web/favicon.png',48);
for(const size of [192,512])for(const mask of ['', '-maskable'])await render(`web/icons/Icon${mask}-${size}.png`,size);
for(const [density,size] of Object.entries({mdpi:48,hdpi:72,xhdpi:96,xxhdpi:144,xxxhdpi:192}))await render(`android/app/src/main/res/mipmap-${density}/ic_launcher.png`,size);
const catalog=JSON.parse(await readFile(new URL('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',root),'utf8'));
for(const item of catalog.images){if(item.filename)await render(`ios/Runner/Assets.xcassets/AppIcon.appiconset/${item.filename}`,Math.round(parseFloat(item.size)*parseFloat(item.scale)));}
// Windows ICO with a PNG image entry (supported by current Windows versions).
const png=await sharp(svg).resize(256,256).png().toBuffer();
const header=Buffer.alloc(22);header.writeUInt16LE(1,2);header.writeUInt16LE(1,4);header.writeUInt16LE(1,10);header.writeUInt16LE(32,12);header.writeUInt32LE(png.length,14);header.writeUInt32LE(22,18);
await writeFile(new URL('windows/runner/resources/app_icon.ico',root),Buffer.concat([header,png]));
console.log('Student Connect brand icons rendered for web, Android, iOS and Windows.');
