// Postgres local PGlite 0.3.14 uniquement. Aucun secret, réseau ou Supabase réel.
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createApi } from '../../app/gestion-matchs-core.js';
const { PGlite } = await import(process.env.SITE_M01_PGLITE_PATH || '@electric-sql/pglite');
const db = new PGlite();
const base = fileURLToPath(new URL('./',import.meta.url));
const ids={admin:'00000000-0000-4000-8000-000000000001',manage:'00000000-0000-4000-8000-000000000002',live:'00000000-0000-4000-8000-000000000003',both:'00000000-0000-4000-8000-000000000004',denied:'00000000-0000-4000-8000-000000000005',mini:'00000000-0000-4000-8000-000000000006'};
let count=0;
const test=async(name,fn)=>{await fn();count++;console.log('OK Postgres local : '+name)};
const owner=()=>db.exec('reset role');
const as=async(name)=>{await owner();await db.exec(`set role authenticated;set request.jwt.claim.sub='${ids[name]||''}'`)};
const scalar=async(sql,args=[])=> (await db.query(sql,args)).rows[0]?.value;
const rpc=async(name,args)=>scalar(`select public.${name}(${args.map((_,i)=>'$'+(i+1)).join(',')}) as value`,args);
await db.exec(`create role anon;create role authenticated;create schema auth;
create table auth.users(id uuid primary key,is_anonymous boolean not null default false);
create function auth.uid() returns uuid language sql as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
create table teams(team_key bigint primary key,label text);
create table matches(match_key bigint primary key,club_team bigint references teams(team_key),start_local timestamp,scheduled_local_override timestamp,venue_name_raw text,venue_name_override text,opponent text,competition text,home_away text,ffbb_match_url text,official_score integer);
alter table matches enable row level security;alter table teams enable row level security;
create view public_calendar as select match_key as match_id,coalesce(scheduled_local_override,start_local)::date as local_date,coalesce(scheduled_local_override,start_local)::time as local_time,venue_name_raw as venue_name from matches;
grant select on public_calendar to anon; alter view public_calendar set(security_barrier=true);
insert into teams values(11,'U11 M1 TEST'),(12,'U11 M2 TEST'),(9,'U9 TEST');
insert into matches(match_key,club_team,start_local,venue_name_raw,opponent,competition,official_score) values
(101,11,'2026-11-07 14:30:45','SALLE TEST','ADVERSAIRE TEST','DMU11-4-P2',77),
(102,12,'2026-11-08 10:00','SALLE TEST','ADVERSAIRE TEST','DMU11-10-P2',null),
(109,9,'2026-11-14 10:00','SALLE TEST','ADVERSAIRE TEST','TEST_U9',null);`);
for(const id of Object.values(ids)) await db.query('insert into auth.users(id) values($1)',[id]);
await test('proposition installable, PK/FK réelles découvertes sans noms supposés',async()=>{
 await db.exec(await fs.readFile(base+'sql/01-access-live.sql','utf8'));
 const cfg=(await db.query('select * from site_m01.model')).rows[0];
 assert.equal(cfg.match_pk,'match_key');assert.equal(cfg.match_team_fk,'club_team');assert.equal(cfg.team_pk,'team_key');
 assert.equal(await scalar('select count(*)::int as value from site_m01.team_access'),0);
});
await db.exec(`update site_m01.model set scheduled_source='start_local',opponent='opponent',team_label='label',competition='competition',public_match_id='match_id';
insert into site_m01.team_rules values(11,'DMU11-4-P2','numeric'),(12,'DMU11-10-P2','minibasket-no-score'),(9,'TEST_U9','u9-no-score');`);
await db.query('insert into site_m01.administrators values($1)',[ids.admin]);
await test('aucun privilège direct UPDATE ou lecture des tables privées',async()=>{
 await as('live');await assert.rejects(db.exec('update public.matches set venue_name_override=\'X\''),/permission denied/);
 await assert.rejects(db.exec('select * from site_m01.history'),/permission denied/);
 await assert.rejects(db.exec('select * from site_m01.team_access'),/permission denied/);
});
await test('configuration des habilitations verrouillée côté serveur',async()=>{await as('admin');await assert.rejects(rpc('site_m01_set_access',[ids.live,'11',false,true,true]),/désactivée/)});
await owner();await db.exec('update site_m01.model set access_enabled=true');
await test('seul administrateur peut attribuer les droits',async()=>{
 await as('denied');await assert.rejects(rpc('site_m01_set_access',[ids.denied,'11',true,true,true]),/refusée/);
 await as('admin');assert.equal(await rpc('site_m01_set_access',[ids.live,'11',false,true,true]),true);
 await rpc('site_m01_set_access',[ids.manage,'11',true,false,true]);await rpc('site_m01_set_access',[ids.both,'11',true,true,true]);
 await rpc('site_m01_set_access',[ids.mini,'12',false,true,true]);await rpc('site_m01_set_access',[ids.mini,'9',false,true,true]);
});
await test('utilisateur et équipe doivent déjà exister',async()=>{await as('admin');await assert.rejects(rpc('site_m01_set_access',['00000000-0000-4000-8000-999999999999','11',true,true,true]),/introuvable/);await assert.rejects(rpc('site_m01_set_access',[ids.live,'999',true,true,true]),/introuvable/)});
await test('droits Gestion/Live et équipes séparés',async()=>{
 await as('live');assert.deepEqual(await rpc('site_m01_teams',['management']),[]);assert.deepEqual(await rpc('site_m01_teams',['live']),['11']);
 assert.equal((await db.query("select * from public.site_m01_list('management')")).rows.length,0);
 await assert.rejects(db.query("select * from public.site_m01_list('live','12')"),/refusé/);
 await as('manage');assert.deepEqual(await rpc('site_m01_teams',['live']),[]);
});
await test('serveur bloque toutes les écritures malgré un client modifié',async()=>{
 await as('both');await assert.rejects(rpc('site_m01_save_management',['101',0,{venue:'AUTRE SALLE TEST'}]),/désactivées/);await assert.rejects(rpc('site_m01_save_live',['101',0,{stage:1}]),/désactivées/);
});
await owner();await db.exec('update site_m01.model set management_enabled=true,live_enabled=true');
await test('Live ne peut écrire Gestion et inversement',async()=>{await as('live');await assert.rejects(rpc('site_m01_save_management',['101',0,{venue:'X'}]),/refusé/);await as('manage');await assert.rejects(rpc('site_m01_save_live',['101',0,{stage:1}]),/refusé/)});
await test('correction heure seule conserve date et sources FFBB',async()=>{
 await as('manage');assert.equal(await rpc('site_m01_save_management',['101',0,{time:'16:00:45'}]),true);
 await owner();const m=(await db.query("select *,to_char(start_local,'YYYY-MM-DD HH24:MI:SS') as source_text,to_char(scheduled_local_override,'YYYY-MM-DD HH24:MI:SS') as override_text from matches where match_key=101")).rows[0];
 assert.equal(m.source_text,'2026-11-07 14:30:45');assert.equal(m.override_text,'2026-11-07 16:00:45');assert.equal(m.official_score,77);
});
await test('correction date seule conserve heure et secondes',async()=>{
 await as('manage');await rpc('site_m01_save_management',['101',1,{date:'2026-11-09'}]);await owner();
 assert.equal((await db.query("select to_char(scheduled_local_override,'YYYY-MM-DD HH24:MI:SS') as value from matches where match_key=101")).rows[0].value,'2026-11-09 16:00:45');
});
await test('salle seule conserve la correction de planification',async()=>{
 await as('manage');await rpc('site_m01_save_management',['101',2,{venue:'AUTRE SALLE TEST'}]);await owner();
 assert.equal((await db.query("select to_char(scheduled_local_override,'YYYY-MM-DD HH24:MI:SS') as value from matches where match_key=101")).rows[0].value,'2026-11-09 16:00:45');
});
await test('version obsolète et champs étrangers refusés',async()=>{
 await as('manage');await assert.rejects(rpc('site_m01_save_management',['101',0,{venue:'X'}]),/obsolète/);
 await assert.rejects(rpc('site_m01_save_management',['101',3,{official_score:99}]),/invalides/);
 await assert.rejects(rpc('site_m01_save_management',['101',3,{date:'2026-02-30'}]));
 await assert.rejects(rpc('site_m01_save_management',['101',3,{time:'24:00'}]));
 await assert.rejects(rpc('site_m01_save_management',['101',3,{venue:''}]));
});
await test('suivi des étapes sans score et score sans changer d’étape',async()=>{
 await as('live');await rpc('site_m01_save_live',['101',0,{stage:1}]);await rpc('site_m01_save_live',['101',1,{clubScore:12,opponentScore:10}]);
 await rpc('site_m01_save_live',['101',2,{stage:2}]);await rpc('site_m01_save_live',['101',3,{stage:1}]);
 await owner();const s=(await db.query('select * from site_m01.match_state where match_id=101')).rows[0];assert.equal(s.stage,1);assert.equal(s.club_score,12);assert.equal(s.opponent_score,10);
});
await test('score interdit U11 M2/U9 : refus côté SQL et absent des réponses',async()=>{
 await as('mini');for(const [id,team] of [['102','12'],['109','9']]) {
  await assert.rejects(rpc('site_m01_save_live',[id,0,{clubScore:1,opponentScore:0}]),/interdit/);
  await rpc('site_m01_save_live',[id,0,{stage:1}]);
  const row=(await db.query("select public.site_m01_list('live',$1) as value",[team])).rows[0].value;
  assert.equal('clubScore' in row,false);assert.equal('opponentScore' in row,false);
 }
});
await test('payload mixte étape/score et score invalide refusés',async()=>{
 await as('live');await assert.rejects(rpc('site_m01_save_live',['101',4,{stage:3,clubScore:1,opponentScore:0}]),/séparément/);
 await assert.rejects(rpc('site_m01_save_live',['101',4,{clubScore:-1,opponentScore:0}]),/invalide/);
 await assert.rejects(rpc('site_m01_save_live',['101',4,{stage:7}]),/invalide/);
});
await test('score SQL facultatif effaçable sans changer d’étape',async()=>{
 await as('live');await rpc('site_m01_save_live',['101',4,{clubScore:null,opponentScore:null}]);
 await owner();const row=(await db.query('select stage,club_score,opponent_score from site_m01.match_state where match_id=101')).rows[0];
 assert.equal(row.stage,1);assert.equal(row.club_score,null);assert.equal(row.opponent_score,null);
});
await test('historique privé atomique et lecture réservée administrateur',async()=>{
 await as('live');await assert.rejects(db.query('select * from public.site_m01_audit()'),/privé/);
 await as('admin');const hist=(await db.query('select * from public.site_m01_audit()')).rows;
 assert(hist.some(r=>r.operation==='management' && r.actor_id===ids.manage && r.before_value.venue==='SALLE TEST' && r.after_value.venue==='AUTRE SALLE TEST'));
 assert(hist.some(r=>r.operation==='live' && r.actor_id===ids.live));
 assert(hist.some(r=>r.operation==='access' && r.actor_id===ids.admin));
});
await test('révocation immédiate, priorité manuelle sur future origine app',async()=>{
 await owner();await db.query("insert into site_m01.team_access(user_id,team_id,origin,can_live) values($1,11,'club_app',true)",[ids.live]);
 await as('admin');await rpc('site_m01_set_access',[ids.live,'11',false,false,false]);
 await as('live');assert.deepEqual(await rpc('site_m01_teams',['live']),[]);await assert.rejects(rpc('site_m01_save_live',['101',4,{stage:3}]),/refusé/);
});
await test('anonyme et compte non habilité ne peuvent s’auto-attribuer de droits',async()=>{
 await owner();await db.exec('set role anon');await assert.rejects(rpc('site_m01_teams',['live']),/permission denied/);
 await as('denied');assert.deepEqual(await rpc('site_m01_teams',['live']),[]);await assert.rejects(rpc('site_m01_set_access',[ids.denied,'11',true,true,true]),/refusée/);
});
await test('échec de journalisation annule intégralement une correction',async()=>{
 await owner();await db.exec("alter table site_m01.history add constraint test_failure check(operation<>'management') not valid");
 const before=await scalar("select venue_name_override as value from matches where match_key=101");
 await as('manage');await assert.rejects(rpc('site_m01_save_management',['101',3,{venue:'NE PAS CONSERVER'}]),/test_failure/);
 await owner();assert.equal(await scalar("select venue_name_override as value from matches where match_key=101"),before);
 await db.exec('alter table site_m01.history drop constraint test_failure');
});
await test('liste des habilitations privée et réservée aux administrateurs',async()=>{
 await as('denied');await assert.rejects(db.query('select * from public.site_m01_access_list()'),/refusée/);
 await as('admin');const rows=(await db.query('select * from public.site_m01_access_list()')).rows;assert(rows.length>=5);assert.equal('email' in rows[0],false);
});
// Contrat client réel -> façades SQL, avec HTTP/Auth simulés mais autorisations SQL réelles.
const config={url:'https://example.test',key:'TEST',binding:{protocol:'site-m01-rpc'},backendReady:true,writesApproved:true,liveWritesApproved:true,accessWritesApproved:true};
const transport=async(url,options)=>{
 const path=new URL(url).pathname, args=JSON.parse(options.body||'{}');
 if(path.endsWith('/verify'))return{ok:true,status:200,json:async()=>({access_token:'TEST'})};
 if(path.endsWith('/user'))return{ok:true,status:200,json:async()=>({id:ids.both})};
 try {
  await as('both');let result;
  if(path.endsWith('/site_m01_teams'))result=await rpc('site_m01_teams',[args.p_scope]);
  else if(path.endsWith('/site_m01_list'))result=(await db.query('select public.site_m01_list($1,$2,$3,$4) as value',[args.p_scope,args.p_team,args.p_offset,args.p_limit])).rows.map(r=>r.value);
  else if(path.endsWith('/site_m01_save_management'))result=await rpc('site_m01_save_management',[args.p_id,args.p_revision,args.p_patch]);
  else if(path.endsWith('/site_m01_save_live'))result=await rpc('site_m01_save_live',[args.p_id,args.p_revision,args.p_patch]);
  else if(path.endsWith('/site_m01_public_match'))result=await rpc('site_m01_public_match',[args.p_id]);
  else throw new Error('RPC inattendue');
  return{ok:true,status:200,json:async()=>result};
 }catch(e){return{ok:false,status:e.code==='42501'?403:409,json:async()=>({message:e.message})}}
};
const api=createApi(config,transport);await api.verifyCode('test@example.test','123456');
await test('client RPC : lecture et Live raccordés aux vraies fonctions locales',async()=>{assert.deepEqual(await api.capabilities(),{management:true,live:true});const live=(await api.liveList())[0];const saved=await api.saveLive(live,{stage:3});assert.equal(saved.stage,3)});
await test('client Gestion détecte la vue publique non corrigée',async()=>{const match=(await api.list())[0];await assert.rejects(api.save(match,{date:match.date,time:match.time,venue:'NOUVELLE SALLE TEST'}),/propagation publique non confirmée/)});
await owner();
await test('patch AST généré et exécuté sur la vue locale avec sauvegarde',async()=>{
 const definition=await scalar("select pg_get_viewdef('public.public_calendar'::regclass,true) as value");
 const dir=await fs.mkdtemp(path.join(tmpdir(),'site-m01-view-'));const input=path.join(dir,'definition.sql');await fs.writeFile(input,definition);
 const patch=execFileSync(process.env.SITE_M01_PYTHON || 'python3',[base+'calendar-view-patch.py',input],{encoding:'utf8',env:{...process.env,PYTHONDONTWRITEBYTECODE:'1'}});
 await db.exec(patch);
 assert.equal(await scalar('select count(*)::int as value from site_m01.view_backup'),1);
 assert.equal(await scalar("select has_table_privilege('anon','public.public_calendar','SELECT') as value"),true);
 assert((await scalar("select reloptions as value from pg_class where oid='public.public_calendar'::regclass")).includes('security_barrier=true'));
 assert.equal(await scalar("select venue_name as value from public.public_calendar where match_id=101"),'NOUVELLE SALLE TEST');
 await assert.rejects(db.exec(patch),/vue a changé/);await db.exec('rollback');
});
await test('client Gestion confirme la propagation après correction salle',async()=>{const match=(await api.list())[0];const row=await api.save(match,{date:match.date,time:match.time,venue:'SALLE VALIDÉE TEST'});assert.equal(row.venue_name,'SALLE VALIDÉE TEST')});
await owner();assert.equal(await scalar("select official_score as value from matches where match_key=101"),77);
console.log(`${count} contrôles Postgres locaux réussis ; aucune opération Supabase de production.`);
await db.close();
