// Définition réelle de la vue + UUID et lignes EXCLUSIVEMENT fictives.
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';
import { createApi } from '../../app/gestion-matchs-core.js';
const {PGlite}=await import(process.env.SITE_M01_PGLITE_PATH || '@electric-sql/pglite');
const db=new PGlite();const base=fileURLToPath(new URL('./',import.meta.url));
const reference=JSON.parse(await fs.readFile(base+'reference/schema-received.json','utf8'));
const uid=n=>`00000000-0000-4000-8000-${String(n).padStart(12,'0')}`;
const admin=uid(1),live=uid(2),manager=uid(3),mini=uid(4),denied=uid(5);
const team=uid(101),teamMini=uid(102),teamU9=uid(109),team18=uid(118),team13=uid(113),privateTeam=uid(199);
const match=uid(201),matchMini=uid(202),match9=uid(209),match18=uid(218),match13=uid(213);
let count=0;const test=async(name,fn)=>{await fn();count++;console.log('OK vue réelle / données fictives : '+name)};
const scalar=async(sql,args=[]) =>(await db.query(sql,args)).rows[0]?.value;
const owner=()=>db.exec('reset role');
const as=async(who)=>{await owner();await db.exec('set role authenticated');await db.query("select set_config('request.jwt.claim.sub',$1,false)",[who])};
const call=async(name,args)=>scalar(`select public.${name}(${args.map((_,i)=>'$'+(i+1)).join(',')}) as value`,args);
await db.exec(`create role anon;create role authenticated;create schema auth;
create table auth.users(id uuid primary key,is_anonymous boolean not null default false);
create function auth.uid() returns uuid language sql as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
create function auth.jwt() returns jsonb language sql as $$ select jsonb_build_object('sub',nullif(current_setting('request.jwt.claim.sub',true),'')::uuid,'is_anonymous',coalesce(nullif(current_setting('request.jwt.claim.is_anonymous',true),''),'false')::boolean) $$;
create table teams(id uuid primary key,code text unique,name text,competition_label text,ffbb_team_id text unique,ffbb_team_url text,ffbb_ranking_url text,ffbb_pool_url text,is_competition_active boolean default true,is_public boolean default true,created_at timestamptz,updated_at timestamptz);
create table matches(id uuid primary key,team_id uuid references teams(id),opponent_name text,home_away text,scheduled_local_ffbb timestamp,scheduled_local_override timestamp,venue_name_raw text,venue_name_override text,venue_address_raw text,round_label text,status text,ffbb_match_url text,updated_at timestamptz,published boolean default true,has_conflict boolean default false,source_data jsonb default '{}',competition_name text,official_score integer);
alter table teams enable row level security;alter table matches enable row level security;
create policy "Public can read public teams" on teams for select to anon,authenticated using(is_public=true);
create policy "Public can read published matches" on matches for select to anon,authenticated using(published=true and has_conflict=false);
grant select on teams,matches to anon,authenticated;`);
const correctedDefinition=reference.calendar_definition.replaceAll('m.venue_name_raw AS venue_name','COALESCE(m.venue_name_override, m.venue_name_raw) AS venue_name');
await db.exec('create view public_calendar with(security_invoker=true) as '+correctedDefinition);
await db.exec('grant select on public_calendar to anon,authenticated');
for(const id of [admin,live,manager,mini,denied]) await db.query('insert into auth.users values($1,false)',[id]);
for(const [id,code,name,label,pub] of [[team,'TEST_M1','U11 M1 TEST','Championnat M1 TEST',true],[teamMini,'TEST_M2','U11 M2 TEST','MiniBasket TEST',true],[teamU9,'TEST_U9','U9 TEST','U9 TEST',true],[team18,'TEST_U18','U18 TEST','U18 TEST',true],[team13,'TEST_U13','U13 TEST','U13 TEST',true],[privateTeam,'TEST_PRIVATE','ÉQUIPE PRIVÉE TEST','PRIVÉ TEST',false]])
 await db.query('insert into teams(id,code,name,competition_label,is_public) values($1,$2,$3,$4,$5)',[id,code,name,label,pub]);
for(const [id,tid,label,source,start] of [[match,team,'Championnat M1 TEST',{},'2026-11-07 14:30:45'],[matchMini,teamMini,'MiniBasket TEST',{import_source:'esbb_minibasket',local_date:'2026-11-08',time_known:false},'2026-11-08 00:00:00'],[match9,teamU9,'U9 TEST',{import_source:'esbb_minibasket',local_date:'2026-11-08',time_known:false},null],[match18,team18,'U18 TEST',{import_source:'esbb_u18m_fbi'},'2026-11-08 16:00:00'],[match13,team13,'U13 TEST',{import_source:'esbb_u13_u15_fbi'},'2026-11-08 17:00:00'],[uid(299),privateTeam,'PRIVÉ TEST',{},'2026-11-08 18:00:00']])
 await db.query("insert into matches(id,team_id,opponent_name,home_away,scheduled_local_ffbb,venue_name_raw,competition_name,source_data,official_score) values($1,$2,'ADVERSAIRE TEST','home',$3,'SALLE BRUTE TEST',$4,$5,77)",[id,tid,start,label,source]);
await test('vue imbriquée reconstruite, sécurité et colonnes identiques',async()=>{
 assert.deepEqual(await scalar("select reloptions as value from pg_class where oid='public_calendar'::regclass"),['security_invoker=true']);
 assert.equal((await db.query('select * from public_calendar')).rows[0].id,match);
});
await db.exec(await fs.readFile(base+'sql/01-access-live.sql','utf8'));
 await db.exec(await fs.readFile(base+'sql/01a-rls-executor.sql','utf8'));
await test('configuration des cinq correspondances sans aucun placeholder',async()=>{
 await db.exec(await fs.readFile(base+'sql/02-configure.sql','utf8'));
 const m=(await db.query('select * from site_m01.model')).rows[0];
 assert.deepEqual([m.scheduled_source,m.opponent,m.team_label,m.competition,m.public_match_id],['scheduled_local_ffbb','opponent_name','name','competition_name','id']);
 assert.equal(m.live_enabled,false);assert.equal(m.management_enabled,false);assert.equal(m.access_enabled,false);
});
await db.query('insert into site_m01.administrators values($1)',[admin]);
await db.exec('update site_m01.model set access_enabled=true,management_enabled=true,live_enabled=true');
await as(admin);
for(const [user,tid,manage,canLive] of [[manager,team,true,false],[live,team,false,true],[mini,teamMini,false,true],[mini,teamU9,false,true],[manager,teamMini,true,false],[manager,team18,true,false],[manager,team13,true,false],[manager,teamU9,true,false],[manager,privateTeam,true,false]]) await call('site_m01_set_access',[user,tid,manage,canLive,true]);
await owner();
for(const [id,code,policy,label] of [[team,'DMU11-4-P2','numeric','Championnat M1 TEST'],[teamMini,'DMU11-10-P2','minibasket-no-score','MiniBasket TEST'],[teamU9,'TEST_U9','u9-no-score','U9 TEST']]) await db.query('insert into site_m01.team_rules values($1,$2,$3,$4)',[id,code,policy,label]);
await test('M1 numérique lié à équipe et compétition, pas au libellé code',async()=>{
 await as(live);const rows=(await db.query("select public.site_m01_list('live') as value")).rows.map(x=>x.value);
 assert.equal(rows.length,1);assert.equal(rows[0].teamId,team);assert.equal(rows[0].competitionCode,'DMU11-4-P2');assert.equal(rows[0].scorePolicy,'numeric');
 await call('site_m01_save_live',[match,0,{clubScore:12,opponentScore:10}]);
});
await test('MiniBasket/U9 conservent date et heure inconnue, pas de score',async()=>{
 await as(mini);const rows=(await db.query("select public.site_m01_list('live') as value")).rows.map(x=>x.value);
 assert.equal(rows.length,2);assert(rows.every(x=>x.time===null));assert(rows.every(x=>x.date==='2026-11-08'));
 for(const row of rows){assert.equal('clubScore' in row,false);await assert.rejects(call('site_m01_save_live',[row.id,0,{clubScore:2,opponentScore:1}]),/interdit/);await call('site_m01_save_live',[row.id,0,{stage:1}]);}
 await assert.rejects(db.query("select public.site_m01_list('live',$1)",[team]),/refusé|introuvable/);
});
await test('Gestion date seule MiniBasket refusée si heure inconnue',async()=>{await as(manager);await assert.rejects(call('site_m01_save_management',[matchMini,0,{date:'2026-11-09'}]),/Date et horaire nécessaires/)});
await owner();
// Forcer des overrides différents dans toutes les branches pour comparer la vue exacte.
await db.query('update matches set venue_name_override=$1 where team_id<>$2',['SALLE CORRIGÉE TEST',privateTeam]);
const before=(await db.query('select * from public_calendar order by id')).rows;
const originalAcl=await scalar("select relacl::text as value from pg_class where oid='public_calendar'::regclass");
await test('vue déjà corrigée : quatre branches salle et reste identique',async()=>{
 const canonical=await scalar("select pg_get_viewdef('public_calendar'::regclass,true) as value");
 assert.equal(canonical,correctedDefinition,'Fixture identique à la référence corrigée');
 const after=(await db.query('select * from public_calendar order by id')).rows;
 assert.equal(after.length,before.length);
 for(let i=0;i<after.length;i++) {
  assert.deepEqual({...after[i],venue_name:before[i].venue_name},before[i]);
  assert.equal(after[i].venue_name,after[i].id===uid(299)?'SALLE BRUTE TEST':'SALLE CORRIGÉE TEST');
 }
 assert.deepEqual(await scalar("select reloptions as value from pg_class where oid='public_calendar'::regclass"),['security_invoker=true']);
 assert.equal(await scalar("select relacl::text as value from pg_class where oid='public_calendar'::regclass"),originalAcl);
});
await test('politique de lecture inchangée : équipe privée invisible à anon',async()=>{
 await owner();await db.exec('set role anon');const rows=(await db.query('select id from public_calendar')).rows;
 assert(rows.every(r=>r.id!==uid(299)));assert.equal(rows.length,5);
 await assert.rejects(db.exec("update public.matches set venue_name_override='INTERDIT'"),/permission denied/);
});
await test('relecture privilégiée ne prétend pas publier une équipe privée',async()=>{await as(manager);await assert.rejects(call('site_m01_public_match',[uid(299)]),/non publique|introuvable/)});
await test('salle corrigée propagée pour MiniBasket, U18 et U13/U15',async()=>{
 await as(manager);for(const id of [matchMini,match18,match13]) {
  await call('site_m01_save_management',[id,0,{venue:'SALLE FINALE TEST'}]);
  assert.equal((await call('site_m01_public_match',[id])).venue_name,'SALLE FINALE TEST');
 }
});
await test('date/heure explicites MiniBasket : override composé et public concordant',async()=>{
 await as(manager);await call('site_m01_save_management',[matchMini,1,{date:'2026-11-09',time:'11:15'}]);
 const row=await call('site_m01_public_match',[matchMini]);assert.equal(row.local_date,'2026-11-09');assert.equal(row.local_time,'11:15:00');
});
await test('client V2 confirme les secondes privées malgré la précision publique à la minute',async()=>{
 const transport=async(url,options)=>{
  const pathname=new URL(url).pathname,args=JSON.parse(options.body||'{}');
  if(pathname.endsWith('/verify')) return {ok:true,status:200,json:async()=>({access_token:'TEST'})};
  if(pathname.endsWith('/user')) return {ok:true,status:200,json:async()=>({id:manager})};
  await as(manager);let value;
  if(pathname.endsWith('/site_m01_teams')) value=await call('site_m01_teams',[args.p_scope]);
  else if(pathname.endsWith('/site_m01_list')) value=(await db.query('select public.site_m01_list($1,$2,$3,$4) as value',[args.p_scope,args.p_team,args.p_offset,args.p_limit])).rows.map(x=>x.value);
  else if(pathname.endsWith('/site_m01_save_management')) value=await call('site_m01_save_management',[args.p_id,args.p_revision,args.p_patch]);
  else if(pathname.endsWith('/site_m01_public_match')) value=await call('site_m01_public_match',[args.p_id]);
  else throw new Error('RPC inattendue');
  return {ok:true,status:200,json:async()=>value};
 };
 const api=createApi({url:'https://example.test',key:'TEST',binding:{protocol:'site-m01-rpc'},backendReady:true,writesApproved:true},transport);
 await api.verifyCode('test@example.test','123456');const row=(await api.list()).find(x=>x.id===match);
 const saved=await api.save(row,{date:row.date,time:'14:45:37',venue:row.venue});assert.equal(saved.local_time,'14:45');
 const reread=(await api.list()).find(x=>x.id===match);assert.equal(reread.time,'14:45:37');
});
await test('changement de compétition : score masqué et écriture refusée',async()=>{
 await owner();await db.query('update teams set competition_label=$1 where id=$2',['AUTRE COMPÉTITION TEST',team]);
 await as(live);const row=(await db.query("select public.site_m01_list('live',$1) as value",[team])).rows[0].value;
 assert.equal(row.scorePolicy,null);assert.equal('clubScore' in row,false);await assert.rejects(call('site_m01_save_live',[match,1,{clubScore:1,opponentScore:0}]),/interdit/);
});
await test('non habilité et Live ne peuvent modifier la Gestion',async()=>{
 await as(denied);assert.deepEqual(await call('site_m01_teams',['live']),[]);
 await as(live);await assert.rejects(call('site_m01_save_management',[match,0,{venue:'INTERDIT'}]),/refusé|introuvable/);
});
await test('révocation des habilitations ferme immédiatement le Live',async()=>{
 await as(admin);await call('site_m01_set_access',[live,team,false,false,false]);
 await as(live);assert.deepEqual(await call('site_m01_teams',['live']),[]);await assert.rejects(call('site_m01_save_live',[match,1,{stage:2}]),/refusé|introuvable/);
});
await test('SQL de mise en arrêt conserve l’historique et désactive les écritures',async()=>{
 await owner();const n=await scalar('select count(*)::int as value from site_m01.history');await db.exec(await fs.readFile(base+'sql/03-disable.sql','utf8'));
 assert.equal(await scalar('select count(*)::int as value from site_m01.history'),n);
 const settings=(await db.query('select * from site_m01.model')).rows[0];assert.equal(settings.live_enabled,false);assert.equal(settings.management_enabled,false);assert.equal(settings.access_enabled,false);
});
console.log(`${count} contrôles sur la vue réelle et des données fictives réussis. Aucun accès production.`);
await db.close();
