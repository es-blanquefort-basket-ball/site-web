-- À exécuter par l'administrateur dans le SQL Editor du projet du club.
-- Métadonnées uniquement : pas de lecture des lignes métier, ni de modification.
-- Vérifier les définitions avant de les partager si elles contiennent des littéraux sensibles.

-- 1. Définition de la vue publique utilisée par le site.
SELECT n.nspname AS schema_name, c.relname, c.relkind,
       pg_get_viewdef(c.oid, true) AS view_definition
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relname = 'public_calendar'
  AND c.relkind IN ('v', 'm');

-- 2. Relations dont dépend la vue, y compris les dépendances des vues intermédiaires.
WITH RECURSIVE relations(oid) AS (
  SELECT to_regclass('public.public_calendar')::oid
  UNION
  SELECT d.refobjid
  FROM relations r
  JOIN pg_rewrite w ON w.ev_class = r.oid
  JOIN pg_depend d ON d.classid = 'pg_rewrite'::regclass AND d.objid = w.oid
  WHERE d.refclassid = 'pg_class'::regclass
)
SELECT n.nspname AS schema_name, c.relname, c.relkind,
       c.relrowsecurity AS rls_enabled,
       CASE WHEN c.relkind IN ('v', 'm') THEN pg_get_viewdef(c.oid, true) END AS view_definition,
       c.reloptions
FROM relations r
JOIN pg_class c ON c.oid = r.oid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'p', 'v', 'm', 'f')
ORDER BY n.nspname, c.relname;

-- 3. Types, nullabilité, contraintes et index des seules relations dépendantes.
WITH RECURSIVE relations(oid) AS (
  SELECT to_regclass('public.public_calendar')::oid
  UNION
  SELECT d.refobjid
  FROM relations r
  JOIN pg_rewrite w ON w.ev_class = r.oid
  JOIN pg_depend d ON d.classid = 'pg_rewrite'::regclass AND d.objid = w.oid
  WHERE d.refclassid = 'pg_class'::regclass
)
SELECT n.nspname AS schema_name, c.relname,
  (SELECT jsonb_agg(jsonb_build_object(
     'column', a.attname, 'type', format_type(a.atttypid, a.atttypmod),
     'not_null', a.attnotnull, 'identity', a.attidentity, 'generated', a.attgenerated,
     'default_expression', pg_get_expr(ad.adbin, ad.adrelid)
   ) ORDER BY a.attnum)
   FROM pg_attribute a LEFT JOIN pg_attrdef ad ON ad.adrelid = a.attrelid AND ad.adnum = a.attnum
   WHERE a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped) AS columns,
  (SELECT jsonb_agg(jsonb_build_object(
     'name', k.conname, 'type', k.contype, 'definition', pg_get_constraintdef(k.oid, true)
   ) ORDER BY k.conname)
   FROM pg_constraint k WHERE k.conrelid = c.oid) AS constraints,
  (SELECT jsonb_agg(pg_get_indexdef(i.indexrelid) ORDER BY i.indexrelid)
   FROM pg_index i WHERE i.indrelid = c.oid) AS indexes,
  (SELECT jsonb_agg(jsonb_build_object('name', pol.polname, 'command', pol.polcmd))
   FROM pg_policy pol WHERE pol.polrelid = c.oid) AS policies,
  (SELECT jsonb_agg(jsonb_build_object('name', t.tgname, 'function', t.tgfoid::regproc::text))
   FROM pg_trigger t WHERE t.tgrelid = c.oid AND NOT t.tgisinternal) AS triggers
FROM relations r
JOIN pg_class c ON c.oid = r.oid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'p', 'v', 'm', 'f')
ORDER BY n.nspname, c.relname;
