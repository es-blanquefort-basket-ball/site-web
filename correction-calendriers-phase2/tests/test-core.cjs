const assert=require('node:assert/strict');const fs=require('node:fs');const path=require('node:path');const vm=require('node:vm');const {stripTypeScriptTypes}=require('node:module');
(async()=>{
 const core=await require('./load-core.cjs')();const target=core.selectTargets(['U13F'])[0];
 const url=id=>`https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dfu13-3/match/${id}`;
 const teamHtml=`<html><body><main><a href="${target.poolUrl}">Phase 2</a><a href="${url('200000014904195')}">ancien</a><a href="${url('200000014909695')}">nouveau</a><a href="${url('200000014909695')}">répété</a><a href="https://example.invalid/match/99">externe</a></main></body></html>`;
 function detail(time='17H30',extra='') {return `<html><body><main><a href="${target.poolUrl}">Phase 2</a><h1>POULE A - JOURNÉE 3</h1><span>28 NOV. ${time}</span>${extra}<div><span>AMICALE BASKETTEURS GRADIGNAN</span><b>-</b><b>-</b><span>ENTENTE SPORTIVE BLANQUEFORT</span></div><section>Salle Nom SALLE JEHAN BUHAN Adresse Avenue du Maréchal Juin, 33170 Gradignan Téléphone VALEUR_NON_EXPORTÉE</section></main></body></html>`;}
 assert.equal(core.extractMatchLinks(teamHtml,target).length,2);
 const row=core.parseMatchDetail(detail(),{id:'200000014909695',url:url('200000014909695')},target);
 assert.equal(row.ffbb_match_id,'200000014909695');assert.equal(row.local_date,'2026-11-28');assert.equal(row.local_time,'17:30');assert.equal(row.starts_local,'2026-11-28T17:30:00');assert.equal(row.scheduled_at_ffbb,'2026-11-28T16:30:00.000Z');assert.equal(row.home_away,'away');
 assert(!JSON.stringify(row).includes('VALEUR_NON_EXPORTÉE'));
 const noAddress=core.parseMatchDetail(detail().replace('Avenue du Maréchal Juin, 33170 Gradignan',''),{id:'200000014909695',url:url('200000014909695')},target);
 assert.equal(noAddress.venue_address,null);assert(!JSON.stringify(noAddress).includes('VALEUR_NON_EXPORTÉE'));
 const scored=core.parseMatchDetail(detail().replace('<b>-</b><b>-</b>','<b>42</b><b>40</b>'),{id:'200000014909695',url:url('200000014909695')},target);
 assert(scored.issues.includes('RESULT_REQUIRES_REVIEW'));

 const unknown=core.parseMatchDetail(detail('00H00'),{id:'200000014904195',url:url('200000014904195')},target);
 const fragment=detail().replace('<html><body><main>','<div>').replace('</main></body></html>','</div>').replace(target.poolUrl,new URL(target.poolUrl).pathname);
 assert.equal(core.parseMatchDetail('<link rel=preload href=/test>'+fragment,{id:'200000014909695',url:url('200000014909695')},target).local_time,'17:30');
 assert.equal(core.parseMatchDetail('<html><body><main></main><div hidden>'+fragment+'</div></body></html>',{id:'200000014909695',url:url('200000014909695')},target).local_time,'17:30');
 assert.equal(unknown.local_date,'2026-11-28');assert.equal(unknown.local_time,null);assert.equal(unknown.starts_local,null);
 assert.equal(core.classifyCandidates([row,unknown]).filter(r=>r.issues.includes('MULTIPLE_OFFICIAL_IDS')).length,2);
 assert.throws(()=>core.parseMatchDetail(detail().replace(target.poolUrl,target.poolUrl.replace(target.phase,'1')),{id:'200000014909695',url:url('200000014909695')},target),/PHASE_POOL/);
 assert.throws(()=>core.parseMatchDetail(detail('17H30','ANNULÉ'),{id:'200000014909695',url:url('200000014909695')},target),/STATUS_REVIEW/);
 assert.throws(()=>core.selectTargets(['SG1']),/non autorisées/);
 const blocked=await core.runPhase2({mode:'probe'},async()=>new Response('Forbidden',{status:403}));
 assert.equal(blocked.status,'error');assert.equal(blocked.success,false);assert.equal(blocked.failed_teams,4);assert.equal(blocked.candidates.length,0);
 const shell=await core.runPhase2({mode:'probe',codes:['U13F']},async()=>new Response(`<html><a href="${target.poolUrl}">Phase 2</a>Challenge</html>`,{headers:{'content-type':'text/html'}}));
 assert.equal(shell.status,'error');assert.equal(shell.teams[0].error,'EMPTY_OR_UNPARSEABLE_CALENDAR');
 const fetcher=async u=>new Response(u===target.teamUrl?teamHtml:detail(u.endsWith('200000014904195')?'00H00':'17H30'),{headers:{'content-type':'text/html'}});
 const preview=await core.runPhase2({mode:'preview',codes:['U13F']},fetcher);
 assert.equal(preview.status,'warning');assert.equal(preview.candidates.length,2);assert(preview.candidates.every(r=>r.published===false&&!r.publishable_after_review));
 const details403=await core.runPhase2({mode:'preview',codes:['U13F']},async u=>u===target.teamUrl?fetcher(u):new Response('',{status:403}));
 assert.equal(details403.status,'error');assert.equal(details403.candidates.length,0);
 let calls=0;await core.fetchHtml(target.teamUrl,async()=>{calls++;return new Response('',{status:302,headers:{location:'http://127.0.0.1/private'}})});assert.equal(calls,1);
 const transportPartial=core.summarize([{ok:true},{ok:false}]);assert.equal(transportPartial.status,'warning');assert.equal(transportPartial.success,false);
 // Exécuter le vrai contrôleur candidat avec un client DB simulé. Aucun SDK externe exécuté.
 const dir=path.join(__dirname,'..');let source=fs.readFileSync(path.join(dir,'ffbb-sync/index.ts'),'utf8').replace(/^import .*;\s*$/gm,'').replace('export default','globalThis.handler =');
 const writes=[];const teams=JSON.parse(fs.readFileSync(path.join(dir,'../diagnostic-calendriers-jeunes/teams-lecture-reelle.json')));
 const publicRows=JSON.parse(fs.readFileSync(path.join(dir,'../diagnostic-calendriers-jeunes/public-calendar-lecture-seule.json')));
 for(const code of ['SG1','SG2']){const r=publicRows.find(r=>r.team_code===code);teams.push({code,ffbb_team_id:r.ffbb_team_url.split('/').at(-1),ffbb_team_url:r.ffbb_team_url});}
 const admin={from(table){return {insert(){writes.push(table+'.insert');return {select(){return {single:async()=>({data:{id:'TEST_RUN'},error:null})}}}},select(){return {eq(){return {not:async()=>({data:teams,error:null})}}}},update(payload){writes.push({table,payload});return {eq:async()=>({error:null})}}}}};
 const sandbox={Response,Request,URL,Date,AbortSignal,isPhase2Team:core.isPhase2Team,handleReadOnly:body=>core.handleReadOnly(body,async()=>new Response('',{status:403})),withSupabase:(_,f)=>(req)=>f(req,{supabaseAdmin:admin}),fetch:async()=>new Response('',{status:403})};
 vm.runInNewContext(stripTypeScriptTypes(source),sandbox);
 const probeResponse=await sandbox.handler.fetch(new Request('https://local.test',{method:'POST',body:JSON.stringify({mode:'phase2_probe'})}));assert.equal(probeResponse.status,502);assert.equal(writes.length,0);
 const legacyResponse=await sandbox.handler.fetch(new Request('https://local.test',{method:'POST'}));const legacy=await legacyResponse.json();assert.equal(legacy.success,false);assert.equal(legacy.status,'error');assert.equal(legacy.sourceErrors,5);assert.equal(legacyResponse.status,502);assert(!writes.some(x=>typeof x==='string'&&x.startsWith('matches.')));assert.equal(writes.at(-1).payload.status,'error');
 const badResponse=await sandbox.handler.fetch(new Request('https://local.test',{method:'POST',body:'{'}));assert.equal(badResponse.status,400);
 // Sonde autonome : contrôle du vrai point d'entrée Deno avec serve simulé.
 const probeSource=fs.readFileSync(path.join(dir,'ffbb-source-probe/index.ts'),'utf8').replace(/^import .*;\s*$/gm,'');
 let probeHandler;vm.runInNewContext(stripTypeScriptTypes(probeSource),{Deno:{serve:f=>{probeHandler=f;}},Response,handleReadOnly:body=>core.handleReadOnly(body,async()=>new Response('',{status:403}))});
 assert.equal((await probeHandler(new Request('https://test',{method:'GET'}))).status,405);
 assert.equal((await probeHandler(new Request('https://test',{method:'POST',body:JSON.stringify({mode:'probe'})}))).status,502);
 const candidates=core.classifyCandidates([row]);fs.writeFileSync('/private/tmp/esbb-phase2-candidate-fixture.json',JSON.stringify(candidates));
 console.log('OK : vrais IDs, identité/phase, date locale/UTC, heure inconnue, ambiguïtés non publiables, 403 global/partiel/détail, shell vide, redirection externe, modes sans écriture, ancien success corrigé en error. Tests simulés.');
})().catch(e=>{console.error(e);process.exitCode=1});
