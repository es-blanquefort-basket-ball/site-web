-- MODÈLE DE CONFIGURATION, NON EXÉCUTÉ. Aucune adresse ni identité réelle.
-- Une seule configuration technique après récupération du schéma réel.
-- Remplacer les cinq [À COMPLÉTER] par des NOMS DE COLONNES confirmés.
-- Le bloc échoue et annule tout si un nom/type est absent ou incompatible.
BEGIN;
DO $$
DECLARE source_column name := '[À COMPLÉTER]';
 opponent_column name := '[À COMPLÉTER]';
 label_column name := '[À COMPLÉTER]';
 competition_column name := '[À COMPLÉTER]';
 public_id_column name := '[À COMPLÉTER]';
BEGIN
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
-- INSERT INTO site_m01.team_rules(team_id,competition_code,score_policy)
-- VALUES ('[ID ÉQUIPE U11 M1]','DMU11-4-P2','numeric'),
--        ('[ID ÉQUIPE U11 M2]','DMU11-10-P2','minibasket-no-score'),
--        ('[ID ÉQUIPE U9]','[COMPÉTITION RÉELLE U9]','u9-no-score');
-- Ne donner aucun autre score_policy='numeric' sans validation de la règle d'équipe.
-- 3. Après validation sur environnement de test : activation distincte côté serveur
-- UPDATE site_m01.model SET access_enabled=true; -- configuration des habilitations
-- management_enabled et live_enabled restent false tant que les écritures non validées.
-- L'administrateur connecté pourra alors appeler la RPC site_m01_set_access avec l'UUID
-- Supabase Auth existant, l'ID réel d'équipe et trois booléens explicites.
-- Retrait = p_enabled:false (tombstone manuel prioritaire sur une future source club_app).
-- La synchronisation club_app n'est pas développée ni autorisée aux clients.
