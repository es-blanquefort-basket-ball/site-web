// PostgreSQL local uniquement. Départ : vrai import MiniBasket simulé, 33 + 24 = 57.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {PGlite}=require('../tests/deps.cjs').requireDeps('@electric-sql/pglite');
const root=path.resolve(__dirname,'../..');
const sql=fs.readFileSync(path.join(__dirname,'IMPORT_U18M_FBI.sql'),'utf8');
const mb=fs.readFileSync(path.join(root,'preparation-calendriers/IMPORT_MINIBASKET.sql'),'utf8');
const baseline=JSON.parse(fs.readFileSync(path.join(root,'diagnostic-calendriers-jeunes/public-calendar-lecture-seule.json')));
const mini=new Set(['U9F','U9M1','U9M2','U11 Mixte','U11 M']);
const source=JSON.parse(fs.readFileSync(path.join(__dirname,'../import-officiel/u18m-fbi-valide.json')));
const staged=JSON.parse(sql.match(/\$fbi\$([\s\S]*?)\$fbi\$/)[1]);
assert.deepEqual(staged,source.rows.map(r=>Object.fromEntries(['fbi_match_number','local_date','local_time','opponent_name','home_away','venue_name','source_cells'].map(k=>[k,r[k]]))));
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
  await db.query(`INSERT INTO teams(code,name,competition_label,ffbb_team_url) VALUES($1,$2,$3,$4) ON CONFLICT(code) DO NOTHING`,[r.team_code,r.team_name,r.competition_label,r.ffbb_team_url]);
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
 const before=await matches(),beforeTeams=await teams(),beforePub=await pubs(),beforeMeta=await meta();
 assert.equal(await count(),57);await db.exec(sql);assert.deepEqual(await matches(),before);assert.deepEqual(await meta(),beforeMeta);
 assert.equal((await db.query("SELECT to_regclass('esbb_u18m_fbi_source_uidx') idx")).rows[0].idx,null);
 await reject(configured('import',false),/Autorisation/);
 await db.exec(configured('import'));assert.equal(await count(),62);
 const after=await matches(),afterMeta=await meta();
 assert.deepEqual(after.filter(r=>baseline.some(x=>x.id===r.id)),before);
 assert.deepEqual((await pubs()).filter(r=>baseline.some(x=>x.id===r.id)),beforePub);
 assert.deepEqual((await teams()).filter(r=>beforeTeams.some(x=>x.id===r.id)),beforeTeams);
 assert.equal(afterMeta.oid,beforeMeta.oid);assert.deepEqual(afterMeta.reloptions,beforeMeta.reloptions);assert.equal(afterMeta.relacl,beforeMeta.relacl);
 const lot=(await db.query(`SELECT m.*,t.is_competition_active FROM matches m JOIN teams t ON t.id=m.team_id WHERE t.code='U18M' ORDER BY m.source_data->>'fbi_match_number'`)).rows;
 assert.equal(lot.length,5);assert(lot.every(r=>r.ffbb_match_id===null&&r.ffbb_match_url===null&&r.score_test===null&&r.is_competition_active===false));
 assert(lot.every(r=>r.source_data.source_match_key==='DMU18-4-P2|U18M|'+r.source_data.fbi_match_number));
 assert.equal((await db.query("SELECT count(*)::int n FROM public_calendar WHERE team_code='U18M' AND local_time='11:00' AND score_public IS NULL AND ffbb_match_url IS NULL")).rows[0].n,5);
 assert(lot.every(r=>r.scheduled_local_ffbb&&r.scheduled_at_ffbb));
 await db.exec(sql);await db.exec(configured('import'));assert.deepEqual(await matches(),after);assert.deepEqual(await meta(),afterMeta);
 // L'index bloque une seconde insertion portant une des mêmes clés FBI, même avec ID FFBB NULL.
 await reject(`BEGIN; INSERT INTO matches(team_id,opponent_name,source_data) SELECT team_id,opponent_name,source_data FROM matches WHERE id='${lot[0].id}';COMMIT;`,/unique|duplicate/i);
 // Toute correction club sur le lot bloque relance/retour ; aucune donnée n'est écrasée.
 await db.query("UPDATE matches SET scheduled_local_override='2026-11-08 12:30' WHERE id=$1",[lot[0].id]);
 const corrected=await matches();await reject(configured('rollback'),/modifié/);await reject(configured('import'),/modifié/);assert.deepEqual(await matches(),corrected);
 await db.query('UPDATE matches SET scheduled_local_override=NULL WHERE id=$1',[lot[0].id]);
 // Un ID canonique posé ultérieurement ne doit pas autoriser la suppression ou la recréation automatique.
 await db.query("UPDATE matches SET ffbb_match_id='200000014955052' WHERE id=$1",[lot[0].id]);
 await reject(configured('rollback'),/modifié/);await db.query('UPDATE matches SET ffbb_match_id=NULL WHERE id=$1',[lot[0].id]);
 // Nouvel export différent : le même import initial refuse la mise à jour silencieuse.
 await reject(configured('import').replace('Salle Valériane Ayayi','AUTRE SALLE TEST'),/modifié/);
 // Modifier la vue après import fait refuser un retour devenu dangereux.
 await db.exec(`CREATE OR REPLACE VIEW public_calendar AS SELECT * FROM (${afterMeta.def.replace(/;\s*$/,'')}) q WHERE true`);
 await reject(configured('rollback'),/Vue changée/);await db.exec(`CREATE OR REPLACE VIEW public_calendar WITH(security_invoker=true,security_barrier=true) AS ${afterMeta.def}`);
 await db.exec(configured('rollback'));assert.equal(await count(),57);
 assert.deepEqual(await matches(),before);assert.deepEqual(await teams(),beforeTeams);assert.deepEqual(await pubs(),beforePub);assert.deepEqual(await meta(),beforeMeta);
 // Équipe existante compatible : réutilisée sans modification, conservée au retour.
 await db.exec("INSERT INTO teams(code,name,competition_label,is_public,is_competition_active) VALUES('U18M','LIBELLÉ CLUB TEST','LIBELLÉ HISTORIQUE TEST',true,false)");
 const existingTeams=await teams();await db.exec(configured('import'));await db.exec(configured('rollback'));assert.deepEqual(await teams(),existingTeams);
 await db.exec("UPDATE teams SET is_competition_active=true WHERE code='U18M'");await reject(configured('import'),/Équipe U18M/);
 await db.exec("UPDATE teams SET is_competition_active=false WHERE code='U18M'");
 await db.exec("INSERT INTO matches(team_id,opponent_name,published) SELECT id,'HORS LOT TEST',false FROM teams WHERE code='U18M'");
 await reject(configured('import'),/préexistante hors lot/);
 console.log('OK : MiniBasket réel en base locale, 57→62→57 ; verify sans écriture persistante, JWT/réseau non concernés.');
 console.log('OK : 5 clés FBI uniques, IDs FFBB NULL, U18M hors sync, données/salles/UTC/vue, 57 lignes et corrections/droits/options préservés.');
 console.log('OK : relance identique, doublon refusé, correction club/ID canonique/nouvel export/vue modifiée protégés, équipe existante préservée, collision et équipe active refusées.');
}finally{await db.close()}})().catch(e=>{console.error(e.message,e.where||'',e.position||'');process.exitCode=1});
