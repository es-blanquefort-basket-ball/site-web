-- CONFIGURATION FINALISÉE depuis la définition réelle fournie. NON EXÉCUTÉE.
-- Aucun compte, aucune habilitation et aucune règle sportive ne sont insérés.
-- Le bloc échoue et annule tout si un nom/type est absent ou incompatible.
BEGIN;
DO $$
DECLARE source_column name := 'scheduled_local_ffbb';
 opponent_column name := 'opponent_name';
 label_column name := 'name';
 competition_column name := 'competition_name';
 public_id_column name := 'id';
BEGIN
 IF NOT (SELECT COALESCE(reloptions,ARRAY[]::text[]) @> ARRAY['security_invoker=true'] FROM pg_class WHERE oid='public.public_calendar'::regclass) THEN RAISE EXCEPTION 'security_invoker=true requis'; END IF;
 IF EXISTS(SELECT 1 FROM pg_attribute WHERE attrelid IN ('public.matches'::regclass,'public.teams'::regclass,'public.public_calendar'::regclass) AND attname='id' AND atttypid<>'uuid'::regtype AND NOT attisdropped)
 OR (SELECT match_pk<>'id' OR team_pk<>'id' OR match_team_fk<>'team_id' FROM site_m01.model) THEN RAISE EXCEPTION 'Identifiants différents du snapshot réel'; END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_attribute WHERE attrelid='public.matches'::regclass AND attname=source_column AND atttypid='timestamp'::regtype AND NOT attisdropped) THEN RAISE EXCEPTION 'Source requise : timestamp local sans fuseau de matches'; END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_attribute WHERE attrelid='public.matches'::regclass AND attname=opponent_column AND NOT attisdropped) OR
 NOT EXISTS(SELECT 1 FROM pg_attribute WHERE attrelid='public.matches'::regclass AND attname=competition_column AND NOT attisdropped) OR
 NOT EXISTS(SELECT 1 FROM pg_attribute WHERE attrelid='public.teams'::regclass AND attname=label_column AND NOT attisdropped) OR
 NOT EXISTS(SELECT 1 FROM pg_attribute WHERE attrelid='public.public_calendar'::regclass AND attname=public_id_column AND NOT attisdropped) THEN RAISE EXCEPTION 'Correspondance de colonne absente'; END IF;
 UPDATE site_m01.model SET scheduled_source=source_column,opponent=opponent_column,
 team_label=label_column,competition=competition_column,public_match_id=public_id_column;
END $$;
-- Toutes les écritures restent désactivées. Aucune ligne d'habilitation ou règle insérée.
COMMIT;

-- RECETTES UNIQUEMENT, ne pas décommenter sans décision du club.
-- 1. Administrateur initial : auth.users doit déjà contenir son UUID réel confirmé.
-- INSERT INTO site_m01.administrators(user_id) VALUES ('[UUID AUTH EXISTANT]'::uuid);
-- 2. Configurer les règles PAR IDENTIFIANT RÉEL d'équipe (jamais par nom approchant).
-- competition_name est un LIBELLÉ, jamais le code DMU11 par supposition.
-- source_competition doit reprendre exactement public_calendar.competition_label
-- pour les rencontres concernées et l’équipe identifiée.
-- INSERT INTO site_m01.team_rules(team_id,competition_code,score_policy,source_competition)
-- VALUES ('[ID ÉQUIPE U11 M1]','DMU11-4-P2','numeric','[LIBELLÉ EXACT DE LA COMPÉTITION]'),
--        ('[ID ÉQUIPE U11 M2]','DMU11-10-P2','minibasket-no-score','[LIBELLÉ EXACT DE LA COMPÉTITION]'),
--        ('[ID ÉQUIPE U9]','[COMPÉTITION RÉELLE U9]','u9-no-score','[LIBELLÉ EXACT DE LA COMPÉTITION]');
-- Ne donner aucun autre score_policy='numeric' sans validation de la règle d'équipe.
-- 3. Après validation sur environnement de test : activation distincte côté serveur
-- UPDATE site_m01.model SET access_enabled=true; -- configuration des habilitations
-- management_enabled et live_enabled restent false tant que les écritures non validées.
-- L'administrateur connecté pourra alors appeler la RPC site_m01_set_access avec l'UUID
-- Supabase Auth existant, l'ID réel d'équipe et trois booléens explicites.
-- Retrait = p_enabled:false (tombstone manuel prioritaire sur une future source club_app).
-- La synchronisation club_app n'est pas développée ni autorisée aux clients.
