-- U18M : import FBI autonome. Aucun appel réseau, cron, score ou ID FFBB inventé.
-- Modes verify/import/rollback. Seul verify est sélectionné ; autorisation humaine requise pour les autres.
-- Aucun des scripts MiniBasket/phase2 existants n'est modifié.
BEGIN;
SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='60s';
CREATE TEMP TABLE u18_options(action text,approved boolean) ON COMMIT DROP;
INSERT INTO u18_options VALUES ('verify',false);
CREATE TEMP TABLE u18_protected(id uuid PRIMARY KEY) ON COMMIT DROP;
INSERT INTO u18_protected VALUES
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
CREATE TEMP TABLE u18_input ON COMMIT DROP AS
SELECT x.*, '2026-2027'::text season_scope, 'DMU18-4-P2'::text competition_code,
 'U18M'::text team_code, 'u18m-fbi-2026-2027-2026-11-04'::text batch_id,
 'DMU18-4-P2|U18M|'||x.fbi_match_number AS source_match_key,
 x.local_date::date + NULLIF(x.local_time,'')::time AS starts_local,
 '987ba1f290a4a40817bdba0a7c85a300959ed184fe2c156d828b75f03029f64b'::text source_sha256
FROM jsonb_to_recordset($fbi$[
  {
    "fbi_match_number": "15",
    "local_date": "2026-11-08",
    "local_time": "11:00",
    "opponent_name": "STE EULALIE BASKET BALL",
    "home_away": "away",
    "venue_name": "Salle Valériane Ayayi",
    "source_cells": "rechercherRencontre!A2:G2"
  },
  {
    "fbi_match_number": "16",
    "local_date": "2026-11-15",
    "local_time": "11:00",
    "opponent_name": "IE - CTC BASKET HAUTE GIRONDE - BASKET CLUB ESTUAIRE GIRONDE - 1",
    "home_away": "home",
    "venue_name": "SALLE PORT DU ROY",
    "source_cells": "rechercherRencontre!A3:G3"
  },
  {
    "fbi_match_number": "20",
    "local_date": "2026-11-29",
    "local_time": "11:00",
    "opponent_name": "UNION SPORTIVE BAZAS - 2",
    "home_away": "home",
    "venue_name": "SALLE PORT DU ROY",
    "source_cells": "rechercherRencontre!A4:G4"
  },
  {
    "fbi_match_number": "23",
    "local_date": "2026-12-06",
    "local_time": "11:00",
    "opponent_name": "COUTRAS GUITRES BASKET - 2",
    "home_away": "away",
    "venue_name": "SALLE DOURSAT",
    "source_cells": "rechercherRencontre!A5:G5"
  },
  {
    "fbi_match_number": "26",
    "local_date": "2026-12-13",
    "local_time": "11:00",
    "opponent_name": "LES PETITS MOUSSES LANGOIRAN - 2",
    "home_away": "away",
    "venue_name": "SALLE RENE BAILLET",
    "source_cells": "rechercherRencontre!A6:G6"
  }
]$fbi$::jsonb) AS x(
 fbi_match_number text,local_date text,local_time text,opponent_name text,home_away text,venue_name text,source_cells text);
ALTER TABLE u18_input ADD COLUMN expected_source jsonb;
UPDATE u18_input SET expected_source=jsonb_build_object(
 'import_source','esbb_u18m_fbi','season_scope',season_scope,'source_match_key',source_match_key,
 'batch_id',batch_id,'competition_code',competition_code,'fbi_match_number',fbi_match_number,
 'source_file','rechercherRencontre.xlsx','source_sha256',source_sha256,'source_cells',source_cells,
 'local_date',local_date,'time_known',local_time IS NOT NULL,'club_validated_fields','[]'::jsonb,
 'provider_baseline',jsonb_build_object('opponent_name',opponent_name,'home_away',home_away,
 'scheduled_local_ffbb',starts_local,'venue_name_raw',venue_name,'venue_address_raw',NULL,
 'competition_name',competition_code,'local_date',local_date,'time_known',local_time IS NOT NULL),
 'canonical_ffbb_status','unresolved');
CREATE TEMP VIEW u18_rows AS
SELECT m.id,m.team_id,m.source_data,s.source_match_key,
 ((m.source_data-ARRAY['rollback_snapshot','view_before','view_installed','created_team_snapshot'])=s.expected_source
  AND (to_jsonb(m)-'source_data'-'updated_at')=m.source_data->'rollback_snapshot'
  AND t.code='U18M' AND m.ffbb_match_id IS NULL AND m.ffbb_match_url IS NULL
  AND m.opponent_name=s.opponent_name AND m.home_away=s.home_away
  AND m.scheduled_local_ffbb IS NOT DISTINCT FROM s.starts_local AND m.scheduled_local_override IS NULL
  AND m.scheduled_at_ffbb IS NOT DISTINCT FROM (s.starts_local AT TIME ZONE 'Europe/Paris')
  AND m.scheduled_at IS NOT DISTINCT FROM (s.starts_local AT TIME ZONE 'Europe/Paris')
  AND m.venue_id IS NULL AND m.venue_name_raw=s.venue_name AND m.venue_address_raw IS NULL
  AND m.competition_name=s.competition_code AND m.round_label IS NULL
  AND m.status='scheduled' AND m.published AND NOT m.has_conflict) IS TRUE AS intact
FROM public.matches m JOIN public.teams t ON t.id=m.team_id
JOIN u18_input s ON m.source_data->>'season_scope'=s.season_scope
 AND m.source_data->>'source_match_key'=s.source_match_key
WHERE m.source_data->>'import_source'='esbb_u18m_fbi'
 AND m.source_data->>'batch_id'='u18m-fbi-2026-2027-2026-11-04';
SELECT s.source_match_key,s.local_date,s.local_time,s.opponent_name,s.home_away,s.venue_name,
 r.id,CASE WHEN r.id IS NULL THEN 'creation_a_valider' WHEN r.intact THEN 'identique' ELSE 'modifie_ne_pas_ecraser' END AS plan
FROM u18_input s LEFT JOIN u18_rows r USING(source_match_key) ORDER BY s.local_date;
DO $operation$
DECLARE opt u18_options%ROWTYPE; old_view text; installed_view text; view_oid oid;
 options text[]; acl aclitem[]; projection text:=''; expression text; col record; idx oid;
BEGIN
 SELECT * INTO STRICT opt FROM u18_options;
 IF opt.action NOT IN ('verify','import','rollback') THEN RAISE EXCEPTION 'Action inconnue'; END IF;
 IF (SELECT count(*) FROM u18_input)<>5 OR
    (SELECT array_agg(fbi_match_number ORDER BY fbi_match_number) FROM u18_input)<>ARRAY['15','16','20','23','26']
    OR EXISTS(SELECT 1 FROM u18_input WHERE local_time IS DISTINCT FROM '11:00'
       OR opponent_name IS NULL OR venue_name IS NULL OR home_away NOT IN ('home','away')) THEN
   RAISE EXCEPTION 'Lot FBI invalide'; END IF;
 IF EXISTS(SELECT 1 FROM u18_rows WHERE NOT intact) OR (SELECT count(*) FROM u18_rows) NOT IN (0,5) THEN
   RAISE EXCEPTION 'Lot incomplet ou modifié : aucune réparation ni écrasement automatique'; END IF;
 IF EXISTS(SELECT 1 FROM public.matches m JOIN u18_input s
   ON m.source_data->>'season_scope'=s.season_scope AND m.source_data->>'source_match_key'=s.source_match_key
   WHERE NOT EXISTS(SELECT 1 FROM u18_rows r WHERE r.id=m.id AND r.intact)) THEN
   RAISE EXCEPTION 'Provenance déjà utilisée hors lot'; END IF;
 -- Une rencontre U18M préexistante non reconnue exige un rapprochement ; jamais de fusion sur date/adversaire.
 IF EXISTS(SELECT 1 FROM public.matches m JOIN public.teams t ON t.id=m.team_id WHERE t.code='U18M'
   AND NOT EXISTS(SELECT 1 FROM u18_rows r WHERE r.id=m.id)) THEN
   RAISE EXCEPTION 'Rencontre U18M préexistante hors lot : rapprochement requis'; END IF;
 IF EXISTS(SELECT 1 FROM public.teams WHERE code='U18M' AND
   (is_public IS DISTINCT FROM true OR is_competition_active IS DISTINCT FROM false)) THEN
   RAISE EXCEPTION 'Équipe U18M privée ou active dans la synchronisation : revue requise'; END IF;
 IF (SELECT count(*) FROM public.public_calendar v JOIN u18_protected p ON p.id=v.id)<>57 THEN
   RAISE EXCEPTION 'Les 57 publications protégées ne sont plus toutes présentes'; END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_attribute WHERE attrelid='public.public_calendar'::regclass AND attname='id' AND attnum>0 AND NOT attisdropped) THEN
   RAISE EXCEPTION 'public_calendar doit exposer matches.id'; END IF;
 IF opt.action='verify' THEN
   IF (SELECT count(*) FROM u18_rows)=5 AND EXISTS(
     SELECT 1 FROM u18_input s JOIN u18_rows r USING(source_match_key)
     WHERE (SELECT count(*) FROM public.public_calendar v WHERE v.id=r.id AND v.team_code='U18M'
       AND v.local_date::date=s.local_date::date AND v.local_time::time=s.local_time::time
       AND v.venue_name=s.venue_name AND v.opponent_name=s.opponent_name
       AND v.competition_label='DMU18-4-P2')<>1) THEN
     RAISE EXCEPTION 'Vérification : publications U18M non conformes'; END IF;
   RETURN;
 END IF;
 IF opt.approved IS DISTINCT FROM true THEN RAISE EXCEPTION 'Autorisation humaine requise'; END IF;
 PERFORM pg_advisory_xact_lock(202627,1118);
 LOCK TABLE public.matches,public.teams IN SHARE ROW EXCLUSIVE MODE;
 -- Relire les contrôles sensibles sous verrou : les vues temporaires relisent les tables actuelles.
 IF EXISTS(SELECT 1 FROM u18_rows WHERE NOT intact) OR (SELECT count(*) FROM u18_rows) NOT IN (0,5)
 OR EXISTS(SELECT 1 FROM public.matches m JOIN public.teams t ON t.id=m.team_id WHERE t.code='U18M'
   AND NOT EXISTS(SELECT 1 FROM u18_rows r WHERE r.id=m.id AND r.intact)) THEN
   RAISE EXCEPTION 'État devenu périmé sous verrou'; END IF;
 IF EXISTS(SELECT 1 FROM public.teams WHERE code='U18M' AND
   (is_public IS DISTINCT FROM true OR is_competition_active IS DISTINCT FROM false)) THEN
   RAISE EXCEPTION 'Équipe devenue incompatible'; END IF;
 IF (SELECT count(*) FROM public.public_calendar v JOIN u18_protected p ON p.id=v.id)<>57 THEN
   RAISE EXCEPTION 'Les 57 publications ont changé sous verrou'; END IF;
 IF EXISTS(SELECT 1 FROM public.matches m JOIN u18_input s
   ON m.source_data->>'season_scope'=s.season_scope AND m.source_data->>'source_match_key'=s.source_match_key
   WHERE NOT EXISTS(SELECT 1 FROM u18_rows r WHERE r.id=m.id AND r.intact)) THEN
   RAISE EXCEPTION 'Provenance devenue incompatible sous verrou'; END IF;
 CREATE TEMP TABLE u18_before_matches ON COMMIT DROP AS
 SELECT id,to_jsonb(m) row_data FROM public.matches m WHERE NOT EXISTS(SELECT 1 FROM u18_rows r WHERE r.id=m.id);
 CREATE TEMP TABLE u18_before_teams ON COMMIT DROP AS SELECT id,to_jsonb(t) row_data FROM public.teams t;
 CREATE TEMP TABLE u18_before_public ON COMMIT DROP AS
 SELECT id,to_jsonb(v) row_data FROM public.public_calendar v WHERE NOT EXISTS(SELECT 1 FROM u18_rows r WHERE r.id=v.id);
 CREATE TEMP TABLE u18_owned(id uuid,row_data jsonb) ON COMMIT DROP;
 view_oid:='public.public_calendar'::regclass;
 SELECT pg_get_viewdef(view_oid,true),reloptions,relacl INTO old_view,options,acl FROM pg_class WHERE oid=view_oid;
 IF opt.action='import' THEN
   CREATE UNIQUE INDEX IF NOT EXISTS esbb_u18m_fbi_source_uidx ON public.matches
    ((source_data->>'season_scope'),(source_data->>'source_match_key')) WHERE source_data->>'import_source'='esbb_u18m_fbi';
   CREATE TEMP TABLE u18_index_reference(source_data jsonb) ON COMMIT DROP;
   CREATE UNIQUE INDEX u18_expected_index ON u18_index_reference
    ((source_data->>'season_scope'),(source_data->>'source_match_key')) WHERE source_data->>'import_source'='esbb_u18m_fbi';
   idx:=to_regclass('public.esbb_u18m_fbi_source_uidx');
   IF NOT EXISTS(SELECT 1 FROM pg_index i WHERE indexrelid=idx AND indrelid='public.matches'::regclass
    AND indisunique AND indisvalid AND indnkeyatts=2 AND indnatts=2
    AND pg_get_expr(indpred,indrelid)=(SELECT pg_get_expr(indpred,indrelid) FROM pg_index WHERE indexrelid='u18_expected_index'::regclass)
    AND pg_get_indexdef(idx,1,true)=pg_get_indexdef('u18_expected_index'::regclass,1,true)
    AND pg_get_indexdef(idx,2,true)=pg_get_indexdef('u18_expected_index'::regclass,2,true)) THEN
    RAISE EXCEPTION 'Index de provenance incompatible'; END IF;
   IF (SELECT count(*) FROM u18_rows)=0 THEN
     -- Création du seul parent manquant ; aucun UPDATE du parent existant.
     WITH created AS (INSERT INTO public.teams(code,name,competition_label,ffbb_team_id,is_public,is_competition_active)
       SELECT 'U18M','U18M','DMU18-4-P2',NULL,true,false
       WHERE NOT EXISTS(SELECT 1 FROM public.teams WHERE code='U18M') RETURNING *)
     INSERT INTO u18_owned SELECT id,to_jsonb(created) FROM created;
     INSERT INTO public.matches(team_id,ffbb_match_id,ffbb_match_url,opponent_name,home_away,
       scheduled_at,scheduled_at_ffbb,scheduled_local_ffbb,scheduled_local_override,venue_id,venue_name_raw,venue_address_raw,
       competition_name,round_label,status,published,has_conflict,source_data)
     SELECT t.id,NULL,NULL,s.opponent_name,s.home_away,s.starts_local AT TIME ZONE 'Europe/Paris',
       s.starts_local AT TIME ZONE 'Europe/Paris',s.starts_local,NULL,NULL,s.venue_name,NULL,
       s.competition_code,NULL,'scheduled',true,false,
       s.expected_source||jsonb_build_object('created_team_snapshot',(SELECT o.row_data FROM u18_owned o WHERE o.id=t.id))
     FROM u18_input s JOIN public.teams t ON t.code=s.team_code;
     FOR col IN SELECT attname,format_type(atttypid,atttypmod) typ FROM pg_attribute
       WHERE attrelid=view_oid AND attnum>0 AND NOT attisdropped ORDER BY attnum LOOP
       expression:=CASE col.attname
         WHEN 'id' THEN 'm.id' WHEN 'team_code' THEN 't.code' WHEN 'team_name' THEN 't.name'
         WHEN 'competition_label' THEN 'm.competition_name'
         WHEN 'starts_local' THEN 'COALESCE(m.scheduled_local_override,m.scheduled_local_ffbb)'
         WHEN 'status' THEN 'm.status' WHEN 'updated_at' THEN 'm.updated_at'
         WHEN 'opponent_name' THEN 'm.opponent_name' WHEN 'home_away' THEN 'm.home_away'
         WHEN 'local_date' THEN $$COALESCE(m.scheduled_local_override::date,m.scheduled_local_ffbb::date,NULLIF(m.source_data->>'local_date','')::date)$$
         WHEN 'local_time' THEN $$NULLIF(COALESCE(m.scheduled_local_override,m.scheduled_local_ffbb)::time,'00:00'::time)$$
         WHEN 'venue_name' THEN 'm.venue_name_raw' WHEN 'venue_address' THEN 'm.venue_address_raw'
         WHEN 'round_label' THEN 'm.round_label'
         WHEN 'ffbb_match_url' THEN 'm.ffbb_match_url'
         -- Aucun lien de fiche canonique ni score : les colonnes supplémentaires sont NULL pour U18M.
         ELSE 'NULL' END;
       projection:=projection||CASE WHEN projection='' THEN '' ELSE ',' END||format('(%s)::%s AS %I',expression,col.typ,col.attname);
     END LOOP;
     EXECUTE format($view$CREATE OR REPLACE VIEW public.public_calendar %s AS
       SELECT legacy.* FROM (%s) legacy WHERE NOT EXISTS(SELECT 1 FROM public.matches m
         WHERE m.id=legacy.id AND m.source_data->>'import_source'='esbb_u18m_fbi')
       UNION ALL SELECT %s FROM public.matches m JOIN public.teams t ON t.id=m.team_id
         WHERE m.source_data->>'import_source'='esbb_u18m_fbi' AND m.published AND NOT m.has_conflict AND t.is_public$view$,
       CASE WHEN options IS NULL THEN '' ELSE 'WITH ('||array_to_string(options,',')||')' END,
       regexp_replace(old_view,';[[:space:]]*$',''),projection);
     installed_view:=pg_get_viewdef(view_oid,true);
     UPDATE public.matches m SET source_data=source_data||jsonb_build_object(
       'rollback_snapshot',to_jsonb(m)-'source_data'-'updated_at','view_before',old_view,'view_installed',installed_view)
       WHERE m.id IN(SELECT id FROM u18_rows);
   ELSE
     IF EXISTS(SELECT 1 FROM u18_rows WHERE source_data->>'view_installed' IS DISTINCT FROM old_view) THEN
       RAISE EXCEPTION 'Vue changée depuis import : aucune réécriture automatique'; END IF;
   END IF;
   IF (SELECT count(*) FROM u18_rows WHERE intact)<>5 THEN RAISE EXCEPTION 'Lot final non conforme'; END IF;
   IF EXISTS(SELECT 1 FROM u18_input s JOIN u18_rows r USING(source_match_key)
    WHERE (SELECT count(*) FROM public.public_calendar v WHERE v.id=r.id AND v.team_code='U18M'
     AND v.local_date::date=s.local_date::date AND v.local_time::time=s.local_time::time
     AND v.opponent_name=s.opponent_name AND v.home_away=s.home_away AND v.venue_name=s.venue_name
     AND v.competition_label='DMU18-4-P2')<>1) THEN RAISE EXCEPTION 'Publication U18M non conforme'; END IF;
 ELSE
   IF (SELECT count(*) FROM u18_rows WHERE intact)<>5 THEN RAISE EXCEPTION 'Retour refusé : lot absent ou modifié'; END IF;
   IF (SELECT count(*) FROM public.matches WHERE source_data->>'import_source'='esbb_u18m_fbi'
       AND source_data->>'batch_id'='u18m-fbi-2026-2027-2026-11-04')<>5 THEN RAISE EXCEPTION 'Portée du lot inattendue'; END IF;
   SELECT source_data->>'view_before',source_data->>'view_installed' INTO old_view,installed_view FROM u18_rows LIMIT 1;
   IF old_view IS NULL OR pg_get_viewdef(view_oid,true) IS DISTINCT FROM installed_view OR
     EXISTS(SELECT 1 FROM u18_rows WHERE source_data->>'view_before' IS DISTINCT FROM old_view
       OR source_data->>'view_installed' IS DISTINCT FROM installed_view) THEN RAISE EXCEPTION 'Vue changée : retour refusé'; END IF;
   INSERT INTO u18_owned SELECT DISTINCT team_id,source_data->'created_team_snapshot' FROM u18_rows
     WHERE source_data->'created_team_snapshot' IS NOT NULL AND source_data->'created_team_snapshot'<>'null'::jsonb;
   IF EXISTS(SELECT 1 FROM u18_owned o JOIN public.teams t ON t.id=o.id WHERE to_jsonb(t) IS DISTINCT FROM o.row_data) THEN
     RAISE EXCEPTION 'Équipe créée modifiée : retour refusé'; END IF;
   DELETE FROM public.matches m WHERE m.id IN(SELECT id FROM u18_rows);
   DELETE FROM public.teams t USING u18_owned o WHERE t.id=o.id AND to_jsonb(t)=o.row_data
     AND NOT EXISTS(SELECT 1 FROM public.matches m WHERE m.team_id=t.id);
   IF EXISTS(SELECT 1 FROM public.matches WHERE source_data->>'import_source'='esbb_u18m_fbi') THEN
     RAISE EXCEPTION 'Autre lot dépendant de la vue : retour à examiner'; END IF;
   EXECUTE format('CREATE OR REPLACE VIEW public.public_calendar %s AS %s',
     CASE WHEN options IS NULL THEN '' ELSE 'WITH ('||array_to_string(options,',')||')' END,old_view);
 END IF;
 IF EXISTS(SELECT 1 FROM u18_before_matches b LEFT JOIN public.matches m ON m.id=b.id
    WHERE m.id IS NULL OR to_jsonb(m) IS DISTINCT FROM b.row_data)
 OR EXISTS(SELECT 1 FROM u18_before_public b LEFT JOIN public.public_calendar v ON v.id=b.id
    WHERE v.id IS NULL OR to_jsonb(v) IS DISTINCT FROM b.row_data) THEN RAISE EXCEPTION 'Rencontre hors lot modifiée'; END IF;
 IF EXISTS(SELECT 1 FROM u18_before_teams b LEFT JOIN public.teams t ON t.id=b.id
    WHERE (t.id IS NULL OR to_jsonb(t) IS DISTINCT FROM b.row_data)
      AND NOT(opt.action='rollback' AND t.id IS NULL AND EXISTS(SELECT 1 FROM u18_owned o WHERE o.id=b.id))) THEN
    RAISE EXCEPTION 'Équipe préexistante modifiée'; END IF;
 IF (SELECT count(*) FROM public.matches)<>(SELECT count(*) FROM u18_before_matches)+(CASE WHEN opt.action='import' THEN 5 ELSE 0 END) THEN
    RAISE EXCEPTION 'Nombre final inattendu'; END IF;
 IF 'public.public_calendar'::regclass::oid<>view_oid OR EXISTS(SELECT 1 FROM pg_class WHERE oid=view_oid
    AND (reloptions IS DISTINCT FROM options OR relacl IS DISTINCT FROM acl)) THEN RAISE EXCEPTION 'Droits/options de vue modifiés'; END IF;
END
$operation$;
SELECT o.action,(SELECT count(*) FROM public.public_calendar) AS publications,
 (SELECT count(*) FROM u18_rows) AS rencontres_du_lot,(SELECT count(*) FROM u18_rows WHERE intact) AS identiques
FROM u18_options o;
SELECT id,source_match_key,md5((source_data)::text) AS provenance_md5 FROM u18_rows;
COMMIT;
