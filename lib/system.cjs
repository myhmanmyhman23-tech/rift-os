const os=require('node:os');
const fs=require('node:fs/promises');
const {execFile,spawn}=require('node:child_process');
const {promisify}=require('node:util');
const execute=promisify(execFile);
const {apps}=require('./catalog.cjs');
async function command(file,args,timeout=8000){
  try {const {stdout}=await execute(file,args,{timeout,maxBuffer:1024*1024,windowsHide:true});return {ok:true,text:stdout.trim()};}
  catch(error){return {ok:false,text:String(error.stderr||error.message).slice(0,2000)};}
}
function parseRelease(text){const result={};for(const line of text.split('\n')){const match=line.match(/^([A-Z_]+)=(.*)$/);if(match)result[match[1]]=match[2].replace(/^"|"$/g,'');}return result;}
function parseGPU(text){return text.split('\n').filter(line=>/VGA compatible controller|3D controller|Display controller/.test(line)).map(line=>line.replace(/^.*?(?:VGA compatible controller|3D controller|Display controller):\s*/,''));}
async function inspect({platform=process.platform,run=command,read=fs.readFile}={}){
  const base={platform,preview:platform!=='linux',cpu:os.cpus()[0]?.model||'Не определён',threads:os.cpus().length,memoryGB:Math.round(os.totalmem()/1024**3),kernel:os.release(),arch:os.arch(),gpus:[],vulkan:{ok:false,detail:'Проверка доступна в Linux'},flatpak:false,apps:{},distro:null,secureBoot:null,rebootRequired:false};
  if(base.preview){for(const key of Object.keys(apps))base.apps[key]=false;return base;}
  const [release,pci,vulkan,fp,secure,reboot,driverStatus]=await Promise.all([
    read('/etc/os-release','utf8').catch(()=>''),run('lspci',['-nnk']),run('vulkaninfo',['--summary']),run('flatpak',['list','--app','--columns=application']),run('mokutil',['--sb-state']),read('/var/run/reboot-required','utf8').then(()=>true).catch(()=>false),read('/var/lib/rift-os/driver-status.json','utf8').catch(()=>null)
  ]);
  base.distro=parseRelease(release);base.gpus=pci.ok?parseGPU(pci.text):[];base.vulkan={ok:vulkan.ok,detail:vulkan.ok?vulkan.text.slice(0,4000):vulkan.text};base.flatpak=fp.ok;base.secureBoot=secure.ok?secure.text:null;base.rebootRequired=reboot;
  try{base.driverPreparation=driverStatus?JSON.parse(driverStatus):null;}catch{base.driverPreparation=null;}
  const installed=new Set(fp.ok?fp.text.split(/\s+/):[]);for(const [key,app] of Object.entries(apps))base.apps[key]=installed.has(app.id);return base;
}
function launch(file,args){return new Promise((resolve,reject)=>{const child=spawn(file,args,{detached:true,stdio:'ignore',shell:false,windowsHide:true});child.once('error',reject);child.once('spawn',()=>{child.unref();resolve({pid:child.pid});});});}
function installApp(app,{onOutput=()=>{},spawnProcess=spawn}={}){
  return new Promise((resolve,reject)=>{
    const child=spawnProcess('flatpak',['install','--user','--noninteractive','-y','flathub',app.id],{shell:false,windowsHide:true});
    const timer=setTimeout(()=>{child.kill();reject(new Error('Установка превысила 30 минут. Проверь сеть и повтори попытку.'));},30*60*1000);
    child.stdout.on('data',data=>onOutput(data.toString()));child.stderr.on('data',data=>onOutput(data.toString()));
    child.once('error',error=>{clearTimeout(timer);reject(error);});child.once('close',code=>{clearTimeout(timer);if(code===0)resolve();else reject(new Error(`Flatpak завершился с кодом ${code}. Подробности в журнале.`));});
  });
}
module.exports={inspect,command,parseRelease,parseGPU,launch,installApp};
