// Test hors réseau et sans base de données. Le code exporté n'est pas modifié ni exécuté comme Edge Function.
// Le HTML est RECONSTITUÉ à partir du texte et des liens visibles : ce n'est pas le HTML HTTP brut FFBB.
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const assert=require('node:assert/strict');
const {stripTypeScriptTypes}=require('node:module');
const dir=__dirname;
const source=fs.readFileSync(path.join(dir,'source/ffbb-sync-export.ts'),'utf8');
const pure=source.slice(source.indexOf('const MONTHS'),source.indexOf('export default'));
const sandbox={URL};
vm.runInNewContext(stripTypeScriptTypes(pure)+'\nglobalThis.audit={parseMatches,extractCompetitionIdentity};',sandbox);
const observations=JSON.parse(fs.readFileSync(path.join(dir,'observations-ffbb-phase2.json')));
const result=[];
for(const team of observations){
 const html=team.rows.map(r=>`#${r.display_number} ${r.round} ${r.date_display} ${r.time_display} ${r.home_away_display} ${r.opponent} <a href="${r.match_url}">0 0</a>`).join(' ');
 const parsed=sandbox.audit.parseMatches(html,team.team_url);
 assert.equal(parsed.length,team.rows.length);
 const identity=sandbox.audit.extractCompetitionIdentity(team.pool_url);
 const tid=team.team_url.split('/').at(-1);
 const keys=parsed.map(r=>[tid,identity.phase,identity.pool,r.round].join('-'));
 const urls=new Set(parsed.map(r=>r.matchUrl));
 assert.equal(urls.size,team.rows.length);
 assert.equal(new Set(keys).size,5);
 for(let i=0;i<parsed.length;i++)assert.equal(parsed[i].matchUrl,team.rows[i].match_url);
 const zero=parsed.filter(r=>r.time==='00h00').length;
 const suspicious=parsed.filter(r=>r.time==='02h00').length;
 const row={team:team.code,visible_rows:parsed.length,official_match_urls:urls.size,synthetic_keys:new Set(keys).size,key_collisions:keys.length-new Set(keys).size,zero_times_not_flagged:zero,suspicious_times_flagged_by_current_rule:suspicious};
 result.push(row);console.log(JSON.stringify(row));
}
assert(source.includes('published: false'));
assert(!/scheduled_local_ffbb\s*:/.test(source));
assert(!/scheduled_local_override/.test(source));
assert(source.includes('scheduled_at_override'));
assert(source.includes('isSuspiciousTime = match.time === "02h00"'));
assert(source.includes('.not("ffbb_team_url", "is", null)'));
assert.equal(result.find(r=>r.team==='U13F').key_collisions,4);
assert.equal(result.find(r=>r.team==='U18M').key_collisions,8);
fs.writeFileSync(path.join(dir,'resultats-parseur.json'),JSON.stringify(result,null,2)+'\n');
console.log('OK : collisions reproduites pour U13F/U18M ; absence de scheduled_local_ffbb et filtre horaire incomplet confirmés dans cet export. Aucun import exécuté.');
