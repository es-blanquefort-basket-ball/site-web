-- Complément de 00-install-preconditions.sql : uniquement les points non confirmés.
-- SQL Editor de fgswygeqstgagmipltpq, opérateur postgres. Lecture seule.
-- Ne crée aucun rôle/utilisateur, ne teste aucune écriture et ne lance pas le lot.
BEGIN READ ONLY;
SELECT
 (SELECT rolinherit FROM pg_roles WHERE rolname=current_user) AS operator_inherits_maintenance_role,
 to_regprocedure('auth.uid()') IS NOT NULL AS auth_uid_exists,
 to_regprocedure('auth.jwt()') IS NOT NULL AS auth_jwt_exists,
 has_column_privilege(current_user,'auth.users','id','REFERENCES') AS can_reference_auth_user_id,
 NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname IN ('anon','authenticated')
  AND has_any_column_privilege(rolname,'public.matches','UPDATE')) AS client_update_absent;

-- Le futur rôle n'existe pas : il reçoit déjà les privilèges PUBLIC, ou
-- l'opérateur doit pouvoir lui déléguer précisément le privilège manquant.
SELECT nspname AS schema_name,
 EXISTS(SELECT 1 FROM aclexplode(COALESCE(nspacl,acldefault('n',nspowner))) a
  WHERE a.grantee=0 AND a.privilege_type='USAGE') AS public_usage,
 has_schema_privilege(current_user,oid,'USAGE WITH GRANT OPTION') AS operator_usage_grantable
FROM pg_namespace WHERE nspname IN ('auth','public');
SELECT p.oid::regprocedure AS function_name,
 EXISTS(SELECT 1 FROM aclexplode(COALESCE(p.proacl,acldefault('f',p.proowner))) a
  WHERE a.grantee=0 AND a.privilege_type='EXECUTE') AS public_execute,
 has_function_privilege(current_user,p.oid,'EXECUTE WITH GRANT OPTION') AS operator_execute_grantable
FROM pg_proc p WHERE p.oid IN (to_regprocedure('auth.uid()'),to_regprocedure('auth.jwt()'));

SELECT c.relname,pg_get_userbyid(c.relowner) AS owner,
 pg_has_role(current_user,c.relowner,'USAGE') AS operator_is_owner_member
FROM pg_class c WHERE c.oid IN
 ('public.matches'::regclass,'public.teams'::regclass,'public.public_calendar'::regclass);

-- Inventaire limité à matches : inclut les triggers désactivés pour interprétation.
SELECT t.tgname,t.tgenabled,(t.tgtype::integer & 16)<>0 AS handles_update,
 pg_get_triggerdef(t.oid,true) AS trigger_definition,
 t.tgfoid::regprocedure AS trigger_function
FROM pg_trigger t WHERE t.tgrelid='public.matches'::regclass AND NOT t.tgisinternal;
-- Corps des seuls triggers UPDATE actifs en session normale. Vérifier les effets
-- sur les overrides, les champs FFBB, les écritures annexes/appels externes et RLS.
-- Métadonnées privées à examiner dans SQL Editor ; ne pas publier les corps bruts.
SELECT DISTINCT t.tgfoid::regprocedure AS trigger_function,
 pg_get_functiondef(t.tgfoid) AS function_definition
FROM pg_trigger t WHERE t.tgrelid='public.matches'::regclass AND NOT t.tgisinternal
 AND (t.tgtype::integer & 16)<>0 AND t.tgenabled IN ('O','A');
COMMIT;
