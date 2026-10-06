const http=require('node:http');
const fs=require('node:fs/promises');
const path=require('node:path');
const {randomBytes,randomUUID}=require('node:crypto');
const {apps,games}=require('./lib/catalog.cjs');
const system=require('./lib/system.cjs');
const {version}=require('./package.json');
const assets={'/':['index.html','text/html'],'/app.js':['app.js','application/javascript'],'/style.css':['style.css','text/css']};
function createServer({platform=process.platform,inspect=()=>system.inspect(),install=system.installApp,launch=system.launch}={}){
  const token=randomBytes(32).toString('hex'),jobs=new Map();let busy=false;
  const json=(res,code,data)=>{res.writeHead(code,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store'});res.end(JSON.stringify(data));};
  const server=http.createServer(async(req,res)=>{
    const port=server.address()?.port,origin=`http://127.0.0.1:${port}`;
    res.setHeader('X-Content-Type-Options','nosniff');res.setHeader('X-Frame-Options','DENY');res.setHeader('Referrer-Policy','no-referrer');
    if(![`127.0.0.1:${port}`,`localhost:${port}`].includes(req.headers.host)){json(res,403,{error:'Недопустимый адрес запроса'});return;}
    try {
      let url;try{url=new URL(req.url,origin);}catch{json(res,400,{error:'Некорректный адрес'});return;}
      if(req.method==='GET'&&url.pathname==='/api/status'){json(res,200,{version,token,games,apps,system:await inspect()});return;}
      if(req.method==='GET'&&url.pathname==='/api/jobs'){json(res,200,{jobs:[...jobs.values()]});return;}
      if(req.method==='POST'&&url.pathname==='/api/action'){
        if(req.headers['x-rift-token']!==token||!([origin,`http://localhost:${port}`].includes(req.headers.origin))){json(res,403,{error:'Обнови страницу перед выполнением действия'});return;}
        let data='',tooLarge=false;for await(const chunk of req){data+=chunk;if(data.length>8192){tooLarge=true;break;}}if(tooLarge){json(res,413,{error:'Слишком большой запрос'});return;}
        let body;try{body=JSON.parse(data);}catch{json(res,400,{error:'Некорректный запрос'});return;}
        if(!['install','launch'].includes(body.action)||!Object.hasOwn(apps,body.app)){json(res,400,{error:'Неизвестное действие или приложение'});return;}
        if(platform!=='linux'){json(res,409,{error:'Это предпросмотр в Windows. Установка и запуск доступны после запуска центра в Linux.'});return;}
        const state=await inspect();if(!state.flatpak){json(res,409,{error:'Flatpak ещё не подготовлен. Выполни linux/setup.sh в Linux.'});return;}
        if(body.action==='launch'){
          if(!state.apps[body.app]){json(res,409,{error:'Сначала установи приложение'});return;}
          await launch('flatpak',['run',apps[body.app].id]);json(res,200,{message:'Запрос запуска отправлен приложению'});return;
        }
        if(state.apps[body.app]){json(res,200,{message:'Приложение уже установлено'});return;}
        if(busy){json(res,409,{error:'Дождись окончания текущей установки'});return;}
        busy=true;const job={id:randomUUID(),app:body.app,name:apps[body.app].name,state:'running',log:'',startedAt:new Date().toISOString()};
        if(jobs.size>=20)jobs.delete(jobs.keys().next().value);jobs.set(job.id,job);
        Promise.resolve().then(()=>install(apps[body.app],{onOutput:text=>job.log=(job.log+text).slice(-30000)})).then(()=>{job.state='done';job.log+='\nУстановка завершена.';}).catch(error=>{job.state='failed';job.log+='\n'+error.message;}).finally(()=>{job.finishedAt=new Date().toISOString();busy=false;});
        json(res,202,{jobId:job.id,message:'Установка началась'});return;
      }
      if(req.method==='GET'&&assets[url.pathname]){const [file,type]=assets[url.pathname];const body=await fs.readFile(path.join(__dirname,'public',file));res.setHeader('Content-Security-Policy',"default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'");res.writeHead(200,{'Content-Type':`${type}; charset=utf-8`});res.end(body);return;}
      json(res,404,{error:'Не найдено'});
    }catch(error){json(res,500,{error:error.message});}
  });
  return server;
}
if(require.main===module){const server=createServer();let port=4180;server.on('error',error=>{if(error.code==='EADDRINUSE'&&port<4190)server.listen(++port,'127.0.0.1');else{console.error(error);process.exitCode=1;}});server.on('listening',()=>console.log(`RIFT OS Control Center: http://127.0.0.1:${port}\n${process.platform==='linux'?'Linux mode':'Windows preview — Linux actions disabled'}`));server.listen(port,'127.0.0.1');}
module.exports={createServer};
