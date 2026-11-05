-- Future interface PRIVÉE d'import FBI : protocole SQL préparé, aucune interface publiée.
-- Ne pas installer de RPC publique, ne pas utiliser la clé anonyme pour ce traitement.
-- Dans la future interface, transmettre le JSON par paramètres SQL liés ;
-- ne jamais concaténer le contenu du CSV dans une requête SQL.
-- L'Edge Function ffbb-sync et le cron restent inchangés ; support FBI non confirmé.
-- Deux passages : preview produit current_record + champs modifiés/protégés ;
-- apply exige la confirmation ET le current_record exact revu pour chaque ligne.
-- Les corrections scheduled_local_override ne sont JAMAIS modifiées.
-- Les corrections directes ou club_validated_fields exigent approved_fields explicites.
-- Clé stable : origine + saison + source_match_key, jamais date/heure/salle.
-- Pas de création/suppression de rencontre dans ce script d'actualisation.
-- Un export absent ne supprime rien. Un horaire retiré redevient NULL, date conservée.
-- Après une actualisation, le rollback de l'import INITIAL refuse les données modifiées.
-- Les valeurs précédentes et l'export reçu sont historisés dans source_data.import_history.
BEGIN;
SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='60s';
CREATE TEMP TABLE mb_refresh_options(action text,sync_reviewed boolean) ON COMMIT DROP;
INSERT INTO mb_refresh_options VALUES ('preview',false);
CREATE TEMP TABLE mb_refresh_input ON COMMIT DROP AS
SELECT * FROM jsonb_to_recordset($refresh_input$[]$refresh_input$::jsonb) AS x(
  season_scope text, source_match_key text, export_row jsonb,
  expected_current jsonb, approved_fields jsonb, confirmed boolean);
-- export_row : ligne du nouvel export normalisée selon les colonnes du staging initial.
-- expected_current : copie exacte de current_record renvoyé par preview (sans updated_at).
-- approved_fields : tableau de noms de champs protégés explicitement approuvés, sinon [].
-- confirmed : true uniquement après contrôle humain du rapprochement et des changements.

DO $guard$
DECLARE action_name text;
BEGIN
  SELECT action INTO STRICT action_name FROM mb_refresh_options;
  IF action_name NOT IN ('preview','apply') THEN RAISE EXCEPTION 'Action inconnue'; END IF;
  IF action_name='apply' THEN
    IF NOT (SELECT sync_reviewed FROM mb_refresh_options) THEN
      RAISE EXCEPTION 'Confirmer que ffbb-sync préserve les lignes manuelles ; couverture FBI non requise';
    END IF;
    SET CONSTRAINTS ALL IMMEDIATE;
    PERFORM pg_advisory_xact_lock(202627,1103);
    LOCK TABLE public.teams,public.matches IN SHARE ROW EXCLUSIVE MODE;
  END IF;
  IF EXISTS (SELECT 1 FROM mb_refresh_input GROUP BY season_scope,source_match_key HAVING count(*)>1)
    OR EXISTS (SELECT 1 FROM mb_refresh_input WHERE NULLIF(season_scope,'') IS NULL
      OR NULLIF(source_match_key,'') IS NULL OR jsonb_typeof(export_row) IS DISTINCT FROM 'object'
      OR (approved_fields IS NOT NULL AND jsonb_typeof(approved_fields)<>'array')
      OR export_row->>'source_match_key' IS DISTINCT FROM source_match_key
      OR export_row->>'source_match_key' IS DISTINCT FROM concat_ws('|',export_row->>'competition_code',export_row->>'team_code_proposed',export_row->>'match_number')
      OR COALESCE(export_row->>'local_date','') !~ '^\d{4}-\d{2}-\d{2}$'
      OR COALESCE(export_row->>'opponent_name','')='' OR export_row->>'opponent_name' ILIKE '%exempt%'
      OR COALESCE(export_row->>'home_away','') NOT IN ('home','away','neutral')
    ) THEN RAISE EXCEPTION 'Entrée invalide, doublon ou changement d’identité'; END IF;
END
$guard$;

CREATE TEMP TABLE mb_refresh_plan ON COMMIT DROP AS
WITH candidates AS (
 SELECT i.*,m.id,m.team_id,t.code,to_jsonb(m)-'updated_at' AS current_record,m.source_data,
  jsonb_build_object('opponent_name',m.opponent_name,'scheduled_local_ffbb',m.scheduled_local_ffbb,
    'venue_name_raw',m.venue_name_raw,'venue_address_raw',m.venue_address_raw,
    'home_away',m.home_away,'competition_name',m.competition_name,'round_label',m.round_label,
    'local_date',m.source_data->>'local_date','time_known',m.source_data->'time_known') AS current_values,
  jsonb_build_object('opponent_name',i.export_row->>'opponent_name',
    'scheduled_local_ffbb',CASE WHEN NULLIF(NULLIF(i.export_row->>'local_time','')::time,'00:00'::time) IS NULL THEN NULL
      ELSE (i.export_row->>'local_date')::date+(i.export_row->>'local_time')::time END,
    'venue_name_raw',NULLIF(i.export_row->>'venue_name',''),
    'venue_address_raw',NULLIF(i.export_row->>'venue_address',''),
    'home_away',i.export_row->>'home_away','competition_name',i.export_row->>'competition_code',
    'round_label',NULLIF(i.export_row->>'round_label',''),
    'local_date',i.export_row->>'local_date',
    'time_known',NULLIF(NULLIF(i.export_row->>'local_time','')::time,'00:00'::time) IS NOT NULL) AS proposed_values,
  (SELECT count(*) FROM public.matches x WHERE x.source_data->>'import_source'='esbb_minibasket'
    AND x.source_data->>'season_scope'=i.season_scope AND x.source_data->>'source_match_key'=i.source_match_key) AS targets
 FROM mb_refresh_input i LEFT JOIN public.matches m
 ON m.source_data->>'import_source'='esbb_minibasket'
 AND m.source_data->>'season_scope'=i.season_scope AND m.source_data->>'source_match_key'=i.source_match_key
 LEFT JOIN public.teams t ON t.id=m.team_id
), diffs AS (
 SELECT c.*,
   COALESCE((SELECT jsonb_agg(k ORDER BY k) FROM jsonb_object_keys(proposed_values) k
     WHERE proposed_values->k IS DISTINCT FROM current_values->k),'[]'::jsonb) AS changed_fields,
   COALESCE((SELECT jsonb_agg(k ORDER BY k) FROM jsonb_object_keys(proposed_values) k
     WHERE proposed_values->k IS DISTINCT FROM current_values->k
     AND (COALESCE(source_data->'club_validated_fields','[]'::jsonb) ? k
       OR current_values->k IS DISTINCT FROM source_data->'provider_baseline'->k)), '[]'::jsonb) AS protected_fields
 FROM candidates c
)
SELECT d.*,
 CASE WHEN targets<>1 OR id IS NULL THEN 'cible_absente_ou_ambigue'
   WHEN code IS DISTINCT FROM export_row->>'team_code_proposed' THEN 'equipe_incompatible'
   WHEN jsonb_typeof(source_data->'provider_baseline') IS DISTINCT FROM 'object' THEN 'reference_import_absente'
   WHEN EXISTS (SELECT 1 FROM jsonb_array_elements_text(protected_fields) f
     WHERE NOT COALESCE(approved_fields,'[]'::jsonb) ? f) THEN 'correction_club_a_valider'
   WHEN changed_fields='[]'::jsonb THEN 'inchange'
   WHEN NOT COALESCE(confirmed,false) OR expected_current IS NULL THEN 'validation_requise'
   WHEN expected_current IS DISTINCT FROM current_record THEN 'donnees_modifiees_depuis_revue'
   ELSE 'mise_a_jour' END AS result
FROM diffs d;

-- Preview pour l'interface privée : ne pas exposer ces données sur le site public.
SELECT season_scope,source_match_key,code,result,changed_fields,protected_fields,
       current_values,proposed_values,current_record
FROM mb_refresh_plan ORDER BY season_scope,source_match_key;

DO $apply$
BEGIN
  IF (SELECT action FROM mb_refresh_options)<>'apply' THEN RETURN; END IF;
  IF NOT EXISTS (SELECT 1 FROM mb_refresh_input) THEN RAISE EXCEPTION 'Lot vide'; END IF;
  IF EXISTS (SELECT 1 FROM mb_refresh_plan WHERE result NOT IN ('mise_a_jour','inchange')) THEN
    RAISE EXCEPTION 'Actualisation bloquée : examiner le plan, aucun changement conservé';
  END IF;
  CREATE TEMP TABLE mb_refresh_before ON COMMIT DROP AS SELECT id,to_jsonb(m) row_data FROM public.matches m;
  CREATE TEMP TABLE mb_refresh_teams_before ON COMMIT DROP AS SELECT id,to_jsonb(t) row_data FROM public.teams t;
  CREATE TEMP TABLE mb_refresh_public_before ON COMMIT DROP AS
    SELECT to_jsonb(v) row_data FROM public.public_calendar v
    WHERE team_code NOT IN (SELECT code FROM mb_refresh_plan WHERE result='mise_a_jour');
  UPDATE public.matches m SET
    opponent_name=p.proposed_values->>'opponent_name',
    scheduled_local_ffbb=(p.proposed_values->>'scheduled_local_ffbb')::timestamp,
    venue_name_raw=p.proposed_values->>'venue_name_raw',venue_address_raw=p.proposed_values->>'venue_address_raw',
    home_away=p.proposed_values->>'home_away',competition_name=p.proposed_values->>'competition_name',
    round_label=p.proposed_values->>'round_label',
    source_data=m.source_data || jsonb_build_object(
      'local_date',p.proposed_values->>'local_date','time_known',p.proposed_values->'time_known',
      'provider_baseline',p.proposed_values,'latest_export_row',p.export_row,
      'import_history',COALESCE(m.source_data->'import_history','[]'::jsonb) || jsonb_build_array(jsonb_build_object(
        'at',transaction_timestamp(),'previous_values',p.current_values,'received_export_row',p.export_row,
        'approved_fields',COALESCE(p.approved_fields,'[]'::jsonb))))
  FROM mb_refresh_plan p WHERE m.id=p.id AND p.result='mise_a_jour'
    AND to_jsonb(m)-'updated_at'=p.expected_current;

  IF EXISTS (SELECT 1 FROM mb_refresh_plan p WHERE NOT EXISTS (SELECT 1 FROM public.matches m WHERE m.id=p.id)) THEN
    RAISE EXCEPTION 'Une rencontre ciblée a disparu'; END IF;
  IF EXISTS (SELECT 1 FROM mb_refresh_plan p JOIN public.matches m ON m.id=p.id
    WHERE p.result='mise_a_jour' AND (
      m.scheduled_local_override IS DISTINCT FROM (p.current_record->>'scheduled_local_override')::timestamp
      OR m.opponent_name IS DISTINCT FROM p.proposed_values->>'opponent_name'
      OR m.scheduled_local_ffbb IS DISTINCT FROM (p.proposed_values->>'scheduled_local_ffbb')::timestamp
      OR m.venue_name_raw IS DISTINCT FROM p.proposed_values->>'venue_name_raw'
      OR m.venue_address_raw IS DISTINCT FROM p.proposed_values->>'venue_address_raw'
      OR m.home_away IS DISTINCT FROM p.proposed_values->>'home_away'
      OR m.competition_name IS DISTINCT FROM p.proposed_values->>'competition_name'
      OR m.round_label IS DISTINCT FROM p.proposed_values->>'round_label'
      OR m.source_data->'provider_baseline' IS DISTINCT FROM p.proposed_values
      OR (m.source_data-ARRAY['local_date','time_known','provider_baseline','latest_export_row','import_history'])
         IS DISTINCT FROM (p.source_data-ARRAY['local_date','time_known','provider_baseline','latest_export_row','import_history'])
      OR (to_jsonb(m)-ARRAY['opponent_name','scheduled_local_ffbb','venue_name_raw','venue_address_raw','home_away',
          'competition_name','round_label','source_data','updated_at']) IS DISTINCT FROM
         (p.current_record-ARRAY['opponent_name','scheduled_local_ffbb','venue_name_raw','venue_address_raw','home_away',
          'competition_name','round_label','source_data','updated_at'])
    )) THEN RAISE EXCEPTION 'Résultat différent du plan ou correction club altérée'; END IF;
  IF EXISTS (SELECT 1 FROM mb_refresh_plan p WHERE p.result='mise_a_jour' AND
      (SELECT count(*) FROM public.public_calendar v
       WHERE v.id=p.id AND v.team_code=p.code AND v.opponent_name=p.proposed_values->>'opponent_name'
         AND v.local_date::date=COALESCE((p.current_record->>'scheduled_local_override')::timestamp::date,
            (p.proposed_values->>'local_date')::date)
         AND NULLIF(v.local_time::text,'')::time IS NOT DISTINCT FROM
           CASE WHEN (p.current_record->>'scheduled_local_override')::timestamp IS NOT NULL
             THEN NULLIF((p.current_record->>'scheduled_local_override')::timestamp::time,'00:00'::time)
             ELSE NULLIF((p.proposed_values->>'scheduled_local_ffbb')::timestamp::time,'00:00'::time) END)<>1
    ) THEN RAISE EXCEPTION 'Date ou heure absente/non conforme dans public_calendar'; END IF;
  IF (SELECT count(*) FROM public.matches)<>(SELECT count(*) FROM mb_refresh_before)
    OR EXISTS (SELECT 1 FROM mb_refresh_before b LEFT JOIN public.matches m ON m.id=b.id
      WHERE NOT EXISTS (SELECT 1 FROM mb_refresh_plan p WHERE p.id=b.id AND p.result='mise_a_jour')
      AND (m.id IS NULL OR to_jsonb(m) IS DISTINCT FROM b.row_data)) THEN
    RAISE EXCEPTION 'Une rencontre hors actualisation a changé';
  END IF;
  IF EXISTS ((SELECT row_data FROM mb_refresh_teams_before EXCEPT ALL SELECT to_jsonb(t) FROM public.teams t)
    UNION ALL (SELECT to_jsonb(t) FROM public.teams t EXCEPT ALL SELECT row_data FROM mb_refresh_teams_before)) THEN
    RAISE EXCEPTION 'Une équipe a changé'; END IF;
  IF EXISTS (
    (SELECT row_data FROM mb_refresh_public_before EXCEPT ALL SELECT to_jsonb(v) FROM public.public_calendar v
      WHERE team_code NOT IN (SELECT code FROM mb_refresh_plan WHERE result='mise_a_jour'))
    UNION ALL
    (SELECT to_jsonb(v) FROM public.public_calendar v
      WHERE team_code NOT IN (SELECT code FROM mb_refresh_plan WHERE result='mise_a_jour')
      EXCEPT ALL SELECT row_data FROM mb_refresh_public_before)
  ) THEN RAISE EXCEPTION 'Une publication hors équipe actualisée a changé'; END IF;
END
$apply$;
COMMIT;
