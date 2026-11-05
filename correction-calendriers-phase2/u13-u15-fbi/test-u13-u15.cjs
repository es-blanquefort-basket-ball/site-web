// PostgreSQL local uniquement. Départ : vrai import MiniBasket simulé, 33 + 24 = 57.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {PGlite}=require('../tests/deps.cjs').requireDeps('@electric-sql/pglite');
const root=path.resolve(__dirname,'../..');
const sql=fs.readFileSync(path.join(__dirname,'IMPORT_U13_U15_FBI.sql'),'utf8');
const u18sql=fs.readFileSync(path.join(__dirname,'../u18m-fbi/IMPORT_U18M_FBI.sql'),'utf8');
const mb=fs.readFileSync(path.join(root,'preparation-calendriers/IMPORT_MINIBASKET.sql'),'utf8');
const baseline=JSON.parse(fs.readFileSync(path.join(root,'diagnostic-calendriers-jeunes/public-calendar-lecture-seule.json')));
const mini=new Set(['U9F','U9M1','U9M2','U11 Mixte','U11 M']);
const staged=JSON.parse(sql.match(/\$fbi\$([\s\S]*?)\$fbi\$/)[1]);
assert.equal(staged.length,15);assert.equal(staged.filter(r=>r.local_time==='00:00').length,9);
assert(staged.every(r=>r.venue_name&&r.source_file&&r.source_sha256));
const knownTeams=JSON.parse(fs.readFileSync(path.join(root,'diagnostic-calendriers-jeunes/teams-lecture-reelle.json')));
const configured=(action,approved=true)=>sql.replace("('verify',false)",`('${action}',${approved})`);
(async()=>{const db=new PGlite();try{
 await db.exec(`CREATE TABLE teams(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),code text NOT NULL UNIQUE,name text NOT NULL,competition_label text,ffbb_team_id text UNIQUE,ffbb_team_url text,is_competition_active boolean DEFAULT false,is_public boolean DEFAULT true);
 CREATE TABLE venues(id uuid PRIMARY KEY DEFAULT gen_random_uuid());
 CREATE TABLE matches(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),team_id uuid NOT NULL REFERENCES teams(id) ON DELETE CASCADE,venue_id uuid REFERENCES venues(id) ON DELETE SET NULL,
 ffbb_match_id text UNIQUE,ffbb_match_url text,opponent_name text NOT NULL,home_away text CHECK(home_away IN('home','away','neutral')),
 scheduled_at timestamptz,scheduled_at_ffbb timestamptz,scheduled_local_ffbb timestamp,scheduled_local_override timestamp,
 venue_name_raw text,venue_address_raw text,competition_name text,round_label text,status text DEFAULT 'scheduled' CHECK(status IN('scheduled','played','postponed','cancelled')),
 published boolean DEFAULT false,has_conflict boolean DEFAULT false,source_data jsonb,created_at timestamptz DEFAULT now(),updated_at timestamptz DEFAULT now(),score_test integer);
 CREATE VIEW public_calendar AS SELECT m.id,t.code team_code,t.name team_name,t.competition_label,
 COALESCE(m.scheduled_local_override,m.scheduled_local_ffbb) starts_local,m.status,m.updated_at,m.opponent_name,m.home_away,
 COALESCE(m.scheduled_local_override,m.scheduled_local_ffbb)::date local_date,
 COALESCE(m.scheduled_local_override,m.scheduled_local_ffbb)::time local_time,
 m.venue_name_raw venue_name,m.venue_address_raw venue_address,m.round_label,m.ffbb_match_url,t.ffbb_team_url,m.score_test AS score_public
 FROM matches m JOIN teams t ON t.id=m.team_id WHERE m.published AND NOT m.has_conflict;
 CREATE ROLE u18_test_reader; GRANT SELECT ON public_calendar TO u18_test_reader;
 ALTER VIEW public_calendar SET(security_invoker=true,security_barrier=true);`);
 for(const r of baseline.filter(r=>!mini.has(r.team_code))){
  await db.query(`INSERT INTO teams(id,code,name,competition_label,ffbb_team_url,is_competition_active,ffbb_team_id) VALUES(COALESCE($5::uuid,gen_random_uuid()),$1,$2,$3,$4,$6,$7) ON CONFLICT(code) DO NOTHING`,[r.team_code,r.team_name,r.competition_label,r.ffbb_team_url,knownTeams.find(t=>t.code===r.team_code)?.id||null,knownTeams.find(t=>t.code===r.team_code)?.is_competition_active||false,knownTeams.find(t=>t.code===r.team_code)?.ffbb_team_id||null]);
  await db.query(`INSERT INTO matches(id,team_id,ffbb_match_id,ffbb_match_url,opponent_name,home_away,scheduled_local_ffbb,venue_name_raw,venue_address_raw,round_label,published,status)
  SELECT $1,id,$2,$3,$4,$5,$6,$7,$8,$9,true,$10 FROM teams WHERE code=$11`,[r.id,'FIXTURE-'+r.id,r.ffbb_match_url,r.opponent_name,r.home_away,r.starts_local,r.venue_name,r.venue_address,r.round_label,r.status,r.team_code]);
 }
 await db.exec(mb.replace("('verify', TRUE, FALSE, TRUE)","('import', TRUE, TRUE, TRUE)"));
 // Reconstituer les UUID réels des 24 lignes de référence dans cette base de test seulement.
 for(const r of baseline.filter(r=>mini.has(r.team_code))){
  const ids=(await db.query(`SELECT m.id FROM matches m JOIN teams t ON t.id=m.team_id WHERE t.code=$1
   AND m.opponent_name=$2 AND m.source_data->>'local_date'=$3`,[r.team_code,r.opponent_name,r.local_date])).rows;
  assert.equal(ids.length,1);
  await db.query(`UPDATE matches SET id=$1::uuid,source_data=jsonb_set(source_data,'{rollback_snapshot,id}',to_jsonb(($1::uuid)::text)) WHERE id=$2`,[r.id,ids[0].id]);
 }
 await db.exec(mb); // La vérification MiniBasket validée passe avant le nouveau lot.
 // Simuler une correction club préexistante : elle doit survivre intégralement à l'import U18.
 await db.query(`UPDATE matches SET scheduled_local_override='2026-11-21 18:35',venue_name_raw='SALLE CORRIGÉE TEST'
 WHERE id=$1`,[baseline.find(r=>!mini.has(r.team_code)).id]);
 const matches=async()=> (await db.query('SELECT id,to_jsonb(m) row FROM matches m ORDER BY id')).rows;
 const teams=async()=> (await db.query('SELECT id,to_jsonb(t) row FROM teams t ORDER BY id')).rows;
 const pubs=async()=> (await db.query('SELECT id,to_jsonb(v) row FROM public_calendar v ORDER BY id')).rows;
 const meta=async()=> (await db.query("SELECT oid,relacl::text,reloptions,pg_get_viewdef(oid,true) def FROM pg_class WHERE oid='public_calendar'::regclass")).rows[0];
 const count=async()=> (await db.query('SELECT count(*)::int n FROM public_calendar')).rows[0].n;
 async function reject(input,pattern){try{await db.exec(input);assert.fail('Refus attendu');}catch(e){await db.exec('ROLLBACK');assert.match(e.message,pattern);}}
 // Ajouter les cinq U18M avec le vrai script validé, puis leurs UUID de référence dans la fixture locale.
 await db.exec(u18sql.replace("('verify',false)","('import',true)"));
 const live=JSON.parse(fs.readFileSync(path.join(__dirname,'publications-62-lecture-seule.json')));
 for(const r of live.filter(r=>r.team_code==='U18M')){
  const ids=(await db.query("SELECT m.id FROM matches m JOIN teams t ON t.id=m.team_id WHERE t.code='U18M' AND m.source_data->>'local_date'=$1",[r.local_date])).rows;
  assert.equal(ids.length,1);
  await db.query("UPDATE matches SET id=$1::uuid,source_data=jsonb_set(source_data,'{rollback_snapshot,id}',to_jsonb(($1::uuid)::text)) WHERE id=$2",[r.id,ids[0].id]);
 }
 await db.exec(u18sql);
 const before=await matches(),beforeTeams=await teams(),beforePub=await pubs(),beforeMeta=await meta();
 assert.equal(await count(),62);
 await db.exec(sql);assert.deepEqual(await matches(),before);assert.deepEqual(await teams(),beforeTeams);assert.deepEqual(await meta(),beforeMeta);
 assert.equal((await db.query("SELECT to_regclass('esbb_u13_u15_fbi_source_uidx') idx")).rows[0].idx,null);
 await reject(configured('import',false),/Autorisation/);
 await db.exec(configured('import'));assert.equal(await count(),77);
 const after=await matches(),afterMeta=await meta();
 assert.deepEqual(after.filter(r=>live.some(x=>x.id===r.id)),before);
 assert.deepEqual((await pubs()).filter(r=>live.some(x=>x.id===r.id)),beforePub);
 assert.deepEqual(await teams(),beforeTeams);
 assert.equal(afterMeta.oid,beforeMeta.oid);assert.equal(afterMeta.relacl,beforeMeta.relacl);assert.deepEqual(afterMeta.reloptions,beforeMeta.reloptions);
 const lot=(await db.query("SELECT m.*,t.code FROM matches m JOIN teams t ON t.id=m.team_id WHERE m.source_data->>'import_source'='esbb_u13_u15_fbi' ORDER BY t.code,m.source_data->>'fbi_match_number'")).rows;
 assert.equal(lot.length,15);assert(lot.every(r=>r.ffbb_match_id===null&&r.ffbb_match_url===null&&r.score_test===null));
 assert(lot.every(r=>r.source_data.source_match_key===r.competition_name+'|'+r.code+'|'+r.source_data.fbi_match_number));
 assert.equal((await db.query("SELECT count(*)::int n FROM public_calendar v JOIN matches m ON m.id=v.id WHERE m.source_data->>'import_source'='esbb_u13_u15_fbi' AND v.local_time IS NULL AND v.local_date IS NOT NULL AND v.starts_local IS NULL")).rows[0].n,9);
 assert.equal((await db.query("SELECT count(*)::int n FROM matches WHERE source_data->>'import_source'='esbb_u13_u15_fbi' AND scheduled_local_ffbb IS NULL AND scheduled_at_ffbb IS NULL AND scheduled_at IS NULL")).rows[0].n,9);
 const actual=(await db.query("SELECT v.team_code,v.local_date::text,v.local_time::text,v.opponent_name,v.home_away,v.venue_name,v.competition_label FROM public_calendar v JOIN matches m ON m.id=v.id WHERE m.source_data->>'import_source'='esbb_u13_u15_fbi' ORDER BY v.team_code,v.local_date")).rows;
 for(const r of actual){const expected=staged.find(s=>s.team_code===r.team_code&&s.local_date===r.local_date);assert(expected);assert.equal(r.local_time,expected.local_time==='00:00'?null:expected.local_time+':00');assert.equal(r.venue_name,expected.venue_name);assert.equal(r.opponent_name,expected.opponent_name);assert.equal(r.home_away,expected.home_away);assert.equal(r.competition_label,expected.competition_code);}
 await db.exec(sql);await db.exec(configured('import'));assert.deepEqual(await matches(),after);assert.deepEqual(await meta(),afterMeta);
 await reject(`BEGIN;INSERT INTO matches(team_id,opponent_name,source_data) SELECT team_id,opponent_name,source_data FROM matches WHERE id='${lot[0].id}';COMMIT;`,/unique|duplicate/i);
 await db.query("UPDATE matches SET scheduled_local_override='2026-11-21 18:15',venue_name_raw='CORRECTION CLUB TEST' WHERE id=$1",[lot[0].id]);
 const corrected=await matches();await reject(configured('import'),/modifié/);await reject(configured('rollback'),/modifié/);assert.deepEqual(await matches(),corrected);
 await db.query('UPDATE matches SET scheduled_local_override=NULL,venue_name_raw=$2 WHERE id=$1',[lot[0].id,lot[0].venue_name_raw]);
 await db.query("UPDATE matches SET ffbb_match_id='200000014909687' WHERE id=$1",[lot[0].id]);await reject(configured('rollback'),/modifié/);await db.query('UPDATE matches SET ffbb_match_id=NULL WHERE id=$1',[lot[0].id]);
 await reject(configured('import').replace('Gymnase du Collège','AUTRE SALLE TEST'),/modifié/);
 await db.exec(`CREATE OR REPLACE VIEW public_calendar AS SELECT * FROM (${afterMeta.def.replace(/;\s*$/,'')}) q WHERE true`);
 await reject(configured('rollback'),/Vue changée/);await db.exec(`CREATE OR REPLACE VIEW public_calendar WITH(security_invoker=true,security_barrier=true) AS ${afterMeta.def}`);
 await db.exec(configured('rollback'));assert.equal(await count(),62);
 assert.deepEqual(await matches(),before);assert.deepEqual(await teams(),beforeTeams);assert.deepEqual(await pubs(),beforePub);assert.deepEqual(await meta(),beforeMeta);
 // Vérifier les collisions possibles sans les fusionner : même équipe/date ou phase2 déplacée.
 await db.exec("BEGIN; INSERT INTO matches(team_id,opponent_name,scheduled_local_ffbb,published) SELECT id,'ADVERSAIRE DIFFÉRENT TEST','2026-11-07 09:00',false FROM teams WHERE code='U13F'");
 await reject(configured('import'),/Collision/); // reject annule aussi cette fixture.
 await db.exec("BEGIN; INSERT INTO matches(team_id,opponent_name,scheduled_local_ffbb,competition_name,home_away,published) SELECT id,'AS LE HAILLAN','2026-11-09 09:00','DFU13-3','away',false FROM teams WHERE code='U13F'");
 await reject(configured('import'),/Collision/);
 // 00:00 et chaîne vide sont deux représentations admises d'une heure inconnue, jamais minuit.
 await db.exec(configured('import').replace('"local_time": "00:00"','"local_time": ""'));assert.equal(await count(),77);await db.exec(configured('rollback'));assert.equal(await count(),62);
 console.log('OK PostgreSQL local : 33 + import MiniBasket + import U18M = 62 ; lot U13/U15 62→77→62.');
 console.log('OK : 15 clés FBI, 15 salles, 9 dates conservées avec heures/timestamps NULL ; IDs FFBB et scores NULL.');
 console.log('OK : 62 lignes/publications (dont U18M), corrections club, équipes historiques et définition/OID/droits/options de vue conservés.');
 console.log('OK : verify sans écriture persistante, autorisation requise, relance idempotente, doublons/collisions publiées ou non refusés, corrections/ID canonique/vue modifiée protégés.');
}finally{await db.close()}})().catch(e=>{console.error(e.message,e.where||'',e.position||'');process.exitCode=1});
