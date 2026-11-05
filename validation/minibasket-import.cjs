// Base PostgreSQL locale simulée : jamais de connexion Supabase.
// PGLITE_MODULE indique un module @electric-sql/pglite installé hors du dépôt.
const { PGlite } = require(process.env.PGLITE_MODULE || '@electric-sql/pglite');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.join(__dirname, '..');
const sql = fs.readFileSync(path.join(root, 'preparation-calendriers/IMPORT_MINIBASKET.sql'), 'utf8');
const snapshot = JSON.parse(fs.readFileSync(path.join(root, 'preparation-calendriers/etat-public-calendar-avant.json')));
const configured = action => sql.replace("('verify', TRUE, FALSE, TRUE)", `('${action}', TRUE, TRUE, TRUE)`);
const compatibleView = `CREATE OR REPLACE VIEW public.public_calendar AS
 SELECT m.id,t.name AS team_name,t.competition_label,
 COALESCE(m.scheduled_local_override,m.scheduled_local_ffbb) AS starts_local,m.status,m.updated_at,
 t.code AS team_code,m.opponent_name,m.home_away,
 COALESCE(COALESCE(m.scheduled_local_override,m.scheduled_local_ffbb)::date,
          NULLIF(m.source_data->>'local_date','')::date) AS local_date,
 COALESCE(m.scheduled_local_override,m.scheduled_local_ffbb)::time AS local_time,
 m.venue_name_raw AS venue_name,m.venue_address_raw AS venue_address,m.round_label,m.score_test AS score_public,
 NULL::text AS ffbb_match_url,NULL::text AS ffbb_team_url
 FROM public.matches m JOIN public.teams t ON t.id=m.team_id
 WHERE m.published=true AND m.has_conflict=false;`;
(async()=>{
 const db=new PGlite();
 try {
  await db.exec(`CREATE TABLE public.teams(
   id uuid PRIMARY KEY DEFAULT gen_random_uuid(),code text NOT NULL UNIQUE,name text NOT NULL,
   competition_label text,ffbb_team_id text UNIQUE,is_competition_active boolean DEFAULT false,is_public boolean DEFAULT true);
  CREATE TABLE public.venues(id uuid PRIMARY KEY DEFAULT gen_random_uuid());
  CREATE TABLE public.matches(
   id uuid PRIMARY KEY DEFAULT gen_random_uuid(),team_id uuid NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
   venue_id uuid REFERENCES public.venues(id) ON DELETE SET NULL,
   opponent_name text NOT NULL,ffbb_match_id text UNIQUE,scheduled_local_ffbb timestamp,
   scheduled_local_override timestamp,venue_name_raw text,venue_address_raw text,home_away text CHECK(home_away IN ('home','away','neutral')),
   competition_name text,round_label text,status text DEFAULT 'scheduled' CHECK(status IN ('scheduled','played','postponed','cancelled')),published boolean DEFAULT false,
   has_conflict boolean DEFAULT false,source_data jsonb,created_at timestamptz DEFAULT now(),updated_at timestamptz DEFAULT now(),
   score_test integer CHECK(score_test IS NULL OR score_test>=0));`);
  await db.exec(compatibleView);
  for(const team of [...new Set(snapshot.map(r=>r.team_code))]){
   await db.query('INSERT INTO public.teams(code,name) VALUES ($1,$1)',[team]);
  }
  for(const r of snapshot){
   await db.query(`INSERT INTO public.matches(team_id,opponent_name,scheduled_local_ffbb,venue_name_raw,
    venue_address_raw,home_away,round_label,published)
    SELECT id,$2,$3,$4,$5,$6,$7,true FROM public.teams WHERE code=$1`,
    [r.team_code,r.opponent_name,`${r.local_date} ${r.local_time}`,r.venue_name,r.venue_address,r.home_away,r.round_label]);
  }
  async function totals(){return (await db.query('SELECT (SELECT count(*)::int FROM matches) matches,(SELECT count(*)::int FROM teams) teams,(SELECT count(*)::int FROM public_calendar) published')).rows[0]}
  async function reject(input,pattern){
   try{await db.exec(input);assert.fail('Le SQL devait refuser cette opération');}
   catch(e){await db.exec('ROLLBACK');assert.match(e.message,pattern);}
  }
  await db.exec(`CREATE ROLE esbb_test_reader; GRANT SELECT ON public.public_calendar TO esbb_test_reader;
    ALTER VIEW public.public_calendar SET (security_invoker=true,security_barrier=true);`);
  const viewMeta=(await db.query("SELECT oid,relacl::text,reloptions FROM pg_class WHERE oid='public.public_calendar'::regclass")).rows[0];
  const initial=await db.query('SELECT id,to_jsonb(m) row FROM matches m ORDER BY id');
  const initialPublic=await db.query('SELECT id,to_jsonb(v) row FROM public_calendar v ORDER BY id');
  await db.exec(sql);assert.deepEqual(await totals(),{matches:33,teams:5,published:33});
  await reject(sql.replace("('verify', TRUE, FALSE, TRUE)","('import', TRUE, FALSE, TRUE)"),/Import bloqué/);
  await db.exec(configured('import'));
  assert.deepEqual(await totals(),{matches:57,teams:10,published:57});
  assert.deepEqual((await db.query("SELECT oid,relacl::text,reloptions FROM pg_class WHERE oid='public.public_calendar'::regclass")).rows[0],viewMeta);
  assert.equal((await db.query("SELECT count(*)::int n FROM matches WHERE source_data->>'import_source'='esbb_minibasket' AND scheduled_local_ffbb IS NULL AND scheduled_local_override IS NULL")).rows[0].n,11);
  assert.equal((await db.query("SELECT count(*)::int n FROM public_calendar WHERE team_code IN ('U9F','U9M1','U9M2','U11 Mixte','U11 M') AND local_time IS NULL")).rows[0].n,11);
  assert.equal((await db.query("SELECT count(*)::int n FROM public_calendar WHERE team_code IN ('U9F','U9M1','U9M2','U11 Mixte','U11 M') AND score_public IS NOT NULL")).rows[0].n,0);
  if(process.env.SQL_CALENDAR_FIXTURE){
    const actualView=await db.query("SELECT team_code,opponent_name,home_away,local_date::text,local_time::text,venue_name,venue_address,round_label,ffbb_match_url,ffbb_team_url FROM public_calendar WHERE team_code IN ('U9F','U9M1','U9M2','U11 Mixte','U11 M')");
    fs.writeFileSync(process.env.SQL_CALENDAR_FIXTURE,JSON.stringify(actualView.rows));
  }
  assert.equal((await db.query("SELECT count(*)::int n FROM matches WHERE source_data->>'import_source'='esbb_minibasket' AND venue_id IS NOT NULL")).rows[0].n,0);
  // Les six champs doivent refléter les tables, sans identifiant/horaire fabriqué.
  async function assertRealPublicFields(){
    const mismatches=await db.query(`SELECT count(*)::int n FROM matches m JOIN teams t ON t.id=m.team_id
      LEFT JOIN public_calendar v ON v.id=m.id
      WHERE m.source_data->>'import_source'='esbb_minibasket' AND (
        v.id IS DISTINCT FROM m.id OR v.team_name IS DISTINCT FROM t.name
        OR v.competition_label IS DISTINCT FROM t.competition_label
        OR v.starts_local IS DISTINCT FROM COALESCE(m.scheduled_local_override,m.scheduled_local_ffbb)
        OR v.status IS DISTINCT FROM m.status OR v.updated_at IS DISTINCT FROM m.updated_at)`);
    assert.equal(mismatches.rows[0].n,0);
    const preserved=await db.query('SELECT v.id,to_jsonb(v) row FROM public_calendar v JOIN matches m ON m.id=v.id WHERE m.source_data IS NULL ORDER BY v.id');
    assert.deepEqual(preserved,initialPublic);
  }
  await assertRealPublicFields();
  assert.equal((await db.query("SELECT count(*)::int n FROM public_calendar WHERE team_code IN ('U9F','U9M1','U9M2','U11 Mixte','U11 M') AND starts_local IS NULL AND local_date IS NOT NULL AND local_time IS NULL")).rows[0].n,11);
  // Valeurs distinctes des codes et de la compétition du match : vérifier les vraies sources.
  await db.exec(`BEGIN;
    UPDATE teams SET name='NOM ÉQUIPE TEST DISTINCT',competition_label='LIBELLÉ ÉQUIPE TEST DISTINCT' WHERE code='U9F';
    UPDATE matches SET status='postponed',updated_at='2026-11-03 20:37:00+00',
      scheduled_local_override='2026-11-08 17:35'
      WHERE id=(SELECT m.id FROM matches m JOIN teams t ON t.id=m.team_id WHERE t.code='U9F' LIMIT 1);`);
  await assertRealPublicFields();
  await db.exec('ROLLBACK');
  // Deux rencontres de même équipe/adversaire/date mais d'UUID distincts restent visibles.
  await db.exec('BEGIN');
  const lookalike=(await db.query(`INSERT INTO matches(team_id,opponent_name,scheduled_local_ffbb,home_away,published)
    SELECT team_id,opponent_name,scheduled_local_ffbb,home_away,true FROM matches
    WHERE source_data->>'import_source'='esbb_minibasket' AND scheduled_local_ffbb IS NOT NULL LIMIT 1
    RETURNING id,team_id,opponent_name,scheduled_local_ffbb`)).rows[0];
  assert.equal((await db.query('SELECT count(*)::int n FROM public_calendar WHERE id=$1',[lookalike.id])).rows[0].n,1);
  assert.equal((await db.query(`SELECT count(*)::int n FROM public_calendar v JOIN matches m ON m.id=v.id
    WHERE m.team_id=$1 AND m.opponent_name=$2
      AND m.scheduled_local_ffbb=(SELECT scheduled_local_ffbb FROM matches WHERE id=$3)`,
    [lookalike.team_id,lookalike.opponent_name,lookalike.id])).rows[0].n,2);
  await db.exec('ROLLBACK');

  await reject("BEGIN; UPDATE matches SET home_away='invalid' WHERE id=(SELECT id FROM matches LIMIT 1); COMMIT;",/check constraint/);
  await reject("BEGIN; UPDATE matches SET status='invalid' WHERE id=(SELECT id FROM matches LIMIT 1); COMMIT;",/check constraint/);
  // Simulation limitée d'une synchronisation par identifiant FFBB non NULL :
  // ne prouve rien sur le code réel de ffbb-sync, mais teste l'isolation des clés.
  const miniBefore=(await db.query("SELECT id,to_jsonb(m) row FROM matches m WHERE source_data->>'import_source'='esbb_minibasket' ORDER BY id")).rows;
  await db.exec(`BEGIN;
    INSERT INTO matches(team_id,opponent_name,ffbb_match_id,status)
      SELECT id,'ADVERSAIRE DE TEST','FFBB-ID-FIXTURE-UNIQUEMENT','scheduled' FROM teams WHERE code='SG1'
      ON CONFLICT(ffbb_match_id) DO UPDATE SET opponent_name=excluded.opponent_name;
    INSERT INTO matches(team_id,opponent_name,ffbb_match_id,status)
      SELECT id,'ADVERSAIRE DE TEST ACTUALISÉ','FFBB-ID-FIXTURE-UNIQUEMENT','scheduled' FROM teams WHERE code='SG1'
      ON CONFLICT(ffbb_match_id) DO UPDATE SET opponent_name=excluded.opponent_name;`);
  assert.deepEqual((await db.query("SELECT id,to_jsonb(m) row FROM matches m WHERE source_data->>'import_source'='esbb_minibasket' ORDER BY id")).rows,miniBefore);
  await db.exec('ROLLBACK');
  const once=await db.query('SELECT id,to_jsonb(m) row FROM matches m ORDER BY id');
  await db.exec(configured('import'));
  assert.deepEqual(await db.query('SELECT id,to_jsonb(m) row FROM matches m ORDER BY id'),once);
  await db.exec(sql);
  await assertRealPublicFields();
  // L'index bloque réellement une collision même avec ffbb_match_id NULL.
  await reject(`BEGIN; INSERT INTO matches(team_id,opponent_name,source_data) SELECT team_id,opponent_name,source_data FROM matches WHERE source_data->>'import_source'='esbb_minibasket' LIMIT 1; COMMIT;`,/duplicate key/);
  // Modification de n'importe quelle colonne métier : rollback interdit.
  await db.exec("UPDATE matches SET score_test=19 WHERE id=(SELECT id FROM matches WHERE source_data->>'import_source'='esbb_minibasket' LIMIT 1)");
  await reject(configured('rollback'),/modifié/);
  await reject(configured('import'),/modifiée/);
  await db.exec("UPDATE matches SET score_test=NULL WHERE score_test=19");
  await db.exec(configured('rollback'));
  assert.deepEqual(await totals(),{matches:33,teams:5,published:33});
  assert.deepEqual(await db.query('SELECT id,to_jsonb(m) row FROM matches m ORDER BY id'),initial);
  assert.deepEqual(await db.query('SELECT id,to_jsonb(v) row FROM public_calendar v ORDER BY id'),initialPublic);
  // L'import adapte aussi une vue héritée qui ne connaît pas les dates JSONB.
  const legacyView=compatibleView.replace("COALESCE(COALESCE(m.scheduled_local_override,m.scheduled_local_ffbb)::date,\n          NULLIF(m.source_data->>'local_date','')::date)","COALESCE(m.scheduled_local_override,m.scheduled_local_ffbb)::date");
  await db.exec(legacyView);
  const beforeView=(await db.query("SELECT pg_get_viewdef('public.public_calendar'::regclass,true) def")).rows[0].def;
  await db.exec(configured('import'));
  assert.equal((await db.query("SELECT count(*)::int n FROM public_calendar WHERE team_code LIKE 'U9%' OR team_code LIKE 'U11%' ")).rows[0].n,24);
  assert.equal((await db.query("SELECT count(*)::int n FROM public_calendar WHERE local_time IS NULL AND local_date IS NOT NULL")).rows[0].n,11);
  await db.exec(configured('rollback'));
  assert.deepEqual(await totals(),{matches:33,teams:5,published:33});
  assert.equal((await db.query("SELECT pg_get_viewdef('public.public_calendar'::regclass,true) def")).rows[0].def,beforeView);
  await db.exec(compatibleView);
  // Effet indirect d'un déclencheur sur les anciens matchs : tout est annulé.
  await db.exec(`CREATE FUNCTION test_side_effect() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN
   UPDATE matches SET opponent_name='MODIFICATION TEST' WHERE source_data IS NULL; RETURN NEW; END $$;
   CREATE TRIGGER test_side_effect AFTER INSERT ON matches FOR EACH ROW EXECUTE FUNCTION test_side_effect();`);
  await reject(configured('import'),/hors lot/);
  assert.deepEqual(await totals(),{matches:33,teams:5,published:33});
  assert.deepEqual(await db.query('SELECT id,to_jsonb(m) row FROM matches m ORDER BY id'),initial);
  await db.exec('DROP TRIGGER test_side_effect ON matches');
  await db.exec(`CREATE CONSTRAINT TRIGGER test_deferred AFTER INSERT ON matches
    DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION test_side_effect();`);
  await reject(configured('import'),/hors lot/);
  assert.deepEqual(await totals(),{matches:33,teams:5,published:33});
  assert.deepEqual(await db.query('SELECT id,to_jsonb(m) row FROM matches m ORDER BY id'),initial);
  await db.exec('DROP TRIGGER test_deferred ON matches');
  // Une équipe réutilisée par le lot ne doit jamais être supprimée par son rollback.
  await db.exec("INSERT INTO teams(code,name,competition_label,is_competition_active,is_public) VALUES ('U9F','U9F','DFU9-10-P2',true,true)");
  const reused=(await db.query("SELECT id FROM teams WHERE code='U9F'")).rows[0].id;
  await db.exec(configured('import'));
  await db.exec(configured('rollback'));
  assert.deepEqual(await totals(),{matches:33,teams:6,published:33});
  assert.equal((await db.query("SELECT id FROM teams WHERE code='U9F'")).rows[0].id,reused);
  // Scénarios d'actualisation d'un nouvel export FBI (aucune donnée de production).
  await db.exec(configured('import'));
  const refresh=fs.readFileSync(path.join(root,'preparation-calendriers/ACTUALISER_MINIBASKET.sql'),'utf8');
  const sourceRows=JSON.parse(sql.match(/\$minibasket\$([\s\S]*?)\$minibasket\$/)[1]);
  const row=structuredClone(sourceRows.find(r=>!r.local_time));
  const getCurrent=async()=> (await db.query("SELECT to_jsonb(m)-'updated_at' record FROM matches m WHERE source_data->>'source_match_key'=$1",[row.source_match_key])).rows[0].record;
  const input={season_scope:'2026-2027',source_match_key:row.source_match_key,export_row:row,approved_fields:[],confirmed:false};
  function refreshSql(action){return refresh.replace('$refresh_input$[]$refresh_input$',`$refresh_input$${JSON.stringify([input])}$refresh_input$`).replace("('preview',false)",`('${action}',true)`);}
  row.local_time='13:15';row.original_time='13:15';
  await db.exec(refreshSql('preview'));
  assert.equal((await getCurrent()).scheduled_local_ffbb,null);
  input.expected_current=await getCurrent();input.confirmed=true;
  const stableId=input.expected_current.id;
  await db.exec(refreshSql('apply'));
  assert.equal((await getCurrent()).id,stableId);
  assert.equal((await getCurrent()).scheduled_local_ffbb,'2026-11-14T13:15:00');
  assert.equal((await db.query("SELECT count(*)::int n FROM public_calendar WHERE local_time IS NULL AND local_date IS NOT NULL")).rows[0].n,10);
  const afterRefresh=await getCurrent();
  await db.exec(refreshSql('apply'));
  assert.deepEqual(await getCurrent(),afterRefresh); // relance strictement sans effet.
  row.local_time='14:15';row.original_time='14:15';
  await reject(refreshSql('apply'),/Actualisation bloquée/); // capture devenue périmée.
  await db.query("UPDATE matches SET scheduled_local_override='2026-11-15 16:45' WHERE id=$1",[stableId]);
  input.expected_current=await getCurrent();
  await db.exec(refreshSql('apply'));
  assert.equal((await getCurrent()).scheduled_local_override,'2026-11-15T16:45:00');
  const effective=(await db.query("SELECT local_date::text d,local_time::text t FROM public_calendar WHERE team_code=$1 AND opponent_name=$2",[row.team_code_proposed,row.opponent_name])).rows[0];
  assert.deepEqual(effective,{d:'2026-11-15',t:'16:45:00'});
  await db.query("UPDATE matches SET venue_name_raw='SALLE CORRIGÉE TEST',source_data=source_data||jsonb_build_object('club_validated_fields',jsonb_build_array('venue_name_raw')) WHERE id=$1",[stableId]);
  input.expected_current=await getCurrent();row.local_time='15:15';row.original_time='15:15';
  await reject(refreshSql('apply'),/Actualisation bloquée/);
  assert.equal((await getCurrent()).venue_name_raw,'SALLE CORRIGÉE TEST');
  input.approved_fields=['venue_name_raw']; // accord explicite sur ce champ dans ce test.
  await db.exec(refreshSql('apply'));
  assert.equal((await getCurrent()).venue_name_raw,row.venue_name);
  assert.equal((await getCurrent()).scheduled_local_override,'2026-11-15T16:45:00');
  // Heure retirée de l'export : date maintenue, jamais un horaire 00:00.
  await db.query("UPDATE matches SET scheduled_local_override=NULL WHERE id=$1",[stableId]);
  input.expected_current=await getCurrent();row.local_time='00:00';row.original_time='00:00';row.local_date='2026-11-16';
  await db.exec(refreshSql('apply'));
  const pending=(await db.query("SELECT local_date::text d,local_time::text t FROM public_calendar WHERE team_code=$1 AND opponent_name=$2",[row.team_code_proposed,row.opponent_name])).rows[0];
  assert.deepEqual(pending,{d:'2026-11-16',t:null});
  assert.equal((await getCurrent()).id,stableId);
  assert.deepEqual(await totals(),{matches:57,teams:10,published:57});
  assert.deepEqual(await db.query("SELECT id,to_jsonb(m) row FROM matches m WHERE source_data IS NULL ORDER BY id"),initial);
  await reject(configured('rollback'),/modifié/); // ne détruit jamais une actualisation confirmée.
  assert.equal((await getCurrent()).source_data.import_history.length,4);
  await assertRealPublicFields();
  console.log('OK actualisation simulée : heure complétée puis retirée, date maintenue/déplacée, ID stable, relance sans effet, capture périmée refusée, corrections/override protégés, historique, 33 anciennes lignes identiques.');
  console.log('OK PostgreSQL local simulé : 33→57, 5→10, 24/11, relance identique, unicité JSONB, rollback limité, modifications refusées, vue héritée adaptée puis restaurée, effets indirects de triggers annulés. Aucune écriture Supabase.');
 } finally {await db.close()}
})().catch(e=>{console.error({message:e.message,position:e.position,where:e.where});process.exitCode=1});
