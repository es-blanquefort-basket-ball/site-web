// Reproduction ciblée des ACL hébergées ; aucune connexion au projet réel.
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
const {PGlite}=await import(process.env.SITE_M01_PGLITE_PATH || '@electric-sql/pglite');
const db=new PGlite();
const scalar=async sql=>(await db.query(sql)).rows[0].value;
let count=0;
const test=async(name,fn)=>{await fn();count++;console.log('OK Auth : '+name)};
await db.exec(`
 create role auth_owner nologin;
 create role installer nologin inherit;
 create role site_m01_executor nologin noinherit;
 create role anon; create role authenticated;
 grant site_m01_executor to installer;
 create schema auth authorization auth_owner;
 create function auth.uid() returns uuid language sql stable as
 $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
 create function auth.jwt() returns jsonb language sql stable as
 $$select coalesce(nullif(current_setting('request.jwt.claims',true),''),'{}')::jsonb$$;
 alter function auth.uid() owner to auth_owner;
 alter function auth.jwt() owner to auth_owner;
 grant usage on schema auth to installer;
 create schema site_m01 authorization installer;
 grant usage,create on schema site_m01 to site_m01_executor;
 set role installer;
`);
await test('installateur non privilégié : USAGE Auth sans délégation',async()=>{
 assert.equal(await scalar("select rolsuper or rolbypassrls as value from pg_roles where rolname=current_user"),false);
 assert.equal(await scalar("select has_schema_privilege(current_user,'auth','USAGE') as value"),true);
 assert.equal(await scalar("select has_schema_privilege(current_user,'auth','USAGE WITH GRANT OPTION') as value"),false);
 assert.equal(await scalar("select has_function_privilege(current_user,'auth.uid()','EXECUTE WITH GRANT OPTION') as value"),false);
});
await test('création des deux relais exacts de 01a sans GRANT Auth',async()=>{
 const source=await fs.readFile(new URL('sql/01a-rls-executor.sql',import.meta.url),'utf8');
 const start=source.indexOf('CREATE FUNCTION site_m01.auth_uid()');
 const end=source.indexOf('-- public est nécessaire',start);
 assert(start>0 && end>start);await db.exec(source.slice(start,end));
 await db.exec('alter function site_m01.auth_uid() owner to site_m01_executor;alter function site_m01.auth_jwt() owner to site_m01_executor');
});
await test('appel réel des deux helpers sans USAGE sur auth',async()=>{
 await db.exec("set role site_m01_executor;set request.jwt.claim.sub='00000000-0000-4000-8000-000000000001';set request.jwt.claims='{\"is_anonymous\":false}'");
 assert.equal(await scalar("select has_schema_privilege(current_user,'auth','USAGE') as value"),false);
 await assert.rejects(db.exec('select auth.uid()'),/permission denied for schema auth/);
 assert.equal(await scalar('select site_m01.auth_uid() as value'),'00000000-0000-4000-8000-000000000001');
 assert.deepEqual(await scalar('select site_m01.auth_jwt() as value'),{is_anonymous:false});
});
await test('relais sans élévation et dépendances Auth enregistrées',async()=>{
 await db.exec('reset role;set role installer');
 const rows=(await db.query("select prosecdef,prosqlbody is not null as bound from pg_proc where pronamespace='site_m01'::regnamespace")).rows;
 assert.equal(rows.length,2);assert(rows.every(r=>!r.prosecdef && r.bound));
 assert.equal(await scalar("select count(*)::int as value from pg_depend where classid='pg_proc'::regclass and objid in ('site_m01.auth_uid()'::regprocedure,'site_m01.auth_jwt()'::regprocedure) and refclassid='pg_proc'::regclass and refobjid in ('auth.uid()'::regprocedure,'auth.jwt()'::regprocedure)"),2);
});
await test('helpers refusés aux deux rôles clients',async()=>{
 for(const role of ['anon','authenticated']) assert.equal(await scalar(`select has_function_privilege('${role}','site_m01.auth_uid()','EXECUTE') or has_function_privilege('${role}','site_m01.auth_jwt()','EXECUTE') as value`),false);
});
await test('révocation EXECUTE Auth respectée malgré la liaison préalable',async()=>{
 await db.exec('reset role;revoke execute on function auth.jwt() from public;set role site_m01_executor');
 await assert.rejects(db.exec('select site_m01.auth_jwt()'),/permission denied for function jwt/);
});
await db.close();console.log(`${count} contrôles Auth réussis ; aucune opération de production.`);
