-- U13F/U13M/U15M : import FBI autonome de 15 rencontres. Aucun appel réseau, cron, score ou ID FFBB inventé.
-- Modes verify/import/rollback. Seul verify est sélectionné ; autorisation humaine requise pour les autres.
-- Aucun des scripts MiniBasket/phase2 existants n'est modifié.
BEGIN;
SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='60s';
CREATE TEMP TABLE p15_options(action text,approved boolean) ON COMMIT DROP;
INSERT INTO p15_options VALUES ('verify',false);
CREATE TEMP TABLE p15_protected(id uuid PRIMARY KEY) ON COMMIT DROP;
INSERT INTO p15_protected VALUES
('183828ad-317b-458c-8fe2-f73417c30cc1'::uuid),
('f0830283-47b4-4e06-a2ca-6248018d69d4'::uuid),
('d628b220-fac7-4cd9-890b-9a849ea9c0ca'::uuid),
('2616d29d-e827-4767-a571-587e336aed47'::uuid),
('373cd4db-2b6a-4971-b9bc-8b8a93945d53'::uuid),
('b5e148a2-68e2-4bc3-8cca-0d4d2ad5307e'::uuid),
('648cc81d-9d2d-4349-84f0-be77281a5e1c'::uuid),
('e9230514-52b1-42af-ab15-7b04a7109989'::uuid),
('f0833e8b-fb99-4381-afa8-8991f380026c'::uuid),
('fff26be8-21e1-485e-97b6-2eec1c3525e2'::uuid),
('7ecdd788-c79e-4b6b-bf5c-0b496c3e8000'::uuid),
('59e597c8-1200-4d5c-ad37-40c7976cea2b'::uuid),
('dcd56f7b-bc04-47a8-bb77-a784d43549fe'::uuid),
('2c3515f1-0dab-47f4-aeac-802a8ce815fb'::uuid),
('19193ec6-7a63-4603-a1b4-d6c14c8d1d6b'::uuid),
('ed40463c-94e0-442e-89ae-b4bb41874582'::uuid),
('003f7d89-fb32-4662-82a6-d73e7c480c26'::uuid),
('23769dde-7e51-41c6-ba78-e51b9042e520'::uuid),
('12b7f7fc-ba19-4b28-981c-6ad7afe3c7e2'::uuid),
('dbb172d5-06ba-424e-bac2-621fcd76f007'::uuid),
('954a3abd-1eb1-4b46-bfd8-3213a558afa2'::uuid),
('c771679c-0ddd-49a8-bfcd-0601cba69cfa'::uuid),
('fc040408-b41e-4f40-a8a5-3010f708232f'::uuid),
('9ba2a930-a4b1-4af0-a15b-5b14f0565e6b'::uuid),
('759cec75-e19a-4c7d-9723-52d2f839232a'::uuid),
('7c182800-7178-4f5c-8e6c-dfd56d55f04a'::uuid),
('c5e2230c-1b76-4a86-8cdc-862da0231acc'::uuid),
('23210dfa-1c6b-4c86-8774-7dc832b8eb21'::uuid),
('890e8fa7-a20f-41a8-ae20-8b3fd5377d43'::uuid),
('490a9e79-17e8-4e21-9c4b-ad191a48cc6f'::uuid),
('189b75ac-d9cc-4d5c-9af6-29b4cafe6f27'::uuid),
('14cfcc18-737c-4beb-99a9-d2bdd6dd2e1c'::uuid),
('962fecdc-3bdc-4676-b91d-7d0bcf5c8f72'::uuid),
('bbd6e7fa-d072-4df8-b93d-5a7d14b07e50'::uuid),
('b0206011-7df4-4cdd-86cd-40f957a3dddd'::uuid),
('24456ec4-1107-48e5-92e9-246d03d504c2'::uuid),
('727f4932-52ce-423c-825c-438b13f6d639'::uuid),
('246ddf9c-ceb9-47e6-9255-e13e33326d9c'::uuid),
('158617ea-a5f8-4dad-84bd-7cf5f7425787'::uuid),
('a0cfbe06-1f45-4d42-915d-87432314c52b'::uuid),
('eb12b459-1c3a-4e31-920a-e1af1dec4897'::uuid),
('65fa7e8c-84c7-4420-b710-eb50919b7aec'::uuid),
('b011b3b2-5f7d-4105-9f8e-7a0eab5c2808'::uuid),
('cb69f1f2-7a87-4f45-8a27-d819fb6fabf6'::uuid),
('d58f4e09-75d1-4db5-b139-5b44260d92b2'::uuid),
('c0ee70ad-155a-4a65-ae27-be33b125beb0'::uuid),
('aacb7bb5-6259-4dca-9404-366c766b4ddd'::uuid),
('5b6904aa-c199-4426-8b41-6b7f0cbb3f21'::uuid),
('4d6a52f4-0a46-4e64-bc6a-8f3912b6f19f'::uuid),
('49ae4c5e-1c1e-4715-b39b-679adc902e8c'::uuid),
('91583827-3368-4425-a899-bae71fba295d'::uuid),
('29284ed9-bf02-49d0-af22-4e45ef36c75a'::uuid),
('ac1c174a-a91d-4a64-b776-c33427196d17'::uuid),
('7a562d25-1973-4950-aa1e-89d42199abd4'::uuid),
('b555ee07-5417-414e-b2c6-38ccc9587de5'::uuid),
('22cc07eb-f721-49bc-8b45-9c424bd32445'::uuid),
('f3bda005-cb6b-4548-9c00-050b1a5911f9'::uuid),
('e9889eb4-fc30-4a02-877e-990e7b8b17ce'::uuid),
('2c8aa6a8-eb30-4c17-984b-6ee80666fab3'::uuid),
('b4440a43-18e6-48ba-9ffc-9b1af83d7272'::uuid),
('e3d44420-41ca-4652-86bf-31965a57a76b'::uuid),
('217f82e0-a04c-4866-a020-e8d090626a2e'::uuid);
CREATE TEMP TABLE p15_input ON COMMIT DROP AS
SELECT x.fbi_match_number,x.local_date,NULLIF(NULLIF(x.local_time,''),'00:00') AS local_time,
 x.opponent_name,x.home_away,x.venue_name,x.source_cells,x.competition_code,x.team_code,x.source_file,x.source_sha256,
 '2026-2027'::text season_scope,'u13-u15-fbi-2026-2027-2026-11-04'::text batch_id,
 x.competition_code||'|'||x.team_code||'|'||x.fbi_match_number AS source_match_key,
 x.local_date::date + NULLIF(NULLIF(x.local_time,''),'00:00')::time AS starts_local,
 '6d55aea920032c3182b65c4fbaedc9ea395122408d5a6f088b12616dd007d753'::text staging_sha256
FROM jsonb_to_recordset($fbi$[
  {
    "fbi_match_number": "1",
    "local_date": "2026-11-07",
    "local_time": "00:00",
    "opponent_name": "AS LE HAILLAN",
    "home_away": "away",
    "venue_name": "Gymnase du Collège",
    "source_cells": "ligne 2",
    "competition_code": "DFU13-3-P2",
    "team_code": "U13F",
    "source_file": "rechercherRencontre (6).xlsx",
    "source_sha256": "a64b1b42edb0e85db63819ec7ab347294c63ee7089489b6fbc9d58de4e021dd5"
  },
  {
    "fbi_match_number": "5",
    "local_date": "2026-11-14",
    "local_time": "00:00",
    "opponent_name": "BORDEAUX ETUDIANTS CLUB",
    "home_away": "home",
    "venue_name": "SALLE PORT DU ROY",
    "source_cells": "ligne 3",
    "competition_code": "DFU13-3-P2",
    "team_code": "U13F",
    "source_file": "rechercherRencontre (6).xlsx",
    "source_sha256": "a64b1b42edb0e85db63819ec7ab347294c63ee7089489b6fbc9d58de4e021dd5"
  },
  {
    "fbi_match_number": "9",
    "local_date": "2026-11-28",
    "local_time": "17:30",
    "opponent_name": "AMICALE BASKETTEURS GRADIGNAN",
    "home_away": "away",
    "venue_name": "SALLE JEHAN BUHAN",
    "source_cells": "ligne 4",
    "competition_code": "DFU13-3-P2",
    "team_code": "U13F",
    "source_file": "rechercherRencontre (6).xlsx",
    "source_sha256": "a64b1b42edb0e85db63819ec7ab347294c63ee7089489b6fbc9d58de4e021dd5"
  },
  {
    "fbi_match_number": "10",
    "local_date": "2026-12-05",
    "local_time": "15:00",
    "opponent_name": "AGJA CAUDERAN",
    "home_away": "away",
    "venue_name": "GYMNASE JULES FERRY",
    "source_cells": "ligne 5",
    "competition_code": "DFU13-3-P2",
    "team_code": "U13F",
    "source_file": "rechercherRencontre (6).xlsx",
    "source_sha256": "a64b1b42edb0e85db63819ec7ab347294c63ee7089489b6fbc9d58de4e021dd5"
  },
  {
    "fbi_match_number": "14",
    "local_date": "2026-12-12",
    "local_time": "00:00",
    "opponent_name": "BOULIAC BASKET CLUB",
    "home_away": "home",
    "venue_name": "SALLE PORT DU ROY",
    "source_cells": "ligne 6",
    "competition_code": "DFU13-3-P2",
    "team_code": "U13F",
    "source_file": "rechercherRencontre (6).xlsx",
    "source_sha256": "a64b1b42edb0e85db63819ec7ab347294c63ee7089489b6fbc9d58de4e021dd5"
  },
  {
    "fbi_match_number": "4",
    "local_date": "2026-11-21",
    "local_time": "00:00",
    "opponent_name": "CASTELNAU MEDOC BC",
    "home_away": "away",
    "venue_name": "GYMNASE CANTERANE",
    "source_cells": "ligne 2",
    "competition_code": "DMU13-4-P2",
    "team_code": "U13M",
    "source_file": "rechercherRencontre (5).xlsx",
    "source_sha256": "0bb085d8e082d8e92b1a8f803b074bef65b4dafe15d79ea6b6b5b599e513dfa4"
  },
  {
    "fbi_match_number": "14",
    "local_date": "2026-11-14",
    "local_time": "00:00",
    "opponent_name": "US LE BOUSCAT - 2",
    "home_away": "home",
    "venue_name": "SALLE PORT DU ROY",
    "source_cells": "ligne 3",
    "competition_code": "DMU13-4-P2",
    "team_code": "U13M",
    "source_file": "rechercherRencontre (5).xlsx",
    "source_sha256": "0bb085d8e082d8e92b1a8f803b074bef65b4dafe15d79ea6b6b5b599e513dfa4"
  },
  {
    "fbi_match_number": "24",
    "local_date": "2026-11-28",
    "local_time": "00:00",
    "opponent_name": "JSA BORDEAUX BASKET - 3",
    "home_away": "away",
    "venue_name": "SALLE DES PEUPLIERS",
    "source_cells": "ligne 4",
    "competition_code": "DMU13-4-P2",
    "team_code": "U13M",
    "source_file": "rechercherRencontre (5).xlsx",
    "source_sha256": "0bb085d8e082d8e92b1a8f803b074bef65b4dafe15d79ea6b6b5b599e513dfa4"
  },
  {
    "fbi_match_number": "31",
    "local_date": "2026-12-05",
    "local_time": "12:00",
    "opponent_name": "SAM LESPARRE BASKET",
    "home_away": "away",
    "venue_name": "COSEC",
    "source_cells": "ligne 5",
    "competition_code": "DMU13-4-P2",
    "team_code": "U13M",
    "source_file": "rechercherRencontre (5).xlsx",
    "source_sha256": "0bb085d8e082d8e92b1a8f803b074bef65b4dafe15d79ea6b6b5b599e513dfa4"
  },
  {
    "fbi_match_number": "41",
    "local_date": "2026-12-12",
    "local_time": "00:00",
    "opponent_name": "SAINT MEDARD BASKET - 4",
    "home_away": "home",
    "venue_name": "SALLE PORT DU ROY",
    "source_cells": "ligne 6",
    "competition_code": "DMU13-4-P2",
    "team_code": "U13M",
    "source_file": "rechercherRencontre (5).xlsx",
    "source_sha256": "0bb085d8e082d8e92b1a8f803b074bef65b4dafe15d79ea6b6b5b599e513dfa4"
  },
  {
    "fbi_match_number": "7",
    "local_date": "2026-11-07",
    "local_time": "17:00",
    "opponent_name": "UNION SPORTIVE GAURIAC",
    "home_away": "away",
    "venue_name": "GYMNASE LOUIS REGNIER",
    "source_cells": "ligne 2",
    "competition_code": "DMU15-3-P2",
    "team_code": "U15M",
    "source_file": "rechercherRencontre (7).xlsx",
    "source_sha256": "b17ba6685c2da432f2c1083615fead9cf8bc5aa33462a6396cef54ab1e611073"
  },
  {
    "fbi_match_number": "17",
    "local_date": "2026-11-14",
    "local_time": "00:00",
    "opponent_name": "BASKET BASSIN D'ARCACHON - 1",
    "home_away": "home",
    "venue_name": "SALLE PORT DU ROY",
    "source_cells": "ligne 3",
    "competition_code": "DMU15-3-P2",
    "team_code": "U15M",
    "source_file": "rechercherRencontre (7).xlsx",
    "source_sha256": "b17ba6685c2da432f2c1083615fead9cf8bc5aa33462a6396cef54ab1e611073"
  },
  {
    "fbi_match_number": "27",
    "local_date": "2026-11-28",
    "local_time": "13:00",
    "opponent_name": "CLUB LEO LAGRANGE LORMONT - 1",
    "home_away": "away",
    "venue_name": "SALLE GEORGES BRASSENS",
    "source_cells": "ligne 4",
    "competition_code": "DMU15-3-P2",
    "team_code": "U15M",
    "source_file": "rechercherRencontre (7).xlsx",
    "source_sha256": "b17ba6685c2da432f2c1083615fead9cf8bc5aa33462a6396cef54ab1e611073"
  },
  {
    "fbi_match_number": "34",
    "local_date": "2026-12-06",
    "local_time": "11:15",
    "opponent_name": "B.IZON",
    "home_away": "away",
    "venue_name": "GYMNASE LES COSTAUDS",
    "source_cells": "ligne 5",
    "competition_code": "DMU15-3-P2",
    "team_code": "U15M",
    "source_file": "rechercherRencontre (7).xlsx",
    "source_sha256": "b17ba6685c2da432f2c1083615fead9cf8bc5aa33462a6396cef54ab1e611073"
  },
  {
    "fbi_match_number": "44",
    "local_date": "2026-12-12",
    "local_time": "00:00",
    "opponent_name": "US LE BOUSCAT - 2",
    "home_away": "home",
    "venue_name": "SALLE PORT DU ROY",
    "source_cells": "ligne 6",
    "competition_code": "DMU15-3-P2",
    "team_code": "U15M",
    "source_file": "rechercherRencontre (7).xlsx",
    "source_sha256": "b17ba6685c2da432f2c1083615fead9cf8bc5aa33462a6396cef54ab1e611073"
  }
]$fbi$::jsonb) AS x(
 fbi_match_number text,local_date text,local_time text,opponent_name text,home_away text,venue_name text,source_cells text,
 competition_code text,team_code text,source_file text,source_sha256 text);
CREATE TEMP TABLE p15_team_map(code text PRIMARY KEY,id uuid NOT NULL,competition_code text NOT NULL) ON COMMIT DROP;
INSERT INTO p15_team_map VALUES
('U13F','a5cc2802-d81c-4719-802a-9f0c7743e13c','DFU13-3-P2'),
('U13M','2d493723-f8ff-4100-b62d-709296eff343','DMU13-4-P2'),
('U15M','e6b598cd-4aea-48ea-b41e-8a0b1f1e18b6','DMU15-3-P2');
ALTER TABLE p15_input ADD COLUMN expected_source jsonb;
UPDATE p15_input SET expected_source=jsonb_build_object(
 'import_source','esbb_u13_u15_fbi','season_scope',season_scope,'source_match_key',source_match_key,
 'batch_id',batch_id,'competition_code',competition_code,'fbi_match_number',fbi_match_number,
 'source_file',source_file,'source_sha256',source_sha256,'source_cells',source_cells,
 'staging_file','RAPPROCHEMENT_FBI_U13_U15_PHASE2.csv','staging_sha256',staging_sha256,
 'local_date',local_date,'time_known',local_time IS NOT NULL,'club_validated_fields','[]'::jsonb,
 'provider_baseline',jsonb_build_object('opponent_name',opponent_name,'home_away',home_away,
 'scheduled_local_ffbb',starts_local,'venue_name_raw',venue_name,'venue_address_raw',NULL,
 'competition_name',competition_code,'local_date',local_date,'time_known',local_time IS NOT NULL),
 'canonical_ffbb_status','unresolved');
CREATE TEMP VIEW p15_rows AS
SELECT m.id,m.team_id,m.source_data,s.source_match_key,
 ((m.source_data-ARRAY['rollback_snapshot','view_before','view_installed'])=s.expected_source
  AND (to_jsonb(m)-'source_data'-'updated_at')=m.source_data->'rollback_snapshot'
  AND t.code=s.team_code AND m.ffbb_match_id IS NULL AND m.ffbb_match_url IS NULL
  AND m.opponent_name=s.opponent_name AND m.home_away=s.home_away
  AND m.scheduled_local_ffbb IS NOT DISTINCT FROM s.starts_local AND m.scheduled_local_override IS NULL
  AND m.scheduled_at_ffbb IS NOT DISTINCT FROM (s.starts_local AT TIME ZONE 'Europe/Paris')
  AND m.scheduled_at IS NOT DISTINCT FROM (s.starts_local AT TIME ZONE 'Europe/Paris')
  AND m.venue_id IS NULL AND m.venue_name_raw=s.venue_name AND m.venue_address_raw IS NULL
  AND m.competition_name=s.competition_code AND m.round_label IS NULL
  AND m.status='scheduled' AND m.published AND NOT m.has_conflict) IS TRUE AS intact
FROM public.matches m JOIN public.teams t ON t.id=m.team_id
JOIN p15_input s ON m.source_data->>'season_scope'=s.season_scope
 AND m.source_data->>'source_match_key'=s.source_match_key
WHERE m.source_data->>'import_source'='esbb_u13_u15_fbi'
 AND m.source_data->>'batch_id'='u13-u15-fbi-2026-2027-2026-11-04';
SELECT s.source_match_key,s.local_date,s.local_time,s.opponent_name,s.home_away,s.venue_name,
 r.id,CASE WHEN r.id IS NULL THEN 'creation_a_valider' WHEN r.intact THEN 'identique' ELSE 'modifie_ne_pas_ecraser' END AS plan
FROM p15_input s LEFT JOIN p15_rows r USING(source_match_key) ORDER BY s.local_date;
DO $operation$
DECLARE opt p15_options%ROWTYPE; old_view text; installed_view text; view_oid oid;
 options text[]; acl aclitem[]; projection text:=''; expression text; col record; idx oid;
BEGIN
 SELECT * INTO STRICT opt FROM p15_options;
 IF opt.action NOT IN ('verify','import','rollback') THEN RAISE EXCEPTION 'Action inconnue'; END IF;
 IF (SELECT array_agg(team_code||':'||fbi_match_number ORDER BY team_code,fbi_match_number) FROM p15_input)
    <> ARRAY['U13F:1','U13F:10','U13F:14','U13F:5','U13F:9','U13M:14','U13M:24','U13M:31','U13M:4','U13M:41','U15M:17','U15M:27','U15M:34','U15M:44','U15M:7'] THEN
   RAISE EXCEPTION 'Numéros FBI inattendus'; END IF;
 IF (SELECT count(*) FROM p15_input)<>15 OR
    (SELECT count(*) FROM p15_input WHERE local_time IS NULL)<>9 OR
    (SELECT count(*) FROM (SELECT season_scope,source_match_key FROM p15_input GROUP BY 1,2) k)<>15 OR
    EXISTS(SELECT 1 FROM p15_input s LEFT JOIN p15_team_map t ON t.code=s.team_code AND t.competition_code=s.competition_code
      WHERE t.code IS NULL OR opponent_name IS NULL OR venue_name IS NULL OR home_away NOT IN ('home','away')
        OR COALESCE(local_time,'12:00') !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$') THEN
   RAISE EXCEPTION 'Lot FBI invalide (15 lignes, 9 horaires inconnus attendus)'; END IF;
 IF EXISTS(SELECT 1 FROM p15_rows WHERE NOT intact) OR (SELECT count(*) FROM p15_rows) NOT IN (0,15) THEN
   RAISE EXCEPTION 'Lot incomplet ou modifié : aucune réparation ni écrasement automatique'; END IF;
 IF EXISTS(SELECT 1 FROM public.matches m JOIN p15_input s
   ON m.source_data->>'season_scope'=s.season_scope AND m.source_data->>'source_match_key'=s.source_match_key
   WHERE NOT EXISTS(SELECT 1 FROM p15_rows r WHERE r.id=m.id AND r.intact)) THEN
   RAISE EXCEPTION 'Provenance déjà utilisée hors lot'; END IF;
 -- Collision de provenance ou correspondance possible : revue humaine, jamais de fusion automatique.
 IF EXISTS(SELECT 1 FROM public.matches m JOIN public.teams t ON t.id=m.team_id
 JOIN p15_input s ON s.team_code=t.code
 WHERE NOT EXISTS(SELECT 1 FROM p15_rows r WHERE r.id=m.id AND r.intact)
 AND (m.source_data->>'source_match_key'=s.source_match_key
   OR (m.source_data->>'fbi_match_number'=s.fbi_match_number AND m.competition_name=s.competition_code)
   OR (COALESCE(m.scheduled_local_override::date,m.scheduled_local_ffbb::date,
          NULLIF(m.source_data->>'local_date','')::date)=s.local_date::date)
   OR (m.competition_name IN(s.competition_code,replace(s.competition_code,'-P2',''))
       AND lower(regexp_replace(m.opponent_name,'[^[:alnum:]]','','g'))=
           lower(regexp_replace(s.opponent_name,'[^[:alnum:]]','','g')) AND m.home_away=s.home_away
       AND (COALESCE(m.scheduled_local_ffbb::date,NULLIF(m.source_data->>'local_date','')::date)>=DATE '2026-11-01'
         OR m.scheduled_local_override::date>=DATE '2026-11-01')))) THEN RAISE EXCEPTION 'Collision possible avec une rencontre existante : rapprochement requis'; END IF;
 IF EXISTS(SELECT 1 FROM p15_team_map r LEFT JOIN public.teams t ON t.id=r.id AND t.code=r.code
    WHERE t.id IS NULL OR t.is_public IS DISTINCT FROM true) THEN
   RAISE EXCEPTION 'Équipe historique absente, privée ou UUID incompatible'; END IF;
 IF (SELECT count(*) FROM public.public_calendar v JOIN p15_protected p ON p.id=v.id)<>62 THEN
   RAISE EXCEPTION 'Les 62 publications protégées ne sont plus toutes présentes'; END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_attribute WHERE attrelid='public.public_calendar'::regclass AND attname='id' AND attnum>0 AND NOT attisdropped) THEN
   RAISE EXCEPTION 'public_calendar doit exposer matches.id'; END IF;
 IF EXISTS(SELECT 1 FROM p15_rows r JOIN p15_protected p ON p.id=r.id) THEN
   RAISE EXCEPTION 'Une rencontre du lot est une publication protégée'; END IF;
 IF opt.action='verify' THEN
   IF (SELECT count(*) FROM p15_rows)=15 AND EXISTS(
     SELECT 1 FROM p15_input s JOIN p15_rows r USING(source_match_key)
     WHERE (SELECT count(*) FROM public.public_calendar v WHERE v.id=r.id AND v.team_code=s.team_code
       AND v.local_date::date=s.local_date::date AND NULLIF(v.local_time::time,'00:00'::time) IS NOT DISTINCT FROM s.local_time::time
       AND v.venue_name=s.venue_name AND v.opponent_name=s.opponent_name
       AND v.competition_label=s.competition_code)<>1) THEN
     RAISE EXCEPTION 'Vérification : publications U13/U15 non conformes'; END IF;
   RETURN;
 END IF;
 IF opt.approved IS DISTINCT FROM true THEN RAISE EXCEPTION 'Autorisation humaine requise'; END IF;
 PERFORM pg_advisory_xact_lock(202627,1118);
 LOCK TABLE public.matches,public.teams IN SHARE ROW EXCLUSIVE MODE;
 -- Relire les contrôles sensibles sous verrou : les vues temporaires relisent les tables actuelles.
 IF EXISTS(SELECT 1 FROM p15_rows WHERE NOT intact) OR (SELECT count(*) FROM p15_rows) NOT IN (0,15)
 OR EXISTS(SELECT 1 FROM public.matches m JOIN public.teams t ON t.id=m.team_id
 JOIN p15_input s ON s.team_code=t.code
 WHERE NOT EXISTS(SELECT 1 FROM p15_rows r WHERE r.id=m.id AND r.intact)
 AND (m.source_data->>'source_match_key'=s.source_match_key
   OR (m.source_data->>'fbi_match_number'=s.fbi_match_number AND m.competition_name=s.competition_code)
   OR (COALESCE(m.scheduled_local_override::date,m.scheduled_local_ffbb::date,
          NULLIF(m.source_data->>'local_date','')::date)=s.local_date::date)
   OR (m.competition_name IN(s.competition_code,replace(s.competition_code,'-P2',''))
       AND lower(regexp_replace(m.opponent_name,'[^[:alnum:]]','','g'))=
           lower(regexp_replace(s.opponent_name,'[^[:alnum:]]','','g')) AND m.home_away=s.home_away
       AND (COALESCE(m.scheduled_local_ffbb::date,NULLIF(m.source_data->>'local_date','')::date)>=DATE '2026-11-01'
         OR m.scheduled_local_override::date>=DATE '2026-11-01')))) THEN RAISE EXCEPTION 'État périmé ou collision sous verrou'; END IF;
 IF EXISTS(SELECT 1 FROM p15_team_map r LEFT JOIN public.teams t ON t.id=r.id AND t.code=r.code
    WHERE t.id IS NULL OR t.is_public IS DISTINCT FROM true) THEN
   RAISE EXCEPTION 'Équipe historique devenue incompatible'; END IF;
 IF (SELECT count(*) FROM public.public_calendar v JOIN p15_protected p ON p.id=v.id)<>62 THEN
   RAISE EXCEPTION 'Les 62 publications ont changé sous verrou'; END IF;
 IF EXISTS(SELECT 1 FROM public.matches m JOIN p15_input s
   ON m.source_data->>'season_scope'=s.season_scope AND m.source_data->>'source_match_key'=s.source_match_key
   WHERE NOT EXISTS(SELECT 1 FROM p15_rows r WHERE r.id=m.id AND r.intact)) THEN
   RAISE EXCEPTION 'Provenance devenue incompatible sous verrou'; END IF;
 CREATE TEMP TABLE p15_before_matches ON COMMIT DROP AS
 SELECT id,to_jsonb(m) row_data FROM public.matches m WHERE NOT EXISTS(SELECT 1 FROM p15_rows r WHERE r.id=m.id);
 CREATE TEMP TABLE p15_before_teams ON COMMIT DROP AS SELECT id,to_jsonb(t) row_data FROM public.teams t;
 CREATE TEMP TABLE p15_before_public ON COMMIT DROP AS
 SELECT id,to_jsonb(v) row_data FROM public.public_calendar v WHERE NOT EXISTS(SELECT 1 FROM p15_rows r WHERE r.id=v.id);
 -- Aucun parent ne sera créé ou supprimé.
 view_oid:='public.public_calendar'::regclass;
 SELECT pg_get_viewdef(view_oid,true),reloptions,relacl INTO old_view,options,acl FROM pg_class WHERE oid=view_oid;
 IF opt.action='import' THEN
   CREATE UNIQUE INDEX IF NOT EXISTS esbb_u13_u15_fbi_source_uidx ON public.matches
    ((source_data->>'season_scope'),(source_data->>'source_match_key')) WHERE source_data->>'import_source'='esbb_u13_u15_fbi';
   CREATE TEMP TABLE p15_index_reference(source_data jsonb) ON COMMIT DROP;
   CREATE UNIQUE INDEX p15_expected_index ON p15_index_reference
    ((source_data->>'season_scope'),(source_data->>'source_match_key')) WHERE source_data->>'import_source'='esbb_u13_u15_fbi';
   idx:=to_regclass('public.esbb_u13_u15_fbi_source_uidx');
   IF NOT EXISTS(SELECT 1 FROM pg_index i WHERE indexrelid=idx AND indrelid='public.matches'::regclass
    AND indisunique AND indisvalid AND indnkeyatts=2 AND indnatts=2
    AND pg_get_expr(indpred,indrelid)=(SELECT pg_get_expr(indpred,indrelid) FROM pg_index WHERE indexrelid='p15_expected_index'::regclass)
    AND pg_get_indexdef(idx,1,true)=pg_get_indexdef('p15_expected_index'::regclass,1,true)
    AND pg_get_indexdef(idx,2,true)=pg_get_indexdef('p15_expected_index'::regclass,2,true)) THEN
    RAISE EXCEPTION 'Index de provenance incompatible'; END IF;
   IF (SELECT count(*) FROM p15_rows)=0 THEN
     -- Les trois parents sont réutilisés intégralement, sans INSERT ou UPDATE de teams.
     INSERT INTO public.matches(team_id,ffbb_match_id,ffbb_match_url,opponent_name,home_away,
       scheduled_at,scheduled_at_ffbb,scheduled_local_ffbb,scheduled_local_override,venue_id,venue_name_raw,venue_address_raw,
       competition_name,round_label,status,published,has_conflict,source_data)
     SELECT t.id,NULL,NULL,s.opponent_name,s.home_away,s.starts_local AT TIME ZONE 'Europe/Paris',
       s.starts_local AT TIME ZONE 'Europe/Paris',s.starts_local,NULL,NULL,s.venue_name,NULL,
       s.competition_code,NULL,'scheduled',true,false,
       s.expected_source
     FROM p15_input s JOIN public.teams t ON t.code=s.team_code;
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
         -- Aucun lien de fiche canonique ni score : les colonnes supplémentaires sont NULL pour U13/U15.
         ELSE 'NULL' END;
       projection:=projection||CASE WHEN projection='' THEN '' ELSE ',' END||format('(%s)::%s AS %I',expression,col.typ,col.attname);
     END LOOP;
     EXECUTE format($view$CREATE OR REPLACE VIEW public.public_calendar %s AS
       SELECT legacy.* FROM (%s) legacy WHERE NOT EXISTS(SELECT 1 FROM public.matches m
         WHERE m.id=legacy.id AND m.source_data->>'import_source'='esbb_u13_u15_fbi')
       UNION ALL SELECT %s FROM public.matches m JOIN public.teams t ON t.id=m.team_id
         WHERE m.source_data->>'import_source'='esbb_u13_u15_fbi' AND m.published AND NOT m.has_conflict AND t.is_public$view$,
       CASE WHEN options IS NULL THEN '' ELSE 'WITH ('||array_to_string(options,',')||')' END,
       regexp_replace(old_view,';[[:space:]]*$',''),projection);
     installed_view:=pg_get_viewdef(view_oid,true);
     UPDATE public.matches m SET source_data=source_data||jsonb_build_object(
       'rollback_snapshot',to_jsonb(m)-'source_data'-'updated_at','view_before',old_view,'view_installed',installed_view)
       WHERE m.id IN(SELECT id FROM p15_rows);
   ELSE
     IF EXISTS(SELECT 1 FROM p15_rows WHERE source_data->>'view_installed' IS DISTINCT FROM old_view) THEN
       RAISE EXCEPTION 'Vue changée depuis import : aucune réécriture automatique'; END IF;
   END IF;
   IF (SELECT count(*) FROM p15_rows WHERE intact)<>15 THEN RAISE EXCEPTION 'Lot final non conforme'; END IF;
   IF EXISTS(SELECT 1 FROM p15_input s JOIN p15_rows r USING(source_match_key)
    WHERE (SELECT count(*) FROM public.public_calendar v WHERE v.id=r.id AND v.team_code=s.team_code
     AND v.local_date::date=s.local_date::date AND NULLIF(v.local_time::time,'00:00'::time) IS NOT DISTINCT FROM s.local_time::time
     AND v.opponent_name=s.opponent_name AND v.home_away=s.home_away AND v.venue_name=s.venue_name
     AND v.competition_label=s.competition_code)<>1) THEN RAISE EXCEPTION 'Publication U13/U15 non conforme'; END IF;
 ELSE
   IF (SELECT count(*) FROM p15_rows WHERE intact)<>15 THEN RAISE EXCEPTION 'Retour refusé : lot absent ou modifié'; END IF;
   IF (SELECT count(*) FROM public.matches WHERE source_data->>'import_source'='esbb_u13_u15_fbi'
       AND source_data->>'batch_id'='u13-u15-fbi-2026-2027-2026-11-04')<>15 THEN RAISE EXCEPTION 'Portée du lot inattendue'; END IF;
   SELECT source_data->>'view_before',source_data->>'view_installed' INTO old_view,installed_view FROM p15_rows LIMIT 1;
   IF old_view IS NULL OR pg_get_viewdef(view_oid,true) IS DISTINCT FROM installed_view OR
     EXISTS(SELECT 1 FROM p15_rows WHERE source_data->>'view_before' IS DISTINCT FROM old_view
       OR source_data->>'view_installed' IS DISTINCT FROM installed_view) THEN RAISE EXCEPTION 'Vue changée : retour refusé'; END IF;
   DELETE FROM public.matches m WHERE m.id IN(SELECT id FROM p15_rows);
   IF EXISTS(SELECT 1 FROM public.matches WHERE source_data->>'import_source'='esbb_u13_u15_fbi') THEN
     RAISE EXCEPTION 'Autre lot dépendant de la vue : retour à examiner'; END IF;
   EXECUTE format('CREATE OR REPLACE VIEW public.public_calendar %s AS %s',
     CASE WHEN options IS NULL THEN '' ELSE 'WITH ('||array_to_string(options,',')||')' END,old_view);
 END IF;
 IF EXISTS(SELECT 1 FROM p15_before_matches b LEFT JOIN public.matches m ON m.id=b.id
    WHERE m.id IS NULL OR to_jsonb(m) IS DISTINCT FROM b.row_data)
 OR EXISTS(SELECT 1 FROM p15_before_public b LEFT JOIN public.public_calendar v ON v.id=b.id
    WHERE v.id IS NULL OR to_jsonb(v) IS DISTINCT FROM b.row_data) THEN RAISE EXCEPTION 'Rencontre hors lot modifiée'; END IF;
 IF EXISTS(SELECT 1 FROM p15_before_teams b LEFT JOIN public.teams t ON t.id=b.id
    WHERE (t.id IS NULL OR to_jsonb(t) IS DISTINCT FROM b.row_data)
) THEN
    RAISE EXCEPTION 'Équipe préexistante modifiée'; END IF;
 IF (SELECT count(*) FROM public.matches)<>(SELECT count(*) FROM p15_before_matches)+(CASE WHEN opt.action='import' THEN 15 ELSE 0 END) THEN
    RAISE EXCEPTION 'Nombre final inattendu'; END IF;
 IF 'public.public_calendar'::regclass::oid<>view_oid OR EXISTS(SELECT 1 FROM pg_class WHERE oid=view_oid
    AND (reloptions IS DISTINCT FROM options OR relacl IS DISTINCT FROM acl)) THEN RAISE EXCEPTION 'Droits/options de vue modifiés'; END IF;
END
$operation$;
SELECT o.action,(SELECT count(*) FROM public.public_calendar) AS publications,
 (SELECT count(*) FROM p15_rows) AS rencontres_du_lot,(SELECT count(*) FROM p15_rows WHERE intact) AS identiques
FROM p15_options o;
SELECT id,source_match_key,md5((source_data)::text) AS provenance_md5 FROM p15_rows;
COMMIT;
