-- Retour arrière strict d'une liste de NOUVEAUX UUID, jamais des 57 rencontres initiales.
-- Mode verify par défaut. current_md5 issu du SELECT final de l'import, à conserver avant actualisation.
BEGIN;
CREATE TEMP TABLE p2_undo_options(action text) ON COMMIT DROP;
INSERT INTO p2_undo_options VALUES ('verify');
CREATE TEMP TABLE p2_undo ON COMMIT DROP AS SELECT * FROM
 jsonb_to_recordset($undo$[]$undo$::jsonb) AS x(id uuid,current_md5 text);
SELECT u.id,m.ffbb_match_id,
 md5((to_jsonb(m)-'updated_at')::text)=u.current_md5 AS unchanged
FROM p2_undo u LEFT JOIN public.matches m ON m.id=u.id;
DO $undo_apply$
DECLARE original_view text; installed_view text; options text[];
BEGIN
 IF (SELECT action FROM p2_undo_options)='verify' THEN RETURN; END IF;
 IF (SELECT action FROM p2_undo_options)<>'rollback' THEN RAISE EXCEPTION 'Action inconnue'; END IF;
 IF NOT EXISTS(SELECT 1 FROM p2_undo) THEN RAISE EXCEPTION 'Liste vide'; END IF;
 PERFORM pg_advisory_xact_lock(202627,1104);
 LOCK TABLE public.matches,public.teams IN SHARE ROW EXCLUSIVE MODE;
 SET CONSTRAINTS ALL IMMEDIATE;
 IF EXISTS(SELECT 1 FROM p2_undo u LEFT JOIN public.matches m ON m.id=u.id WHERE m.id IS NULL
   OR m.source_data->>'import_source' IS DISTINCT FROM 'esbb_ffbb_phase2'
   OR md5((to_jsonb(m)-'updated_at')::text) IS DISTINCT FROM u.current_md5
   OR to_jsonb(m)-'source_data'-'updated_at' IS DISTINCT FROM m.source_data->'rollback_snapshot')
   OR EXISTS(SELECT 1 FROM p2_undo GROUP BY id HAVING count(*)>1)
 THEN RAISE EXCEPTION 'Lot absent, modifié ou hors périmètre'; END IF;
 SELECT m.source_data->>'view_before',m.source_data->>'view_installed' INTO original_view,installed_view
 FROM public.matches m JOIN p2_undo u ON u.id=m.id LIMIT 1;
 IF original_view IS NULL OR pg_get_viewdef('public.public_calendar'::regclass,true) IS DISTINCT FROM installed_view
   OR EXISTS(SELECT 1 FROM public.matches m JOIN p2_undo u ON u.id=m.id
     WHERE m.source_data->>'view_before' IS DISTINCT FROM original_view
       OR m.source_data->>'view_installed' IS DISTINCT FROM installed_view) THEN
   RAISE EXCEPTION 'Vue ou lot de retour arrière devenu incompatible'; END IF;
 CREATE TEMP TABLE p2_undo_before_matches ON COMMIT DROP AS
   SELECT id,to_jsonb(m) row_data FROM public.matches m WHERE id NOT IN (SELECT id FROM p2_undo);
 CREATE TEMP TABLE p2_undo_before_public ON COMMIT DROP AS
   SELECT id,to_jsonb(v) row_data FROM public.public_calendar v WHERE id NOT IN (SELECT id FROM p2_undo);
 CREATE TEMP TABLE p2_undo_teams ON COMMIT DROP AS
   SELECT DISTINCT m.team_id id,m.source_data->'created_team_snapshot' row_data
   FROM public.matches m JOIN p2_undo u ON m.id=u.id
   WHERE m.source_data->'created_team_snapshot' IS NOT NULL AND m.source_data->'created_team_snapshot'<>'null'::jsonb;
 DELETE FROM public.matches m USING p2_undo u WHERE m.id=u.id;
 DELETE FROM public.teams t USING p2_undo_teams o WHERE t.id=o.id AND to_jsonb(t)=o.row_data
   AND NOT EXISTS (SELECT 1 FROM public.matches m WHERE m.team_id=t.id);
 IF NOT EXISTS(SELECT 1 FROM public.matches m WHERE m.source_data->>'import_source'='esbb_ffbb_phase2') THEN
   SELECT reloptions INTO options FROM pg_class WHERE oid='public.public_calendar'::regclass;
   EXECUTE format('CREATE OR REPLACE VIEW public.public_calendar %s AS %s',
    CASE WHEN options IS NULL THEN '' ELSE 'WITH ('||array_to_string(options,',')||')' END,original_view);
 END IF;
 IF EXISTS(SELECT 1 FROM p2_undo_before_matches b LEFT JOIN public.matches m ON m.id=b.id
   WHERE m.id IS NULL OR to_jsonb(m) IS DISTINCT FROM b.row_data)
   OR EXISTS(SELECT 1 FROM p2_undo_before_public b LEFT JOIN public.public_calendar v ON v.id=b.id
   WHERE v.id IS NULL OR to_jsonb(v) IS DISTINCT FROM b.row_data) THEN
   RAISE EXCEPTION 'Effet sur une rencontre hors lot : transaction annulée'; END IF;
END
$undo_apply$;
COMMIT;
