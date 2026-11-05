const fs=require('node:fs');const path=require('node:path');const {pathToFileURL}=require('node:url');const os=require('node:os');const crypto=require('node:crypto');
module.exports=async function(){
 const dir=path.join(__dirname,'..');const {requireDeps}=require('./deps.cjs');
 const target=fs.readFileSync(path.join(dir,'_shared/targets.mjs'),'utf8').replace('export const TARGETS','const TARGETS');
 let code=fs.readFileSync(path.join(dir,'_shared/phase2-core.mjs'),'utf8')
  .replace('import { TARGETS } from "./targets.mjs";',target)
  .replace('npm:linkedom@0.18.12',pathToFileURL(requireDeps.resolve('linkedom')).href)
  .replace('npm:luxon@3.7.2',pathToFileURL(requireDeps.resolve('luxon')).href);
 const temp=path.join(os.tmpdir(),'esbb-phase2-core-'+crypto.createHash('sha256').update(code).digest('hex')+'.mjs');fs.writeFileSync(temp,code);return import(pathToFileURL(temp).href);
};
