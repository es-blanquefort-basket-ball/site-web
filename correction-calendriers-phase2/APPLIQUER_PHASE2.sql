-- CANDIDAT LOCAL. Aucun effet persistant en mode preview par défaut.
-- Jamais exécuter le ffbb-sync historique pour tester cet import.
-- Entrée : candidats du mode phase2_preview, transport complet, sans issues, puis revue humaine.
-- Les engagements actifs de phase 2 restent dans _shared/targets.ts : les champs historiques
-- des trois équipes existantes sont conservés pour ne pas changer leurs anciennes publications.
-- U18M est créé hors cron historique (is_competition_active=false), public pour les matchs validés.
BEGIN;
SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='60s';
CREATE TEMP TABLE p2_options(action text,transport_edge_verified boolean) ON COMMIT DROP;
INSERT INTO p2_options VALUES ('preview',false);
CREATE TEMP TABLE p2_input ON COMMIT DROP AS
SELECT value AS candidate FROM jsonb_array_elements($candidates$[]$candidates$::jsonb);
CREATE TEMP TABLE p2_approval ON COMMIT DROP AS
SELECT * FROM jsonb_to_recordset($approval$[]$approval$::jsonb) AS x(ffbb_match_id text,expected_md5 text);
-- Le preview affiche le MD5 exact de chaque JSONB. Le recopier après revue dans approval.
-- Cette empreinte contrôle les modifications depuis la revue ; ce n'est pas une signature d'autorisation.
CREATE TEMP TABLE p2_targets(code text PRIMARY KEY,team_id_ffbb text,competition text,phase text,pool text,team_url text) ON COMMIT DROP;
INSERT INTO p2_targets VALUES
('U13F','200000005408294','DFU13-3','200000002902208','200000003064585','https://competitions.ffbb.com/ligues/naq/comites/0033/clubs/naq0033034/equipes/200000005408294'),
('U13M','200000005416665','DMU13-4','200000002902520','200000003065651','https://competitions.ffbb.com/ligues/naq/comites/0033/clubs/naq0033034/equipes/200000005416665'),
('U15M','200000005414841','DMU15-3','200000002902453','200000003065402','https://competitions.ffbb.com/ligues/naq/comites/0033/clubs/naq0033034/equipes/200000005414841'),
('U18M','200000005419968','DMU18-4','200000002902228','200000003064624','https://competitions.ffbb.com/ligues/naq/comites/0033/clubs/naq0033034/equipes/200000005419968');
CREATE TEMP TABLE p2_protected(id uuid PRIMARY KEY) ON COMMIT DROP;
INSERT INTO p2_protected VALUES
('183828ad-317b-458c-8fe2-f73417c30cc1'::uuid),
('f0830283-47b4-4e06-a2ca-6248018d69d4'::uuid),
('d628b220-fac7-4cd9-890b-9a849ea9c0ca'::uuid),
('2616d29d-e827-4767-a571-587e336aed47'::uuid),
('373cd4db-2b6a-4971-b9bc-8b8a93945d53'::uuid),
('648cc81d-9d2d-4349-84f0-be77281a5e1c'::uuid),
('b5e148a2-68e2-4bc3-8cca-0d4d2ad5307e'::uuid),
('e9230514-52b1-42af-ab15-7b04a7109989'::uuid),
('f0833e8b-fb99-4381-afa8-8991f380026c'::uuid),
('fff26be8-21e1-485e-97b6-2eec1c3525e2'::uuid),
('7ecdd788-c79e-4b6b-bf5c-0b496c3e8000'::uuid),
('59e597c8-1200-4d5c-ad37-40c7976cea2b'::uuid),
('2c3515f1-0dab-47f4-aeac-802a8ce815fb'::uuid),
('dcd56f7b-bc04-47a8-bb77-a784d43549fe'::uuid),
('ed40463c-94e0-442e-89ae-b4bb41874582'::uuid),
('19193ec6-7a63-4603-a1b4-d6c14c8d1d6b'::uuid),
('003f7d89-fb32-4662-82a6-d73e7c480c26'::uuid),
('23769dde-7e51-41c6-ba78-e51b9042e520'::uuid),
('954a3abd-1eb1-4b46-bfd8-3213a558afa2'::uuid),
('12b7f7fc-ba19-4b28-981c-6ad7afe3c7e2'::uuid),
('dbb172d5-06ba-424e-bac2-621fcd76f007'::uuid),
('fc040408-b41e-4f40-a8a5-3010f708232f'::uuid),
('c771679c-0ddd-49a8-bfcd-0601cba69cfa'::uuid),
('23210dfa-1c6b-4c86-8774-7dc832b8eb21'::uuid),
('c5e2230c-1b76-4a86-8cdc-862da0231acc'::uuid),
('7c182800-7178-4f5c-8e6c-dfd56d55f04a'::uuid),
('759cec75-e19a-4c7d-9723-52d2f839232a'::uuid),
('9ba2a930-a4b1-4af0-a15b-5b14f0565e6b'::uuid),
('890e8fa7-a20f-41a8-ae20-8b3fd5377d43'::uuid),
('490a9e79-17e8-4e21-9c4b-ad191a48cc6f'::uuid),
('14cfcc18-737c-4beb-99a9-d2bdd6dd2e1c'::uuid),
('24456ec4-1107-48e5-92e9-246d03d504c2'::uuid),
('962fecdc-3bdc-4676-b91d-7d0bcf5c8f72'::uuid),
('b0206011-7df4-4cdd-86cd-40f957a3dddd'::uuid),
('bbd6e7fa-d072-4df8-b93d-5a7d14b07e50'::uuid),
('158617ea-a5f8-4dad-84bd-7cf5f7425787'::uuid),
('246ddf9c-ceb9-47e6-9255-e13e33326d9c'::uuid),
('65fa7e8c-84c7-4420-b710-eb50919b7aec'::uuid),
('a0cfbe06-1f45-4d42-915d-87432314c52b'::uuid),
('eb12b459-1c3a-4e31-920a-e1af1dec4897'::uuid),
('d58f4e09-75d1-4db5-b139-5b44260d92b2'::uuid),
('b011b3b2-5f7d-4105-9f8e-7a0eab5c2808'::uuid),
('c0ee70ad-155a-4a65-ae27-be33b125beb0'::uuid),
('cb69f1f2-7a87-4f45-8a27-d819fb6fabf6'::uuid),
('4d6a52f4-0a46-4e64-bc6a-8f3912b6f19f'::uuid),
('5b6904aa-c199-4426-8b41-6b7f0cbb3f21'::uuid),
('49ae4c5e-1c1e-4715-b39b-679adc902e8c'::uuid),
('91583827-3368-4425-a899-bae71fba295d'::uuid),
('7a562d25-1973-4950-aa1e-89d42199abd4'::uuid),
('29284ed9-bf02-49d0-af22-4e45ef36c75a'::uuid),
('f3bda005-cb6b-4548-9c00-050b1a5911f9'::uuid),
('22cc07eb-f721-49bc-8b45-9c424bd32445'::uuid),
('2c8aa6a8-eb30-4c17-984b-6ee80666fab3'::uuid),
('b555ee07-5417-414e-b2c6-38ccc9587de5'::uuid),
('e9889eb4-fc30-4a02-877e-990e7b8b17ce'::uuid),
('217f82e0-a04c-4866-a020-e8d090626a2e'::uuid),
('b4440a43-18e6-48ba-9ffc-9b1af83d7272'::uuid);
CREATE TEMP TABLE p2_plan ON COMMIT DROP AS
SELECT c.candidate,md5(c.candidate::text) AS candidate_md5,
       c.candidate->>'ffbb_match_id' AS match_id,c.candidate->>'team_code' AS code,
       m.id AS existing_id,m.source_data,
       CASE WHEN t.code IS NULL THEN 'engagement_incompatible'
         WHEN c.candidate->'issues' IS DISTINCT FROM '[]'::jsonb
           OR c.candidate->'publishable_after_review' IS DISTINCT FROM 'true'::jsonb THEN 'source_a_controler'
         WHEN NOT EXISTS (SELECT 1 FROM p2_approval a WHERE a.ffbb_match_id=c.candidate->>'ffbb_match_id'
           AND a.expected_md5=md5(c.candidate::text)) THEN 'validation_requise'
         WHEN m.id IN (SELECT id FROM p2_protected) THEN 'rencontre_protegee'
         WHEN m.id IS NOT NULL AND (m.source_data->>'import_source' IS DISTINCT FROM 'esbb_ffbb_phase2'
           OR m.source_data->'candidate' IS DISTINCT FROM c.candidate) THEN 'conflit_existant'
         WHEN m.id IS NOT NULL THEN 'inchange'
         ELSE 'creation' END AS result
FROM p2_input c
LEFT JOIN p2_targets t ON t.code=c.candidate->>'team_code'
 AND t.team_id_ffbb=c.candidate->>'ffbb_team_id'
 AND t.competition=c.candidate->>'competition_label'
 AND t.phase=c.candidate->>'phase' AND t.pool=c.candidate->>'pool'
 AND t.team_url=c.candidate->>'ffbb_team_url'
LEFT JOIN public.matches m ON m.ffbb_match_id=c.candidate->>'ffbb_match_id';
SELECT code,match_id,candidate_md5,result,candidate FROM p2_plan ORDER BY code,match_id;

DO $apply$
DECLARE old_view text; projection text:=''; expression text; col record; options text[]; old_acl aclitem[]; view_oid oid;
BEGIN
 IF (SELECT action FROM p2_options) NOT IN ('preview','apply') THEN RAISE EXCEPTION 'Action inconnue'; END IF;
 IF (SELECT action FROM p2_options)='preview' THEN RETURN; END IF;
 IF NOT (SELECT transport_edge_verified FROM p2_options) THEN
   RAISE EXCEPTION 'Confirmer un preview complet sans HTTP 403 depuis Supabase NON PRODUCTIF avant application'; END IF;
 IF NOT EXISTS (SELECT 1 FROM p2_input) THEN RAISE EXCEPTION 'Lot vide'; END IF;
 IF EXISTS (SELECT 1 FROM p2_input GROUP BY candidate->>'ffbb_match_id' HAVING count(*)>1)
   OR EXISTS (SELECT 1 FROM p2_approval GROUP BY ffbb_match_id HAVING count(*)>1) THEN RAISE EXCEPTION 'Identifiant dupliqué'; END IF;
 IF EXISTS (SELECT 1 FROM p2_plan WHERE result NOT IN ('creation','inchange')) THEN
   RAISE EXCEPTION 'Plan non approuvé ou conflit : aucune écriture'; END IF;
 -- Validation stricte des références, dates et heures avant DML.
 IF EXISTS (SELECT 1 FROM p2_plan p JOIN p2_targets t ON t.code=p.code WHERE
     COALESCE(p.match_id,'') !~ '^\d+$'
     OR p.candidate->>'ffbb_match_url' IS DISTINCT FROM
        'https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/'||lower(t.competition)||'/match/'||p.match_id
     OR COALESCE(p.candidate->>'local_date','') !~ '^\d{4}-\d{2}-\d{2}$'
     OR COALESCE(p.candidate->>'home_away','') NOT IN ('home','away','neutral')
     OR COALESCE(p.candidate->>'opponent_name','')=''
     OR p.candidate->>'status' IS DISTINCT FROM 'scheduled'
     OR to_char((p.candidate->>'local_date')::date,'YYYY-MM-DD') IS DISTINCT FROM p.candidate->>'local_date'
     OR (p.candidate->>'local_time' IS NOT NULL AND p.candidate->>'local_time' !~ '^([01]\d|2[0-3]):[0-5]\d$')
     OR (p.candidate->>'local_time')::time='00:00'::time
     OR (p.candidate->>'scheduled_at_ffbb')::timestamptz IS DISTINCT FROM
       ((p.candidate->>'starts_local')::timestamp AT TIME ZONE 'Europe/Paris')
     OR p.candidate->>'starts_local' IS DISTINCT FROM
       CASE WHEN p.candidate->>'local_time' IS NULL THEN NULL
         ELSE (p.candidate->>'local_date')||'T'||to_char((p.candidate->>'local_time')::time,'HH24:MI:SS') END
   ) THEN RAISE EXCEPTION 'Référence ou date/heure invalide'; END IF;
 SET CONSTRAINTS ALL IMMEDIATE;
 PERFORM pg_advisory_xact_lock(202627,1104);
 LOCK TABLE public.matches,public.teams IN SHARE ROW EXCLUSIVE MODE;
 -- Le plan doit être relu sous verrou pour exclure toute écriture concurrente depuis le preview SQL.
 IF EXISTS (SELECT 1 FROM p2_plan p WHERE EXISTS (SELECT 1 FROM public.matches m
   WHERE m.ffbb_match_id=p.match_id AND (p.existing_id IS NULL OR m.id<>p.existing_id
     OR m.source_data IS DISTINCT FROM p.source_data))) THEN RAISE EXCEPTION 'Plan devenu périmé'; END IF;
 CREATE TEMP TABLE p2_before_matches ON COMMIT DROP AS SELECT id,to_jsonb(m) row_data FROM public.matches m;
 CREATE TEMP TABLE p2_before_teams ON COMMIT DROP AS SELECT id,to_jsonb(t) row_data FROM public.teams t;
 CREATE TEMP TABLE p2_before_public ON COMMIT DROP AS SELECT id,to_jsonb(v) row_data FROM public.public_calendar v;
 IF (SELECT count(*) FROM public.public_calendar v JOIN p2_protected p ON p.id=v.id)<>57 THEN
   RAISE EXCEPTION 'Les 57 publications protégées ne sont plus toutes présentes'; END IF;
 IF EXISTS (SELECT 1 FROM public.matches m JOIN p2_plan p ON m.ffbb_match_url=p.candidate->>'ffbb_match_url'
   WHERE m.ffbb_match_id IS DISTINCT FROM p.match_id) THEN RAISE EXCEPTION 'Même URL sous ancienne clé synthétique : rapprochement manuel'; END IF;
 -- Aucune mise à jour du parent historique : sa compétition et ses liens resteraient sinon réécrits dans la vue.
 CREATE TEMP TABLE p2_owned_teams ON COMMIT DROP AS WITH inserted AS (
 INSERT INTO public.teams(code,name,competition_label,ffbb_team_id,is_competition_active,is_public)
 SELECT DISTINCT p.code,p.code,t.competition,t.team_id_ffbb,false,true
 FROM p2_plan p JOIN p2_targets t ON t.code=p.code
 WHERE p.code='U18M' AND NOT EXISTS (SELECT 1 FROM public.teams x WHERE x.code=p.code) RETURNING *
 ) SELECT id,to_jsonb(inserted) row_data FROM inserted;
 IF EXISTS (SELECT 1 FROM p2_plan p LEFT JOIN public.teams t ON t.code=p.code WHERE t.id IS NULL OR t.is_public IS DISTINCT FROM true) THEN
   RAISE EXCEPTION 'Équipe interne absente ou privée'; END IF;
 INSERT INTO public.matches(team_id,ffbb_match_id,ffbb_match_url,opponent_name,home_away,
   scheduled_at,scheduled_at_ffbb,scheduled_local_ffbb,scheduled_local_override,venue_id,venue_name_raw,venue_address_raw,
   competition_name,round_label,status,published,has_conflict,source_data)
 SELECT t.id,p.match_id,p.candidate->>'ffbb_match_url',p.candidate->>'opponent_name',p.candidate->>'home_away',
   (p.candidate->>'scheduled_at_ffbb')::timestamptz,(p.candidate->>'scheduled_at_ffbb')::timestamptz,
   (p.candidate->>'starts_local')::timestamp,NULL,NULL,p.candidate->>'venue_name',p.candidate->>'venue_address',
   p.candidate->>'competition_label',p.candidate->>'round_label','scheduled',true,false,
   jsonb_build_object('import_source','esbb_ffbb_phase2','candidate',p.candidate,
     'approved_candidate_md5',p.candidate_md5,'local_date',p.candidate->>'local_date',
     'time_known',p.candidate->>'local_time' IS NOT NULL,'ffbb_team_url',p.candidate->>'ffbb_team_url',
     'created_team_snapshot',(SELECT o.row_data FROM p2_owned_teams o WHERE o.id=t.id))
 FROM p2_plan p JOIN public.teams t ON t.code=p.code WHERE p.result='creation';
 -- Adapter uniquement la nouvelle origine ; toute la vue actuelle, y compris MiniBasket, reste la branche historique.
 IF EXISTS (SELECT 1 FROM p2_plan WHERE result='creation') THEN
   view_oid:='public.public_calendar'::regclass;
   SELECT pg_get_viewdef(view_oid,true),reloptions,relacl INTO old_view,options,old_acl FROM pg_class WHERE oid=view_oid;
   FOR col IN SELECT attname,format_type(atttypid,atttypmod) typ FROM pg_attribute
     WHERE attrelid=view_oid AND attnum>0 AND NOT attisdropped ORDER BY attnum LOOP
     expression:=CASE col.attname
       WHEN 'id' THEN 'm.id' WHEN 'team_code' THEN 't.code' WHEN 'team_name' THEN 't.name'
       WHEN 'competition_label' THEN 'm.competition_name'
       WHEN 'starts_local' THEN 'COALESCE(m.scheduled_local_override,m.scheduled_local_ffbb)'
       WHEN 'status' THEN 'm.status' WHEN 'updated_at' THEN 'm.updated_at'
       WHEN 'opponent_name' THEN 'm.opponent_name' WHEN 'home_away' THEN 'm.home_away'
       WHEN 'local_date' THEN $$COALESCE(m.scheduled_local_override::date,NULLIF(m.source_data->>'local_date','')::date,m.scheduled_local_ffbb::date)$$
       WHEN 'local_time' THEN $$NULLIF(COALESCE(m.scheduled_local_override,m.scheduled_local_ffbb)::time,'00:00'::time)$$
       WHEN 'venue_name' THEN 'm.venue_name_raw' WHEN 'venue_address' THEN 'm.venue_address_raw'
       WHEN 'round_label' THEN 'm.round_label' WHEN 'ffbb_match_url' THEN 'm.ffbb_match_url'
       WHEN 'ffbb_team_url' THEN $$m.source_data->>'ffbb_team_url'$$ ELSE 'NULL' END;
     projection:=projection||CASE WHEN projection='' THEN '' ELSE ',' END||format('(%s)::%s AS %I',expression,col.typ,col.attname);
   END LOOP;
   EXECUTE format($view$CREATE OR REPLACE VIEW public.public_calendar %s AS
     SELECT legacy.* FROM (%s) legacy WHERE NOT EXISTS (SELECT 1 FROM public.matches m
       WHERE m.id=legacy.id AND m.source_data->>'import_source'='esbb_ffbb_phase2')
     UNION ALL SELECT %s FROM public.matches m JOIN public.teams t ON t.id=m.team_id
       WHERE m.source_data->>'import_source'='esbb_ffbb_phase2' AND m.published AND NOT m.has_conflict AND t.is_public$view$,
     CASE WHEN options IS NULL THEN '' ELSE 'WITH ('||array_to_string(options,',')||')' END,
     regexp_replace(old_view,';[[:space:]]*$',''),projection);
   UPDATE public.matches m SET source_data=m.source_data||jsonb_build_object(
     'rollback_snapshot',to_jsonb(m)-'source_data'-'updated_at',
     'view_before',old_view,'view_installed',pg_get_viewdef(view_oid,true))
   WHERE m.id NOT IN (SELECT id FROM p2_before_matches)
     AND m.source_data->>'import_source'='esbb_ffbb_phase2';
   IF EXISTS(SELECT 1 FROM pg_class WHERE oid=view_oid AND (relacl IS DISTINCT FROM old_acl OR reloptions IS DISTINCT FROM options)) THEN
     RAISE EXCEPTION 'Droits ou options de vue changés'; END IF;
 END IF;
 IF EXISTS (SELECT 1 FROM p2_before_matches b LEFT JOIN public.matches m ON m.id=b.id
   WHERE m.id IS NULL OR to_jsonb(m) IS DISTINCT FROM b.row_data) THEN RAISE EXCEPTION 'Rencontre existante modifiée'; END IF;
 IF EXISTS (SELECT 1 FROM p2_before_teams b LEFT JOIN public.teams t ON t.id=b.id
   WHERE t.id IS NULL OR to_jsonb(t) IS DISTINCT FROM b.row_data) THEN RAISE EXCEPTION 'Équipe existante modifiée'; END IF;
 IF EXISTS (SELECT 1 FROM p2_before_public b LEFT JOIN public.public_calendar v ON v.id=b.id
   WHERE v.id IS NULL OR to_jsonb(v) IS DISTINCT FROM b.row_data) THEN RAISE EXCEPTION 'Publication existante modifiée'; END IF;
 IF EXISTS (SELECT 1 FROM p2_plan p WHERE (SELECT count(*) FROM public.public_calendar v JOIN public.matches m ON m.id=v.id
   WHERE m.ffbb_match_id=p.match_id AND v.id=m.id AND v.team_code=p.code
     AND v.local_date::date=(p.candidate->>'local_date')::date
     AND NULLIF(v.local_time::text,'')::time IS NOT DISTINCT FROM (p.candidate->>'local_time')::time)<>1) THEN
   RAISE EXCEPTION 'Date/heure ou publication finale non conforme'; END IF;
END
$apply$;
-- Conserver cette sortie privée avec la revue ; les UUID sont la portée exacte du retour arrière.
SELECT m.id,m.ffbb_match_id,md5((to_jsonb(m)-'updated_at')::text) AS current_md5
FROM public.matches m JOIN p2_plan p ON p.match_id=m.ffbb_match_id
WHERE m.source_data->>'import_source'='esbb_ffbb_phase2';
COMMIT;
