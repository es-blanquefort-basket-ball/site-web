-- SITE-M01 : lecture uniquement dans le SQL Editor de fgswygeqstgagmipltpq.
-- Aucun accès aux personnes ni aux données de rencontres, aucune écriture.

-- 1. Identifier clé stable, relation équipe, champs FFBB et corrections manuelles.
SELECT table_name, column_name, data_type, udt_name, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name IN ('matches', 'teams', 'public_calendar')
ORDER BY table_name, ordinal_position;
SELECT conrelid::regclass AS relation, conname, pg_get_constraintdef(oid, true) AS definition
FROM pg_constraint
WHERE conrelid IN (to_regclass('public.matches'), to_regclass('public.teams'))
ORDER BY conrelid::regclass::text, conname;

-- 2. Vérifier la priorité manuelle/FFBB, l’identifiant exposé et la propagation.
SELECT c.relname, c.relkind, c.reloptions, pg_get_viewdef(c.oid, true) AS definition
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relname = 'public_calendar' AND c.relkind IN ('v','m');

-- 3. Vérifier RLS et les prédicats SELECT/UPDATE : authenticated seul ne suffit pas.
SELECT c.relname, c.relrowsecurity, c.relforcerowsecurity
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relname IN ('matches','teams');
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies WHERE schemaname = 'public' AND tablename IN ('matches','teams');

-- 4. Vérifier les privilèges effectifs et restrictions par colonne (sans modifier).
SELECT r.role_name, c.relname, has_table_privilege(r.role_name,c.oid,'SELECT') AS can_select,
       has_table_privilege(r.role_name,c.oid,'UPDATE') AS can_update
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
CROSS JOIN (VALUES ('anon'),('authenticated')) AS r(role_name)
WHERE n.nspname='public' AND c.relname IN ('matches','teams','public_calendar');
SELECT grantee, table_name, column_name, privilege_type
FROM information_schema.column_privileges
WHERE table_schema='public' AND table_name='matches' AND grantee IN ('anon','authenticated','PUBLIC');

-- 5. Identifier les fonctions référencées par les politiques, sans supposer de RPC.
SELECT DISTINCT p.oid::regprocedure AS function, p.prosecdef AS security_definer,
       p.proconfig, p.proacl, pg_get_functiondef(p.oid) AS definition
FROM pg_policy pol
JOIN pg_depend d ON d.classid='pg_policy'::regclass AND d.objid=pol.oid AND d.refclassid='pg_proc'::regclass
JOIN pg_proc p ON p.oid=d.refobjid
WHERE pol.polrelid=to_regclass('public.matches');

-- 6. Vérifier les triggers de corrections/horodatage et leurs fonctions.
SELECT t.tgname, pg_get_triggerdef(t.oid,true) AS trigger_definition,
       pg_get_functiondef(t.tgfoid) AS function_definition
FROM pg_trigger t WHERE t.tgrelid=to_regclass('public.matches') AND NOT t.tgisinternal;
-- Ne pas partager de littéraux sensibles si une définition en contient.
-- Selon les résultats, une requête ciblée sur la relation d'autorisation référencée
-- sera nécessaire. Ne pas exporter auth.users ni les listes d'adresses autorisées.
