import assert from 'node:assert/strict';
import { stages, liveChange, normalizeLive, publicLive, canShowScore } from '../../app/gestion-matchs-live.js';
import { createApi } from '../../app/gestion-matchs-core.js';
let count = 0;
const test = async (name, action) => { await action(); count++; console.log(`OK Live : ${name}`); };
const m1 = { id:'M1',teamId:'T1',teamLabel:'TEST M1',competitionCode:'DMU11-4-P2',scorePolicy:'numeric',stage:0,clubScore:null,opponentScore:null,revision:0 };
const m2 = { ...m1,id:'M2',teamId:'T2',competitionCode:'DMU11-10-P2',scorePolicy:'minibasket-no-score' };
const u9 = { ...m1,id:'U9',teamId:'T9',competitionCode:'TEST_U9',scorePolicy:'u9-no-score' };
await test('sept étapes validées dans l’ordre', () => { assert.equal(stages.length,7); assert.equal(stages[3],'Mi-temps'); assert.equal(stages[6],'Match terminé'); });
await test('aller et retour entre toutes les étapes sans score', () => {
 let row={...m1}; for(let i=1;i<7;i++) row={...row,...liveChange(row,{stage:i})};
 for(let i=5;i>=0;i--) row={...row,...liveChange(row,{stage:i})};
 assert.equal(row.stage,0); assert.equal(row.clubScore,null);
 assert.throws(()=>liveChange(row,{stage:-1})); assert.throws(()=>liveChange(row,{stage:7}));
});
await test('changement d’étape conserve le score', () => { const row={...m1,clubScore:12,opponentScore:10}; assert.deepEqual({...row,...liveChange(row,{stage:1})},{...row,stage:1}); });
await test('correction score à chaque étape et score facultatif', () => {
 for(let stage=0;stage<7;stage++) { const row={...m1,stage,clubScore:12,opponentScore:10}; const change=liveChange(row,{clubScore:'9',opponentScore:''}); assert.equal(change.clubScore,9); assert.equal(change.opponentScore,null); assert.equal({...row,...change}.stage,stage); }
});
await test('rejet négatif, décimal, infini, texte, dépassement', () => {
 for(const value of ['-1','1.2','1e2','abc',Infinity,2147483648]) assert.throws(()=>liveChange(m1,{clubScore:value,opponentScore:''}));
 assert.deepEqual(liveChange(m1,{clubScore:'0',opponentScore:''}),{clubScore:0,opponentScore:null});
});
await test('étape et score ne peuvent pas être enregistrés ensemble',()=>assert.throws(()=>liveChange(m1,{stage:1,clubScore:2,opponentScore:0})));
await test('U11 M1 autorisé par règle équipe explicite',()=>assert.equal(canShowScore(m1),true));
await test('U11 M2 et U9 sans scores, étapes possibles',()=>{
 for(const row of [m2,u9]) { assert.equal(canShowScore(row),false); assert.throws(()=>liveChange(row,{clubScore:'1',opponentScore:'2'})); assert.deepEqual(liveChange(row,{stage:1}),{stage:1}); }
 assert.equal(canShowScore({...m2,scorePolicy:'numeric'}),false);
 assert.equal(canShowScore({...m1,scorePolicy:undefined}),false);
});
await test('projection publique sans identités ni scores interdits',()=>{
 for(const row of [m2,u9]) { const output=publicLive({...row,clubScore:99,opponentScore:88,author:'TEST_USER'}); assert.equal('clubScore' in output,false); assert.equal('author' in output,false); assert.equal(normalizeLive({...row,clubScore:99}).clubScore,null); }
 assert.equal(publicLive({...m1,clubScore:0}).clubScore,0);
});
let stored={...m1}, allowed=['T1'], management=false, calls=[], corrupt=false, refuse=false, conflict=false, confirmation=true, rereadWrong=false;
const binding={accessRpc:'TEST_MANAGE',live:{accessRpc:'TEST_TEAMS',readTable:'TEST_LIVE',read:Object.fromEntries(Object.keys(m1).map(k=>[k,k])),saveRpc:'TEST_SAVE',args:{id:'id',revision:'revision',patch:'patch'}}};
const config={url:'https://example.test',key:'TEST',binding,writesApproved:false,liveWritesApproved:false};
const transport=async(url,options)=>{
 calls.push({url,...options}); let data;
 if(refuse) return {ok:false,status:403};
 if(url.endsWith('/verify')) data={access_token:'TEST'};
 else if(url.endsWith('/user')) data={id:'TEST_USER'};
 else if(url.endsWith('/TEST_MANAGE')) data=management;
 else if(url.endsWith('/TEST_TEAMS')) data=allowed;
 else if(url.includes('/TEST_LIVE?')) data=[corrupt?{...stored,teamId:'OTHER'}:rereadWrong?{...stored,stage:0}:stored];
 else if(url.endsWith('/TEST_SAVE')) { const body=JSON.parse(options.body); if(conflict) return {ok:false,status:409}; if(confirmation) stored={...stored,...body.patch,revision:stored.revision+1}; data=confirmation; }
 return {ok:true,status:200,json:async()=>data};
};
const api=createApi(config,transport);
await test('sans session Live refusé sans requête',async()=>{await assert.rejects(api.liveList(),/connexion nécessaire/);assert.equal(calls.length,0);});
await api.verifyCode('live@example.test','123456');
await test('Live seul sans droits de gestion',async()=>{assert.deepEqual(await api.capabilities(),{management:false,live:true});await assert.rejects(api.authorize(),/non autorisé/);});
await test('lecture limitée aux équipes autorisées',async()=>{assert.equal((await api.liveList()).length,1);const url=calls.at(-1).url;assert.equal(new URL(url).searchParams.get('teamId'),'eq.T1');});
await test('réponse contenant une autre équipe refusée',async()=>{corrupt=true;await assert.rejects(api.liveList(),/hors du périmètre/);corrupt=false;});
await test('écritures réelles verrouillées : aucun appel',async()=>{const n=calls.length;await assert.rejects(api.saveLive(stored,{stage:1}),/désactivées/);assert.equal(calls.length,n);});
config.liveWritesApproved=true;
await test('sauvegarde fictive limitée au Live et relecture',async()=>{const row=await api.saveLive(stored,{stage:1});assert.equal(row.stage,1);const call=calls.find(c=>c.url.endsWith('/TEST_SAVE'));assert.deepEqual(JSON.parse(call.body).patch,{stage:1});assert.equal(calls.some(c=>c.method==='PATCH'),false);});
await test('droit équipe révoqué avant écriture',async()=>{allowed=['OTHER'];await assert.rejects(api.saveLive(stored,{stage:2}),/refusé/);allowed=['T1'];});
await test('version obsolète rejetée avant écriture',async()=>{await assert.rejects(api.saveLive({...stored,revision:-1},{stage:2}),/modifiée entre-temps/);});
await test('conflit atomique retourné par la base signalé',async()=>{conflict=true;await assert.rejects(api.saveLive(stored,{stage:2}),/modifiée entre-temps/);conflict=false;});
await test('réponse négative : aucun faux succès',async()=>{confirmation=false;await assert.rejects(api.saveLive(stored,{stage:2}),/non confirmé/);confirmation=true;});
await test('relecture incohérente : aucun faux succès',async()=>{const before={...stored};const wrapped=async(url,options)=>{const result=await transport(url,options);if(url.endsWith('/TEST_SAVE'))rereadWrong=true;return result};const other=createApi(config,wrapped);await other.verifyCode('live@example.test','123456');await assert.rejects(other.saveLive(before,{stage:2}),/relecture Live non confirmée/);rereadWrong=false;});
await test('HTTP403 et panne réseau : erreurs explicites',async()=>{refuse=true;await assert.rejects(api.liveList(),/Accès refusé/);refuse=false;const offline=createApi(config,async()=>{throw new Error('offline')});await assert.rejects(offline.sendCode('x@example.test'),/Erreur de connexion/);});
console.log(`${count} contrôles Live réussis, transport fictif uniquement.`);
