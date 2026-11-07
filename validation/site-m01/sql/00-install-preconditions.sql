-- LECTURE SEULE, à lancer dans le SQL Editor du projet fgswygeqstgagmipltpq.
-- Aucune migration, aucune ligne de personne, aucun contenu de demande affiché.
BEGIN READ ONLY;
SELECT jsonb_build_object(
 'server_version',current_setting('server_version'),
 'operator',current_user,
 'operator_can_create_role',(SELECT rolcreaterole OR rolsuper FROM pg_roles WHERE rolname=current_user),
 'operator_inherits_maintenance_role',(SELECT rolinherit FROM pg_roles WHERE rolname=current_user),
 'can_create_schema',has_database_privilege(current_user,current_database(),'CREATE'),
 'can_create_public_rpc',has_schema_privilege(current_user,'public','CREATE'),
 'site_m01_already_present',to_regnamespace('site_m01') IS NOT NULL,
 'executor_role_already_present',EXISTS(SELECT 1 FROM pg_roles WHERE rolname='site_m01_executor'),
 'auth_uid_exists',to_regprocedure('auth.uid()') IS NOT NULL,
 'auth_jwt_exists',to_regprocedure('auth.jwt()') IS NOT NULL,
 'can_reference_auth_user_id',has_column_privilege(current_user,'auth.users','id','REFERENCES'),
 'auth_schema_usage_grantable',has_schema_privilege(current_user,'auth','USAGE WITH GRANT OPTION'),
 'auth_helpers_acl',(SELECT jsonb_agg(jsonb_build_object('function',p.oid::regprocedure::text,'acl',p.proacl,'execute_grantable',has_function_privilege(current_user,p.oid,'EXECUTE WITH GRANT OPTION'))) FROM pg_proc p WHERE p.oid IN (to_regprocedure('auth.uid()'),to_regprocedure('auth.jwt()'))),
 'source_table_owners',(SELECT jsonb_agg(jsonb_build_object('table',c.relname,'owner',pg_get_userbyid(c.relowner),'operator_is_owner_member',pg_has_role(current_user,c.relowner,'USAGE'))) FROM pg_class c WHERE c.oid IN ('public.matches'::regclass,'public.teams'::regclass)),
 'source_read_policies',(SELECT jsonb_agg(to_jsonb(p)) FROM pg_policies p WHERE p.schemaname='public' AND p.tablename IN ('matches','teams')),
 'matches_rls',(SELECT relrowsecurity FROM pg_class WHERE oid='public.matches'::regclass),
 'teams_rls',(SELECT relrowsecurity FROM pg_class WHERE oid='public.teams'::regclass),
 'calendar_options',(SELECT reloptions FROM pg_class WHERE oid='public.public_calendar'::regclass),
 'client_update_absent',NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname IN ('anon','authenticated') AND has_any_column_privilege(rolname,'public.matches','UPDATE')),
 'match_triggers',(SELECT jsonb_agg(jsonb_build_object('name',tgname,'function',tgfoid::regprocedure::text,'definition',pg_get_triggerdef(oid,true))) FROM pg_trigger WHERE tgrelid='public.matches'::regclass AND NOT tgisinternal)
) AS installation_preconditions;
-- Recherche de structure uniquement, strictement limitée aux dérogations/report match.
SELECT table_schema,table_name,column_name FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog','information_schema','auth','storage')
AND (table_name ~* '(derog|waiver|resched|dispens|demande|request|match.*change)'
 OR column_name ~* '(derog|waiver|resched|dispens)')
ORDER BY table_schema,table_name,ordinal_position;
SELECT n.nspname AS schema_name,p.proname AS function_name
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname NOT IN ('pg_catalog','information_schema','auth','storage')
AND p.proname ~* '(derog|waiver|resched|dispens|demande|match.*request|match.*change)';
-- Clés seulement, jamais les valeurs source_data ou coordonnées des personnes.
SELECT DISTINCT k AS derogation_source_key FROM public.matches m
CROSS JOIN LATERAL jsonb_object_keys(CASE WHEN jsonb_typeof(m.source_data)='object' THEN m.source_data ELSE '{}'::jsonb END) k
WHERE k ~* '(derog|waiver|resched|dispens|demande|match.*request|match.*change)';
COMMIT;
