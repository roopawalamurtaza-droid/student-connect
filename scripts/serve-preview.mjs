import {createServer} from 'node:http';
import {readFile,stat} from 'node:fs/promises';
import {resolve,extname,sep} from 'node:path';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../build/web/',import.meta.url));
const types={'.html':'text/html','.js':'text/javascript','.json':'application/json','.wasm':'application/wasm','.png':'image/png','.ttf':'font/ttf','.otf':'font/otf'};
createServer(async(req,res)=>{
  try {
    const pathname=decodeURIComponent(new URL(req.url,'http://localhost').pathname);
    let path=resolve(root,'.'+pathname);
    if(path!==resolve(root) && !path.startsWith(resolve(root)+sep)){res.writeHead(403);res.end();return;}
    if((await stat(path).catch(()=>null))?.isDirectory())path=resolve(path,'index.html');
    const body=await readFile(path);
    res.writeHead(200,{'Content-Type':types[extname(path)]||'application/octet-stream','Cache-Control':'no-store'});res.end(body);
  }catch {res.writeHead(404);res.end('Not found');}
}).listen(5173,'127.0.0.1',()=>console.log('Student Connect preview: http://localhost:5173'));
