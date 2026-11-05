// Quatre lectures HTTP locales. N'appelle AUCUNE Edge Function et n'utilise AUCUN client Supabase.
const fs=require('node:fs');const path=require('node:path');const crypto=require('node:crypto');
(async()=>{const core=await require('./tests/load-core.cjs')();
 const result=await core.runPhase2({mode:process.argv.includes('--preview')?'preview':'probe'});
 const digest=crypto.createHash('sha256').update(fs.readFileSync(path.join(__dirname,'_shared/phase2-core.mjs'))).digest('hex');
 const report={core_sha256:digest,origin:'local_node_not_supabase',tested_at_utc:new Date().toISOString(),...result};
 fs.writeFileSync(path.join(__dirname,process.argv.includes('--preview')?'resultat-preview-local.json':'resultat-acces-local.json'),JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify({...report,candidates:report.candidates.length,with_issues:report.candidates.filter(r=>r.issues.length).length,unknown_times:report.candidates.filter(r=>!r.local_time).length},null,2));
})().catch(e=>{console.error(e.message);process.exitCode=1});
