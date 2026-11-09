// Contrôle de sécurité SQL local : rôles réels Postgres, JWT et lignes fictifs.
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
const {PGlite}=await import(process.env.SITE_M01_PGLITE_PATH || '@electric-sql/pglite');
const db=new PGlite();const base=fileURLToPath(new URL('./',import.meta.url));
const uid=n=>`00000000-0000-4000-8000-${String(n).padStart(12,'0')}`;
const admin=uid(1),manager=uid(2),live=uid(3),denied=uid(4),deleted=uid(5),team=uid(101),other=uid(102),match=uid(201),otherMatch=uid(202);
let count=0;const test=async(name,fn)=>{await fn();count++;console.log('OK sécurité RLS : '+name)};
const owner=()=>db.exec('reset role');
const as=async(user,role='authenticated')=>{await owner();await db.exec('set role '+role);await db.query("select set_config('request.jwt.claim.sub',$1,false)",[user])};
const scalar=async(sql,args=[]) =>(await db.query(sql,args)).rows[0]?.value;
const rpc=async(name,args=[])=>scalar(`select public.${name}(${args.map((_,i)=>'$'+(i+1)).join(',')}) as value`,args);
const sql=async(file)=>db.exec(await fs.readFile(base+'sql/'+file,'utf8'));
await db.exec(`create role anon;create role authenticated;create schema auth;
create table auth.users(id uuid primary key,is_anonymous boolean default false);
create function auth.uid() returns uuid language sql as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
create function auth.jwt() returns jsonb language sql as $$ select jsonb_build_object('sub',nullif(current_setting('request.jwt.claim.sub',true),'')::uuid,'is_anonymous',coalesce(nullif(current_setting('request.jwt.claim.is_anonymous',true),''),'false')::boolean,'user_metadata',jsonb_build_object('admin',true)) $$;
create table teams(id uuid primary key,code text unique,name text,competition_label text,ffbb_team_url text,is_public boolean default true);
create table matches(id uuid primary key,team_id uuid references teams(id),opponent_name text,home_away text,scheduled_local_ffbb timestamp,scheduled_local_override timestamp,venue_name_raw text,venue_name_override text,venue_address_raw text,round_label text,status text,ffbb_match_url text,updated_at timestamptz,published boolean default true,has_conflict boolean default false,source_data jsonb default '{}',competition_name text,official_score integer);
alter table matches enable row level security;alter table teams enable row level security;
create policy public_teams on teams for select to anon,authenticated using(is_public);
create policy public_matches on matches for select to anon,authenticated using(published and not has_conflict);
grant select on teams,matches to anon,authenticated;`);
const ref=JSON.parse(await fs.readFile(base+'reference/schema-received.json','utf8'));
await db.exec('create view public_calendar with(security_invoker=true) as '+ref.calendar_definition);
await db.exec('grant select on public_calendar to anon,authenticated');
for(const id of [admin,manager,live,denied,deleted]) await db.query('insert into auth.users(id) values($1)',[id]);
for(const [id,code] of [[team,'TEST_A'],[other,'TEST_B']]) await db.query("insert into teams(id,code,name,competition_label) values($1,$2,$2,'CHAMPIONNAT TEST')",[id,code]);
for(const [id,t] of [[match,team],[otherMatch,other]]) await db.query("insert into matches(id,team_id,opponent_name,scheduled_local_ffbb,venue_name_raw,competition_name,official_score) values($1,$2,'TEST','2026-11-07 14:30','SALLE TEST','CHAMPIONNAT TEST',77)",[id,t]);
await test('installation atomique annulée si un garde de sécurité échoue',async()=>{
 await db.exec('alter view public_calendar set(security_invoker=false)');await assert.rejects(sql('INSTALLATION.sql'),/security_invoker/);await db.exec('rollback');
 assert.equal(await scalar("select to_regnamespace('site_m01') is null as value"),true);
 assert.equal(await scalar("select count(*)::int as value from pg_roles where rolname='site_m01_executor'"),0);
 await db.exec('alter view public_calendar set(security_invoker=true)');
});
await test('sonde Auth annule tout si une dépendance interne exige USAGE',async()=>{
 const definition=await scalar("select pg_get_functiondef('auth.jwt()'::regprocedure) as value");
 await db.exec('create or replace function auth.jwt() returns jsonb language sql as $$select to_jsonb(auth.uid())$$');
 await assert.rejects(sql('INSTALLATION.sql'),/permission denied for schema auth/);await db.exec('rollback');
 assert.equal(await scalar("select to_regnamespace('site_m01') is null as value"),true);
 assert.equal(await scalar("select count(*)::int as value from pg_roles where rolname='site_m01_executor'"),0);
 await db.exec(definition);
});
await test('préconditions et installation fermée sans créer de compte réel',async()=>{
 await sql('00-install-preconditions.sql');await sql('INSTALLATION.sql');
 assert.equal(await scalar('select count(*)::int as value from site_m01.team_access'),0);
});
await test('Auth sans USAGE auth : appel direct refusé, relais invoker fonctionnel',async()=>{
 await as(manager,'site_m01_executor');
 assert.equal(await scalar("select has_schema_privilege(current_user,'auth','USAGE') as value"),false);
 await assert.rejects(db.exec('select auth.uid()'),/permission denied for schema auth/);
 assert.equal(await scalar('select site_m01.auth_uid() as value'),manager);
 assert.equal((await scalar('select site_m01.auth_jwt() as value')).sub,manager);
 await owner();
 const helpers=(await db.query("select prosecdef,prosqlbody is not null as bound from pg_proc where oid in ('site_m01.auth_uid()'::regprocedure,'site_m01.auth_jwt()'::regprocedure)")).rows;
 assert(helpers.every(h=>!h.prosecdef && h.bound));
 assert.equal(await scalar("select has_function_privilege('authenticated','site_m01.auth_uid()','EXECUTE') as value"),false);
});
await test('relais Auth ne contourne pas EXECUTE de la fonction cible',async()=>{
 await owner();await db.exec('revoke execute on function auth.uid() from public');
 await as(manager,'site_m01_executor');await assert.rejects(db.exec('select site_m01.auth_uid()'),/permission denied for function uid/);
 await owner();await db.exec('grant execute on function auth.uid() to public');
});
await test('rôle NOLOGIN sans BYPASSRLS, non propriétaire des tables',async()=>{
 const r=(await db.query("select * from pg_roles where rolname='site_m01_executor'")).rows[0];assert(!r.rolcanlogin && !r.rolsuper && !r.rolbypassrls && !r.rolcreaterole);
 assert.equal(await scalar("select count(*)::int as value from pg_class where relnamespace='site_m01'::regnamespace and relkind='r' and relowner='site_m01_executor'::regrole"),0);
 assert.equal(await scalar("select pg_has_role('authenticated','site_m01_executor','MEMBER') as value"),false);
});
await test('propriétaires des fonctions et façades sans privilège',async()=>{
 assert.equal(await scalar("select count(*)::int as value from pg_proc p where p.pronamespace='site_m01'::regnamespace and p.proowner<>'site_m01_executor'::regrole"),0);
 assert.equal(await scalar("select count(*)::int as value from pg_proc p where p.pronamespace='public'::regnamespace and p.proname like 'site_m01_%' and p.prosecdef"),0);
 const funcs=(await db.query("select proconfig from pg_proc where pronamespace='site_m01'::regnamespace")).rows;assert(funcs.every(f=>f.proconfig.includes('row_security=on') && f.proconfig.some(s=>['search_path=','search_path=\"\"'].includes(s))));
});
await test('seules les deux colonnes override sont modifiables par le rôle interne',async()=>{
 assert.equal(await scalar("select has_any_column_privilege('authenticated','public.matches','UPDATE') as value"),false);
 assert.equal(await scalar("select has_any_column_privilege('anon','public.matches','UPDATE') as value"),false);
 assert.equal(await scalar("select has_table_privilege('site_m01_executor','public.matches','UPDATE') as value"),false);
 const fields=(await db.query("select attname from pg_attribute where attrelid='public.matches'::regclass and attnum>0 and has_column_privilege('site_m01_executor',attrelid,attnum,'UPDATE') order by attname")).rows.map(r=>r.attname);
 assert.deepEqual(fields,['scheduled_local_override','venue_name_override']);
});
await test('un client ne peut SET ROLE vers l’exécuteur',async()=>{
 await db.exec('set session authorization authenticated');await assert.rejects(db.exec('set role site_m01_executor'),/permission denied/);await db.exec('set session authorization postgres');
});
await test('helpers et tables privées refusés au client',async()=>{
 await as(denied);await assert.rejects(db.exec('select * from site_m01.administrators'),/permission denied/);await assert.rejects(db.exec('select site_m01.identity()'),/permission denied/);
 await assert.rejects(rpc('site_m01_set_access',[denied,team,true,true,true]),/refusée/);assert.deepEqual(await rpc('site_m01_teams',['live']),[]);
});
await owner();await db.query('insert into site_m01.administrators values($1)',[admin]);await db.exec('update site_m01.model set access_enabled=true,management_enabled=true,live_enabled=true');
await db.query("insert into site_m01.team_rules values($1,'DMU11-4-P2','numeric','CHAMPIONNAT TEST')",[team]);
await as(admin);for(const [u,m,l] of [[manager,true,false],[live,false,true],[deleted,false,true]]) await rpc('site_m01_set_access',[u,team,m,l,true]);
await test('user_metadata admin=true ne donne aucun droit',async()=>{await as(denied);await assert.rejects(rpc('site_m01_set_access',[denied,team,true,true,true]),/refusée/)});
await test('identité anonyme refusée même avec un UUID habilité',async()=>{
 await as(live);await db.exec("set request.jwt.claim.is_anonymous='true'");await assert.rejects(rpc('site_m01_teams',['live']),/Connexion requise/);await db.exec("set request.jwt.claim.is_anonymous='false'");
});
await test('Live réussi sans droit organisationnel, autre équipe refusée',async()=>{
 await as(live);await rpc('site_m01_save_live',[match,0,{stage:1}]);await assert.rejects(rpc('site_m01_save_management',[match,0,{venue:'INTERDIT'}]),/introuvable|refusé/);
 await assert.rejects(rpc('site_m01_save_live',[otherMatch,0,{stage:1}]),/introuvable|refusé/);
});
await test('RLS SELECT restrictive réellement appliquée à la RPC privilégiée',async()=>{
 await owner();await db.exec('create policy test_deny_select on public.matches as restrictive for select to site_m01_executor using(false)');
 await as(live);assert.equal((await db.query("select * from public.site_m01_list('live')")).rows.length,0);
 await owner();await db.exec('drop policy test_deny_select on public.matches');
});
await test('RLS UPDATE restrictive bloque une Gestion pourtant habilitée',async()=>{
 await owner();await db.exec('create policy test_deny_update on public.matches as restrictive for update to site_m01_executor using(false) with check(false)');
 await as(manager);await assert.rejects(rpc('site_m01_save_management',[match,0,{venue:'INTERDIT'}]),/introuvable|refusé/);
 await owner();assert.equal(await scalar('select venue_name_override as value from matches where id=$1',[match]),null);await db.exec('drop policy test_deny_update on public.matches');
});
await test('rôle interne borné : ni score FFBB, ni admin, ni règles, ni verrous',async()=>{
 await as(manager,'site_m01_executor');await assert.rejects(db.exec('update public.matches set official_score=0'),/permission denied/);
 await assert.rejects(db.exec('delete from public.matches'),/permission denied/);await assert.rejects(db.exec('update site_m01.model set live_enabled=true'),/permission denied/);
 await assert.rejects(db.query('insert into site_m01.administrators values($1)',[denied]),/permission denied/);
 await assert.rejects(db.exec("update site_m01.team_rules set score_policy='numeric'"),/permission denied/);
});
await test('rôle interne ne peut forger l’auteur ni réécrire l’historique',async()=>{
 await as(live,'site_m01_executor');await assert.rejects(db.query("insert into site_m01.history(actor_id,operation,subject_key) values($1,'live','TEST')",[admin]),/row-level security/);
 await assert.rejects(db.exec("update site_m01.history set subject_key='FORGÉ'"),/permission denied/);await assert.rejects(db.exec('delete from site_m01.history'),/permission denied/);
});
await test('origine club_app interdite à l’administration cliente',async()=>{
 await as(admin,'site_m01_executor');await assert.rejects(db.query("insert into site_m01.team_access(user_id,team_id,origin,can_live) values($1,$2,'club_app',true)",[denied,team]),/row-level security/);
});
await test('Gestion autorisée, audit atomique et résultat FFBB conservé',async()=>{
 await as(manager);await rpc('site_m01_save_management',[match,0,{venue:'SALLE CORRIGÉE TEST'}]);assert.equal((await rpc('site_m01_public_match',[match])).venue_name,'SALLE CORRIGÉE TEST');
 await owner();assert.equal(await scalar('select official_score as value from matches where id=$1',[match]),77);
});
await test('suppression Auth retire les droits malgré un ancien JWT',async()=>{
 await owner();await db.query('delete from auth.users where id=$1',[deleted]);await as(deleted);assert.deepEqual(await rpc('site_m01_teams',['live']),[]);
 await assert.rejects(rpc('site_m01_save_live',[match,1,{stage:2}]),/introuvable|refusé/);
});
await test('arrêt ferme RPC et RLS même pour une identité Gestion habilitée',async()=>{
 await owner();await sql('03-disable.sql');await as(manager);await assert.rejects(rpc('site_m01_save_management',[match,1,{venue:'INTERDIT'}]),/permission denied/);
 await as(manager,'site_m01_executor');const result=await db.query('update public.matches set venue_name_override=$1 where id=$2',['INTERDIT',match]);assert.equal(result.affectedRows,0);
 await owner();assert.equal(await scalar('select venue_name_override as value from matches where id=$1',[match]),'SALLE CORRIGÉE TEST');
});
console.log(`${count} contrôles de sécurité/RLS locaux réussis, aucune opération de production.`);await db.close();
