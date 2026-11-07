-- PROPOSITION NON EXÉCUTÉE : 3 expression(s) salle corrigée(s).
BEGIN;
LOCK TABLE public.public_calendar IN ACCESS EXCLUSIVE MODE;
DO $guard$ BEGIN
 IF (SELECT COALESCE(reloptions,ARRAY[]::text[]) FROM pg_class WHERE oid='public.public_calendar'::regclass) <> ARRAY['security_invoker=true']::text[] THEN RAISE EXCEPTION 'Options de sécurité modifiées depuis le snapshot'; END IF;
 IF pg_get_viewdef('public.public_calendar'::regclass,true) <> ' SELECT legacy.id,
    legacy.team_code,
    legacy.team_name,
    legacy.competition_label,
    legacy.opponent_name,
    legacy.home_away,
    legacy.starts_local,
    legacy.local_date,
    legacy.local_time,
    legacy.venue_name,
    legacy.venue_address,
    legacy.round_label,
    legacy.status,
    legacy.ffbb_team_url,
    legacy.ffbb_match_url,
    legacy.updated_at
   FROM ( SELECT legacy_1.id,
            legacy_1.team_code,
            legacy_1.team_name,
            legacy_1.competition_label,
            legacy_1.opponent_name,
            legacy_1.home_away,
            legacy_1.starts_local,
            legacy_1.local_date,
            legacy_1.local_time,
            legacy_1.venue_name,
            legacy_1.venue_address,
            legacy_1.round_label,
            legacy_1.status,
            legacy_1.ffbb_team_url,
            legacy_1.ffbb_match_url,
            legacy_1.updated_at
           FROM ( SELECT legacy_1_1.id,
                    legacy_1_1.team_code,
                    legacy_1_1.team_name,
                    legacy_1_1.competition_label,
                    legacy_1_1.opponent_name,
                    legacy_1_1.home_away,
                    legacy_1_1.starts_local,
                    legacy_1_1.local_date,
                    legacy_1_1.local_time,
                    legacy_1_1.venue_name,
                    legacy_1_1.venue_address,
                    legacy_1_1.round_label,
                    legacy_1_1.status,
                    legacy_1_1.ffbb_team_url,
                    legacy_1_1.ffbb_match_url,
                    legacy_1_1.updated_at
                   FROM ( SELECT m.id,
                            t.code AS team_code,
                            t.name AS team_name,
                            t.competition_label,
                            m.opponent_name,
                            m.home_away,
                            COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb) AS starts_local,
                            to_char(COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb), ''YYYY-MM-DD''::text) AS local_date,
                            to_char(COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb), ''HH24:MI''::text) AS local_time,
                            COALESCE(m.venue_name_override, m.venue_name_raw) AS venue_name,
                            m.venue_address_raw AS venue_address,
                            m.round_label,
                            m.status,
                            t.ffbb_team_url,
                            m.ffbb_match_url,
                            m.updated_at
                           FROM matches m
                             JOIN teams t ON t.id = m.team_id
                          WHERE m.published = true AND m.has_conflict = false) legacy_1_1
                  WHERE NOT (EXISTS ( SELECT 1
                           FROM matches m
                          WHERE m.id = legacy_1_1.id AND (m.source_data ->> ''import_source''::text) = ''esbb_minibasket''::text))
                UNION ALL
                 SELECT m.id,
                    t.code AS team_code,
                    t.name AS team_name,
                    t.competition_label,
                    m.opponent_name,
                    m.home_away,
                    COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb) AS starts_local,
                    COALESCE(m.scheduled_local_override::date, NULLIF(m.source_data ->> ''local_date''::text, ''''::text)::date, m.scheduled_local_ffbb::date)::text AS local_date,
                        CASE
                            WHEN m.scheduled_local_override IS NOT NULL THEN NULLIF(m.scheduled_local_override::time without time zone, ''00:00:00''::time without time zone)
                            WHEN (m.source_data ->> ''time_known''::text) = ''true''::text THEN NULLIF(m.scheduled_local_ffbb::time without time zone, ''00:00:00''::time without time zone)
                            ELSE NULL::time without time zone
                        END::text AS local_time,
                    m.venue_name_raw AS venue_name,
                    m.venue_address_raw AS venue_address,
                    m.round_label,
                    m.status,
                    NULL::text AS ffbb_team_url,
                    NULL::text AS ffbb_match_url,
                    m.updated_at
                   FROM matches m
                     JOIN teams t ON t.id = m.team_id
                  WHERE (m.source_data ->> ''import_source''::text) = ''esbb_minibasket''::text AND m.published = true AND m.has_conflict = false AND t.is_public = true) legacy_1
          WHERE NOT (EXISTS ( SELECT 1
                   FROM matches m
                  WHERE m.id = legacy_1.id AND (m.source_data ->> ''import_source''::text) = ''esbb_u18m_fbi''::text))
        UNION ALL
         SELECT m.id,
            t.code AS team_code,
            t.name AS team_name,
            m.competition_name AS competition_label,
            m.opponent_name,
            m.home_away,
            COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb) AS starts_local,
            COALESCE(m.scheduled_local_override::date, m.scheduled_local_ffbb::date, NULLIF(m.source_data ->> ''local_date''::text, ''''::text)::date)::text AS local_date,
            NULLIF(COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb)::time without time zone, ''00:00:00''::time without time zone)::text AS local_time,
            m.venue_name_raw AS venue_name,
            m.venue_address_raw AS venue_address,
            m.round_label,
            m.status,
            NULL::text AS ffbb_team_url,
            m.ffbb_match_url,
            m.updated_at
           FROM matches m
             JOIN teams t ON t.id = m.team_id
          WHERE (m.source_data ->> ''import_source''::text) = ''esbb_u18m_fbi''::text AND m.published AND NOT m.has_conflict AND t.is_public) legacy
  WHERE NOT (EXISTS ( SELECT 1
           FROM matches m
          WHERE m.id = legacy.id AND (m.source_data ->> ''import_source''::text) = ''esbb_u13_u15_fbi''::text))
UNION ALL
 SELECT m.id,
    t.code AS team_code,
    t.name AS team_name,
    m.competition_name AS competition_label,
    m.opponent_name,
    m.home_away,
    COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb) AS starts_local,
    COALESCE(m.scheduled_local_override::date, m.scheduled_local_ffbb::date, NULLIF(m.source_data ->> ''local_date''::text, ''''::text)::date)::text AS local_date,
    NULLIF(COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb)::time without time zone, ''00:00:00''::time without time zone)::text AS local_time,
    m.venue_name_raw AS venue_name,
    m.venue_address_raw AS venue_address,
    m.round_label,
    m.status,
    NULL::text AS ffbb_team_url,
    m.ffbb_match_url,
    m.updated_at
   FROM matches m
     JOIN teams t ON t.id = m.team_id
  WHERE (m.source_data ->> ''import_source''::text) = ''esbb_u13_u15_fbi''::text AND m.published AND NOT m.has_conflict AND t.is_public;' THEN
  RAISE EXCEPTION 'La vue a changé : régénérer le patch depuis sa définition actuelle';
 END IF;
END $guard$;
CREATE TABLE IF NOT EXISTS site_m01.view_backup (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 saved_at timestamptz NOT NULL DEFAULT clock_timestamp(), definition text NOT NULL,
 view_options text[]
);
ALTER TABLE site_m01.view_backup ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON site_m01.view_backup FROM PUBLIC,anon,authenticated;
INSERT INTO site_m01.view_backup(definition,view_options)
 SELECT ' SELECT legacy.id,
    legacy.team_code,
    legacy.team_name,
    legacy.competition_label,
    legacy.opponent_name,
    legacy.home_away,
    legacy.starts_local,
    legacy.local_date,
    legacy.local_time,
    legacy.venue_name,
    legacy.venue_address,
    legacy.round_label,
    legacy.status,
    legacy.ffbb_team_url,
    legacy.ffbb_match_url,
    legacy.updated_at
   FROM ( SELECT legacy_1.id,
            legacy_1.team_code,
            legacy_1.team_name,
            legacy_1.competition_label,
            legacy_1.opponent_name,
            legacy_1.home_away,
            legacy_1.starts_local,
            legacy_1.local_date,
            legacy_1.local_time,
            legacy_1.venue_name,
            legacy_1.venue_address,
            legacy_1.round_label,
            legacy_1.status,
            legacy_1.ffbb_team_url,
            legacy_1.ffbb_match_url,
            legacy_1.updated_at
           FROM ( SELECT legacy_1_1.id,
                    legacy_1_1.team_code,
                    legacy_1_1.team_name,
                    legacy_1_1.competition_label,
                    legacy_1_1.opponent_name,
                    legacy_1_1.home_away,
                    legacy_1_1.starts_local,
                    legacy_1_1.local_date,
                    legacy_1_1.local_time,
                    legacy_1_1.venue_name,
                    legacy_1_1.venue_address,
                    legacy_1_1.round_label,
                    legacy_1_1.status,
                    legacy_1_1.ffbb_team_url,
                    legacy_1_1.ffbb_match_url,
                    legacy_1_1.updated_at
                   FROM ( SELECT m.id,
                            t.code AS team_code,
                            t.name AS team_name,
                            t.competition_label,
                            m.opponent_name,
                            m.home_away,
                            COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb) AS starts_local,
                            to_char(COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb), ''YYYY-MM-DD''::text) AS local_date,
                            to_char(COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb), ''HH24:MI''::text) AS local_time,
                            COALESCE(m.venue_name_override, m.venue_name_raw) AS venue_name,
                            m.venue_address_raw AS venue_address,
                            m.round_label,
                            m.status,
                            t.ffbb_team_url,
                            m.ffbb_match_url,
                            m.updated_at
                           FROM matches m
                             JOIN teams t ON t.id = m.team_id
                          WHERE m.published = true AND m.has_conflict = false) legacy_1_1
                  WHERE NOT (EXISTS ( SELECT 1
                           FROM matches m
                          WHERE m.id = legacy_1_1.id AND (m.source_data ->> ''import_source''::text) = ''esbb_minibasket''::text))
                UNION ALL
                 SELECT m.id,
                    t.code AS team_code,
                    t.name AS team_name,
                    t.competition_label,
                    m.opponent_name,
                    m.home_away,
                    COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb) AS starts_local,
                    COALESCE(m.scheduled_local_override::date, NULLIF(m.source_data ->> ''local_date''::text, ''''::text)::date, m.scheduled_local_ffbb::date)::text AS local_date,
                        CASE
                            WHEN m.scheduled_local_override IS NOT NULL THEN NULLIF(m.scheduled_local_override::time without time zone, ''00:00:00''::time without time zone)
                            WHEN (m.source_data ->> ''time_known''::text) = ''true''::text THEN NULLIF(m.scheduled_local_ffbb::time without time zone, ''00:00:00''::time without time zone)
                            ELSE NULL::time without time zone
                        END::text AS local_time,
                    m.venue_name_raw AS venue_name,
                    m.venue_address_raw AS venue_address,
                    m.round_label,
                    m.status,
                    NULL::text AS ffbb_team_url,
                    NULL::text AS ffbb_match_url,
                    m.updated_at
                   FROM matches m
                     JOIN teams t ON t.id = m.team_id
                  WHERE (m.source_data ->> ''import_source''::text) = ''esbb_minibasket''::text AND m.published = true AND m.has_conflict = false AND t.is_public = true) legacy_1
          WHERE NOT (EXISTS ( SELECT 1
                   FROM matches m
                  WHERE m.id = legacy_1.id AND (m.source_data ->> ''import_source''::text) = ''esbb_u18m_fbi''::text))
        UNION ALL
         SELECT m.id,
            t.code AS team_code,
            t.name AS team_name,
            m.competition_name AS competition_label,
            m.opponent_name,
            m.home_away,
            COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb) AS starts_local,
            COALESCE(m.scheduled_local_override::date, m.scheduled_local_ffbb::date, NULLIF(m.source_data ->> ''local_date''::text, ''''::text)::date)::text AS local_date,
            NULLIF(COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb)::time without time zone, ''00:00:00''::time without time zone)::text AS local_time,
            m.venue_name_raw AS venue_name,
            m.venue_address_raw AS venue_address,
            m.round_label,
            m.status,
            NULL::text AS ffbb_team_url,
            m.ffbb_match_url,
            m.updated_at
           FROM matches m
             JOIN teams t ON t.id = m.team_id
          WHERE (m.source_data ->> ''import_source''::text) = ''esbb_u18m_fbi''::text AND m.published AND NOT m.has_conflict AND t.is_public) legacy
  WHERE NOT (EXISTS ( SELECT 1
           FROM matches m
          WHERE m.id = legacy.id AND (m.source_data ->> ''import_source''::text) = ''esbb_u13_u15_fbi''::text))
UNION ALL
 SELECT m.id,
    t.code AS team_code,
    t.name AS team_name,
    m.competition_name AS competition_label,
    m.opponent_name,
    m.home_away,
    COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb) AS starts_local,
    COALESCE(m.scheduled_local_override::date, m.scheduled_local_ffbb::date, NULLIF(m.source_data ->> ''local_date''::text, ''''::text)::date)::text AS local_date,
    NULLIF(COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb)::time without time zone, ''00:00:00''::time without time zone)::text AS local_time,
    m.venue_name_raw AS venue_name,
    m.venue_address_raw AS venue_address,
    m.round_label,
    m.status,
    NULL::text AS ffbb_team_url,
    m.ffbb_match_url,
    m.updated_at
   FROM matches m
     JOIN teams t ON t.id = m.team_id
  WHERE (m.source_data ->> ''import_source''::text) = ''esbb_u13_u15_fbi''::text AND m.published AND NOT m.has_conflict AND t.is_public;',reloptions FROM pg_class WHERE oid='public.public_calendar'::regclass;
DO $replace$ DECLARE options text[]; BEGIN
 SELECT reloptions INTO options FROM pg_class WHERE oid='public.public_calendar'::regclass;
 -- CREATE OR REPLACE peut réinitialiser reloptions : les réappliquer explicitement.
 EXECUTE 'CREATE OR REPLACE VIEW public.public_calendar'
  || CASE WHEN cardinality(options)>0 THEN ' WITH ('||array_to_string(options,',')||')' ELSE '' END
  || ' AS ' || 'SELECT legacy.id, legacy.team_code, legacy.team_name, legacy.competition_label, legacy.opponent_name, legacy.home_away, legacy.starts_local, legacy.local_date, legacy.local_time, legacy.venue_name, legacy.venue_address, legacy.round_label, legacy.status, legacy.ffbb_team_url, legacy.ffbb_match_url, legacy.updated_at FROM (SELECT legacy_1.id, legacy_1.team_code, legacy_1.team_name, legacy_1.competition_label, legacy_1.opponent_name, legacy_1.home_away, legacy_1.starts_local, legacy_1.local_date, legacy_1.local_time, legacy_1.venue_name, legacy_1.venue_address, legacy_1.round_label, legacy_1.status, legacy_1.ffbb_team_url, legacy_1.ffbb_match_url, legacy_1.updated_at FROM (SELECT legacy_1_1.id, legacy_1_1.team_code, legacy_1_1.team_name, legacy_1_1.competition_label, legacy_1_1.opponent_name, legacy_1_1.home_away, legacy_1_1.starts_local, legacy_1_1.local_date, legacy_1_1.local_time, legacy_1_1.venue_name, legacy_1_1.venue_address, legacy_1_1.round_label, legacy_1_1.status, legacy_1_1.ffbb_team_url, legacy_1_1.ffbb_match_url, legacy_1_1.updated_at FROM (SELECT m.id, t.code AS team_code, t.name AS team_name, t.competition_label, m.opponent_name, m.home_away, COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb) AS starts_local, to_char(COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb), CAST(''YYYY-MM-DD'' AS text)) AS local_date, to_char(COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb), CAST(''HH24:MI'' AS text)) AS local_time, COALESCE(m.venue_name_override, m.venue_name_raw) AS venue_name, m.venue_address_raw AS venue_address, m.round_label, m.status, t.ffbb_team_url, m.ffbb_match_url, m.updated_at FROM matches AS m INNER JOIN teams AS t ON t.id = m.team_id WHERE m.published = TRUE AND m.has_conflict = FALSE) AS legacy_1_1 WHERE NOT EXISTS (SELECT 1 FROM matches AS m WHERE m.id = legacy_1_1.id AND (m.source_data ->> CAST(''import_source'' AS text)) = CAST(''esbb_minibasket'' AS text)) UNION ALL SELECT m.id, t.code AS team_code, t.name AS team_name, t.competition_label, m.opponent_name, m.home_away, COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb) AS starts_local, CAST(COALESCE(CAST(m.scheduled_local_override AS date), CAST(NULLIF(m.source_data ->> CAST(''local_date'' AS text), CAST('''' AS text)) AS date), CAST(m.scheduled_local_ffbb AS date)) AS text) AS local_date, CAST(CASE WHEN m.scheduled_local_override IS NOT NULL THEN NULLIF(CAST(m.scheduled_local_override AS time), CAST(''00:00:00'' AS time)) WHEN (m.source_data ->> CAST(''time_known'' AS text)) = CAST(''true'' AS text) THEN NULLIF(CAST(m.scheduled_local_ffbb AS time), CAST(''00:00:00'' AS time)) ELSE CAST(NULL AS time) END AS text) AS local_time, COALESCE(m.venue_name_override, m.venue_name_raw) AS venue_name, m.venue_address_raw AS venue_address, m.round_label, m.status, CAST(NULL AS text) AS ffbb_team_url, CAST(NULL AS text) AS ffbb_match_url, m.updated_at FROM matches AS m INNER JOIN teams AS t ON t.id = m.team_id WHERE (m.source_data ->> CAST(''import_source'' AS text)) = CAST(''esbb_minibasket'' AS text) AND m.published = TRUE AND m.has_conflict = FALSE AND t.is_public = TRUE) AS legacy_1 WHERE NOT EXISTS (SELECT 1 FROM matches AS m WHERE m.id = legacy_1.id AND (m.source_data ->> CAST(''import_source'' AS text)) = CAST(''esbb_u18m_fbi'' AS text)) UNION ALL SELECT m.id, t.code AS team_code, t.name AS team_name, m.competition_name AS competition_label, m.opponent_name, m.home_away, COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb) AS starts_local, CAST(COALESCE(CAST(m.scheduled_local_override AS date), CAST(m.scheduled_local_ffbb AS date), CAST(NULLIF(m.source_data ->> CAST(''local_date'' AS text), CAST('''' AS text)) AS date)) AS text) AS local_date, CAST(NULLIF(CAST(COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb) AS time), CAST(''00:00:00'' AS time)) AS text) AS local_time, COALESCE(m.venue_name_override, m.venue_name_raw) AS venue_name, m.venue_address_raw AS venue_address, m.round_label, m.status, CAST(NULL AS text) AS ffbb_team_url, m.ffbb_match_url, m.updated_at FROM matches AS m INNER JOIN teams AS t ON t.id = m.team_id WHERE (m.source_data ->> CAST(''import_source'' AS text)) = CAST(''esbb_u18m_fbi'' AS text) AND m.published AND NOT m.has_conflict AND t.is_public) AS legacy WHERE NOT EXISTS (SELECT 1 FROM matches AS m WHERE m.id = legacy.id AND (m.source_data ->> CAST(''import_source'' AS text)) = CAST(''esbb_u13_u15_fbi'' AS text)) UNION ALL SELECT m.id, t.code AS team_code, t.name AS team_name, m.competition_name AS competition_label, m.opponent_name, m.home_away, COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb) AS starts_local, CAST(COALESCE(CAST(m.scheduled_local_override AS date), CAST(m.scheduled_local_ffbb AS date), CAST(NULLIF(m.source_data ->> CAST(''local_date'' AS text), CAST('''' AS text)) AS date)) AS text) AS local_date, CAST(NULLIF(CAST(COALESCE(m.scheduled_local_override, m.scheduled_local_ffbb) AS time), CAST(''00:00:00'' AS time)) AS text) AS local_time, COALESCE(m.venue_name_override, m.venue_name_raw) AS venue_name, m.venue_address_raw AS venue_address, m.round_label, m.status, CAST(NULL AS text) AS ffbb_team_url, m.ffbb_match_url, m.updated_at FROM matches AS m INNER JOIN teams AS t ON t.id = m.team_id WHERE (m.source_data ->> CAST(''import_source'' AS text)) = CAST(''esbb_u13_u15_fbi'' AS text) AND m.published AND NOT m.has_conflict AND t.is_public';
END $replace$;
COMMIT;
