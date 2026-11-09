-- Contrôle bloquant EN LECTURE SEULE après 01 -> 01a -> 02.
-- À exécuter AVANT toute attribution/activation. N'ouvre aucun verrou.
BEGIN READ ONLY;
DO $verify$ BEGIN
 IF (SELECT count(*) FROM pg_proc p WHERE p.oid IN ('site_m01.auth_uid()'::regprocedure,'site_m01.auth_jwt()'::regprocedure) AND p.prosqlbody IS NOT NULL AND NOT p.prosecdef AND NOT has_function_privilege('authenticated',p.oid,'EXECUTE') AND NOT has_function_privilege('anon',p.oid,'EXECUTE'))<>2 THEN RAISE EXCEPTION 'Relais Auth privés préanalysés invoker requis'; END IF;
 IF NOT has_function_privilege('site_m01_executor','auth.uid()','EXECUTE') OR NOT has_function_privilege('site_m01_executor','auth.jwt()','EXECUTE') THEN RAISE EXCEPTION 'EXECUTE Auth requis pour le rôle interne'; END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='site_m01_executor' AND NOT rolcanlogin AND NOT rolsuper AND NOT rolbypassrls AND NOT rolcreaterole AND NOT rolcreatedb) THEN RAISE EXCEPTION 'Rôle exécuteur absent ou trop privilégié'; END IF;
 IF pg_has_role('authenticated','site_m01_executor','MEMBER') OR pg_has_role('anon','site_m01_executor','MEMBER') THEN RAISE EXCEPTION 'Élévation de rôle client interdite'; END IF;
 IF EXISTS(SELECT 1 FROM pg_auth_members WHERE member='site_m01_executor'::regrole OR (roleid='site_m01_executor'::regrole AND member<>(SELECT nspowner FROM pg_namespace WHERE nspname='site_m01'))) THEN RAISE EXCEPTION 'Délégation du rôle interne hors opérateur propriétaire interdite'; END IF;
 IF EXISTS(SELECT 1 FROM pg_class c WHERE c.relnamespace='site_m01'::regnamespace AND c.relkind IN ('r','p') AND (NOT c.relrowsecurity OR c.relowner=(SELECT oid FROM pg_roles WHERE rolname='site_m01_executor'))) THEN RAISE EXCEPTION 'RLS privée contournable'; END IF;
 IF EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace JOIN pg_roles r ON r.oid=p.proowner WHERE n.nspname='site_m01' AND (r.rolname<>'site_m01_executor' OR r.rolsuper OR r.rolbypassrls OR NOT COALESCE(p.proconfig @> ARRAY['row_security=on'],false))) THEN RAISE EXCEPTION 'Propriétaire/row_security des fonctions incorrect'; END IF;
 IF EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname LIKE 'site_m01_%' AND p.prosecdef) THEN RAISE EXCEPTION 'Façade publique privilégiée interdite'; END IF;
 IF EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE (n.nspname='site_m01' OR (n.nspname='public' AND p.proname LIKE 'site_m01_%')) AND NOT EXISTS(SELECT 1 FROM unnest(p.proconfig) cfg WHERE cfg IN ('search_path=""','search_path='))) THEN RAISE EXCEPTION 'search_path vide requis'; END IF;
 IF EXISTS(SELECT 1 FROM pg_roles r WHERE r.rolname IN ('anon','authenticated') AND has_any_column_privilege(r.rolname,'public.matches','UPDATE')) THEN RAISE EXCEPTION 'UPDATE client interdit'; END IF;
 IF EXISTS(SELECT 1 FROM pg_attribute a WHERE a.attrelid='public.matches'::regclass AND a.attnum>0 AND NOT a.attisdropped AND has_column_privilege('site_m01_executor',a.attrelid,a.attnum,'UPDATE')<>(a.attname IN ('scheduled_local_override','venue_name_override'))) THEN RAISE EXCEPTION 'UPDATE exécuteur hors des deux overrides'; END IF;
 IF EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='site_m01' AND has_function_privilege('anon',p.oid,'EXECUTE')) THEN RAISE EXCEPTION 'Fonction privée accessible anonymement'; END IF;
 IF has_function_privilege('authenticated','site_m01.identity()','EXECUTE') OR has_function_privilege('authenticated','site_m01.allowed(text,text)','EXECUTE') THEN RAISE EXCEPTION 'Helper privé exposé'; END IF;
 IF NOT (SELECT COALESCE(reloptions,ARRAY[]::text[]) @> ARRAY['security_invoker=true'] FROM pg_class WHERE oid='public.public_calendar'::regclass) THEN RAISE EXCEPTION 'security_invoker=true requis'; END IF;
 IF (SELECT count(*) FROM regexp_matches(pg_get_viewdef('public.public_calendar'::regclass,true),
  'COALESCE\(m\.venue_name_override, m\.venue_name_raw\) AS venue_name','g'))<>4
  OR pg_get_viewdef('public.public_calendar'::regclass,true) ~ 'm\.venue_name_raw AS venue_name'
 THEN RAISE EXCEPTION 'Les quatre branches de public_calendar doivent utiliser venue_name_override'; END IF;
 -- Empreinte de la définition reçue avec les trois projections brutes remplacées,
 -- et sans autre modification. Un écart imprévu impose une nouvelle revue.
 IF md5(pg_get_viewdef('public.public_calendar'::regclass,true)) <> '919d12fb7af679d5913a8738ae180045'
 THEN RAISE EXCEPTION 'Définition public_calendar différente de la référence corrigée'; END IF;
 IF EXISTS(SELECT 1 FROM site_m01.model WHERE management_enabled OR live_enabled OR access_enabled) THEN RAISE EXCEPTION 'Les écritures doivent rester fermées avant recette'; END IF;
 IF (SELECT count(*) FROM pg_policies WHERE schemaname='public' AND policyname IN ('site_m01_executor_read_matches','site_m01_executor_update_matches','site_m01_executor_read_teams') AND roles=ARRAY['site_m01_executor']::name[])<>3 THEN RAISE EXCEPTION 'Politiques exécuteur manquantes ou élargies'; END IF;
END $verify$;
SELECT 'Contrôle installation réussi, écritures fermées' AS result;
SELECT n.nspname AS schema_name,p.proname,p.prosecdef,r.rolname AS owner,p.proconfig,
 has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute,
 has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace JOIN pg_roles r ON r.oid=p.proowner
WHERE n.nspname='site_m01' OR (n.nspname='public' AND p.proname LIKE 'site_m01_%')
ORDER BY n.nspname,p.proname;
COMMIT;
