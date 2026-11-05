// PostgreSQL simulé local : aucune connexion Supabase. Toutes les écritures restent dans PGlite.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {PGlite}=process.env.PGLITE_MODULE?require(process.env.PGLITE_MODULE):require('./deps.cjs').requireDeps('@electric-sql/pglite');
const dir=path.join(__dirname,'..');const raw=fs.readFileSync(process.env.ESBB_IMPORT_SQL || path.join(dir,'APPLIQUER_PHASE2.sql'),'utf8');
const undo=fs.readFileSync(path.join(dir,'RETOUR_PHASE2.sql'),'utf8');
const baseline=JSON.parse(fs.readFileSync(path.join(dir,'../diagnostic-calendriers-jeunes/public-calendar-lecture-seule.json')));
(async()=>{const db=new PGlite();try{
 await db.exec(`CREATE TABLE teams(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),code text NOT NULL UNIQUE,name text NOT NULL,competition_label text,ffbb_team_id text UNIQUE,ffbb_team_url text,is_competition_active boolean DEFAULT false,is_public boolean DEFAULT true);
 CREATE TABLE venues(id uuid PRIMARY KEY DEFAULT gen_random_uuid());
 CREATE TABLE matches(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),team_id uuid NOT NULL REFERENCES teams(id) ON DELETE CASCADE,ffbb_match_id text UNIQUE,ffbb_match_url text,
 opponent_name text NOT NULL,scheduled_at timestamptz,scheduled_at_ffbb timestamptz,home_away text CHECK(home_away IN ('home','away','neutral')),scheduled_local_ffbb timestamp,scheduled_local_override timestamp,venue_id uuid REFERENCES venues(id) ON DELETE SET NULL,
 venue_name_raw text,venue_address_raw text,competition_name text,round_label text,status text DEFAULT 'scheduled' CHECK(status IN ('scheduled','played','postponed','cancelled')),
 published boolean DEFAULT false,has_conflict boolean DEFAULT false,source_data jsonb,created_at timestamptz DEFAULT now(),updated_at timestamptz DEFAULT now());
 CREATE VIEW public_calendar AS SELECT m.id,t.code team_code,t.name team_name,t.competition_label,
 COALESCE(m.scheduled_local_override,m.scheduled_local_ffbb) starts_local,m.status,m.updated_at,m.opponent_name,m.home_away,
 COALESCE(m.scheduled_local_override::date,m.scheduled_local_ffbb::date,(m.source_data->>'local_date')::date) local_date,
 NULLIF(COALESCE(m.scheduled_local_override,m.scheduled_local_ffbb)::time,'00:00'::time) local_time,
 m.venue_name_raw venue_name,m.venue_address_raw venue_address,m.round_label,m.ffbb_match_url,t.ffbb_team_url
 FROM matches m JOIN teams t ON t.id=m.team_id WHERE m.published AND NOT m.has_conflict;
 CREATE ROLE p2_reader;GRANT SELECT ON public_calendar TO p2_reader;ALTER VIEW public_calendar SET(security_invoker=true,security_barrier=true);`);
 for(const r of baseline){
  await db.query(`INSERT INTO teams(code,name,competition_label,ffbb_team_url) VALUES($1,$2,$3,$4) ON CONFLICT(code) DO NOTHING`,[r.team_code,r.team_name,r.competition_label,r.ffbb_team_url]);
  await db.query(`INSERT INTO matches(id,team_id,ffbb_match_id,ffbb_match_url,opponent_name,home_away,scheduled_local_ffbb,venue_name_raw,venue_address_raw,round_label,published,status,source_data)
  SELECT $1,id,$2,$3,$4,$5,$6,$7,$8,$9,true,$10,$11::jsonb FROM teams WHERE code=$12`,[r.id,'FIXTURE-'+r.id,r.ffbb_match_url,r.opponent_name,r.home_away,r.starts_local,r.venue_name,r.venue_address,r.round_label,r.status,JSON.stringify({local_date:r.local_date,fixture:true}),r.team_code]);
 }
 const before=(await db.query('SELECT id,to_jsonb(m) row FROM matches m ORDER BY id')).rows;
 const publicBefore=(await db.query('SELECT id,to_jsonb(v) row FROM public_calendar v ORDER BY id')).rows;
 const teamsBefore=(await db.query('SELECT id,to_jsonb(t) row FROM teams t ORDER BY id')).rows;
 const viewBefore=(await db.query("SELECT pg_get_viewdef('public_calendar'::regclass,true) def")).rows[0].def;
 const metaBefore=(await db.query("SELECT oid,reloptions,relacl::text FROM pg_class WHERE oid='public_calendar'::regclass")).rows[0];
 const main=JSON.parse(fs.readFileSync('/private/tmp/esbb-phase2-candidate-fixture.json'))[0];
 // Données SIMULÉES, non approuvées pour la production.
 const u18={...main,team_code:'U18M',ffbb_team_id:'200000005419968',competition_label:'DMU18-4',phase:'200000002902228',pool:'200000003064624',
 ffbb_team_url:'https://competitions.ffbb.com/ligues/naq/comites/0033/clubs/naq0033034/equipes/200000005419968',
 ffbb_match_id:'200000014955052',ffbb_match_url:'https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu18-4/match/200000014955052',
 local_date:'2026-11-08',local_time:null,starts_local:null,scheduled_at_ffbb:null,opponent_name:'ADVERSAIRE TEST SIMULÉ'};
 let candidates=[main,u18];
 async function configured(action='apply',approved=true){const approvals=[];for(const r of candidates){const hash=(await db.query('SELECT md5($1::jsonb::text) hash',[JSON.stringify(r)])).rows[0].hash;approvals.push({ffbb_match_id:r.ffbb_match_id,expected_md5:hash});}
 return raw.replace(/\$candidates\$[\s\S]*?\$candidates\$/,`$candidates$${JSON.stringify(candidates)}$candidates$`)
 .replace('$approval$[]$approval$',`$approval$${JSON.stringify(approved?approvals:[])}$approval$`)
 .replace("('preview',false)",`('${action}',true)`);}
 async function reject(sql,pattern){try{await db.exec(sql);assert.fail('Refus attendu');}catch(e){await db.exec('ROLLBACK');assert.match(e.message,pattern);}}
 await db.exec(raw);assert.equal((await db.query('SELECT count(*)::int n FROM matches')).rows[0].n,57);
 await reject(await configured('apply',false),/non approuvé/);
 await reject((await configured()).replace("('apply',true)","('apply',false)"),/Supabase NON PRODUCTIF|source officielle/);
 await db.exec(await configured());
 assert.equal((await db.query('SELECT count(*)::int n FROM public_calendar')).rows[0].n,59);
 assert.deepEqual((await db.query('SELECT id,to_jsonb(m) row FROM matches m WHERE id=ANY($1::uuid[]) ORDER BY id',[baseline.map(r=>r.id)])).rows,before);
 assert.deepEqual((await db.query('SELECT id,to_jsonb(v) row FROM public_calendar v WHERE id=ANY($1::uuid[]) ORDER BY id',[baseline.map(r=>r.id)])).rows,publicBefore);
 assert.deepEqual((await db.query('SELECT id,to_jsonb(t) row FROM teams t WHERE id=ANY($1::uuid[]) ORDER BY id',[teamsBefore.map(r=>r.id)])).rows,teamsBefore);
 assert.equal((await db.query("SELECT local_time FROM public_calendar WHERE team_code='U18M'")).rows[0].local_time,null);
 assert.equal((await db.query("SELECT local_date::text d FROM public_calendar WHERE team_code='U18M'")).rows[0].d,'2026-11-08');
 assert.deepEqual((await db.query("SELECT oid,reloptions,relacl::text FROM pg_class WHERE oid='public_calendar'::regclass")).rows[0],metaBefore);
 const after=(await db.query('SELECT id,to_jsonb(m) row FROM matches m ORDER BY id')).rows;
 await db.exec(await configured());assert.deepEqual((await db.query('SELECT id,to_jsonb(m) row FROM matches m ORDER BY id')).rows,after);
 const undoRows=(await db.query("SELECT id,md5((to_jsonb(m)-'updated_at')::text) current_md5 FROM matches m WHERE source_data->>'import_source'='esbb_ffbb_phase2'")).rows;
 const undoConfigured=undo.replace('$undo$[]$undo$',`$undo$${JSON.stringify(undoRows)}$undo$`).replace("('verify')","('rollback')");
 await db.exec("UPDATE matches SET scheduled_local_override='2026-11-08 12:30' WHERE source_data->>'import_source'='esbb_ffbb_phase2'");
 await reject(undoConfigured,/modifié/);
 await db.exec("UPDATE matches SET scheduled_local_override=NULL WHERE source_data->>'import_source'='esbb_ffbb_phase2'");
 await db.exec(undoConfigured);
 assert.deepEqual((await db.query('SELECT id,to_jsonb(m) row FROM matches m ORDER BY id')).rows,before);
 assert.deepEqual((await db.query('SELECT id,to_jsonb(v) row FROM public_calendar v ORDER BY id')).rows,publicBefore);
 assert.deepEqual((await db.query('SELECT id,to_jsonb(t) row FROM teams t ORDER BY id')).rows,teamsBefore);
 assert.equal((await db.query("SELECT pg_get_viewdef('public_calendar'::regclass,true) def")).rows[0].def,viewBefore);
 candidates=[{...main,issues:['MULTIPLE_OFFICIAL_IDS'],publishable_after_review:false}];await reject(await configured(),/non approuvé/);
 candidates=[{...main,local_time:'00:00',starts_local:'2026-11-28T00:00:00'}];await reject(await configured(),/invalide/);
 const live=JSON.parse(fs.readFileSync(path.join(dir,'resultat-preview-local.json')));
 const realCandidates=live.candidates.filter(r=>r.publishable_after_review&&r.issues.length===0);
 assert.equal(realCandidates.length,11);
 candidates=realCandidates;await db.exec(await configured());
 assert.equal((await db.query('SELECT count(*)::int n FROM public_calendar')).rows[0].n,68);
 const liveUndo=(await db.query("SELECT id,md5((to_jsonb(m)-'updated_at')::text) current_md5 FROM matches m WHERE source_data->>'import_source'='esbb_ffbb_phase2'")).rows;
 await db.exec(undo.replace('$undo$[]$undo$',`$undo$${JSON.stringify(liveUndo)}$undo$`).replace("('verify')","('rollback')"));
 assert.deepEqual((await db.query('SELECT id,to_jsonb(m) row FROM matches m ORDER BY id')).rows,before);
 assert.deepEqual((await db.query('SELECT id,to_jsonb(v) row FROM public_calendar v ORDER BY id')).rows,publicBefore);
 console.log('OK données HTTP réelles en base SIMULÉE : 11 candidats non ambigus, 57→68→57 ; aucune approbation ou écriture de production.');
 console.log('OK PostgreSQL simulé : refus sans preuve source/revue, 57→59→57, heure inconnue avec date, vrais IDs, relance identique, protection des 57 lignes/tous parents/droits/vue, rollback limité, correction club et ambiguïtés protégées.');
}finally{await db.close()}})().catch(e=>{console.error({message:e.message,position:e.position,where:e.where});process.exitCode=1});
