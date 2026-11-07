-- DURCISSEMENT OBLIGATOIRE après 01, avant toute configuration/activation.
-- Proposition NON EXÉCUTÉE en production. Aucun compte ni droit métier créé.
-- Les tables restent au propriétaire d'installation ; les fonctions privées sont
-- exécutées par un rôle distinct, sans LOGIN, SUPERUSER, BYPASSRLS ou appartenance app.
BEGIN;
CREATE ROLE site_m01_executor NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
GRANT site_m01_executor TO CURRENT_USER;
-- Seul l'opérateur SQL propriétaire du schéma conserve cette appartenance pour
-- maintenir/arrêter les fonctions. Aucune appartenance pour les rôles applicatifs.
GRANT USAGE ON SCHEMA site_m01 TO site_m01_executor;
GRANT CREATE ON SCHEMA site_m01 TO site_m01_executor;
-- Ne pas redéléguer inutilement les helpers Auth si PUBLIC les rend déjà exécutables.
-- Sinon l'opérateur doit posséder l'option de délégation exacte, sans élargir les clients.
DO $auth_acl$ DECLARE f regprocedure; n text; BEGIN
 FOREACH n IN ARRAY ARRAY['public','auth'] LOOP
  IF NOT has_schema_privilege('site_m01_executor',n,'USAGE') THEN
   EXECUTE format('GRANT USAGE ON SCHEMA %I TO site_m01_executor',n);
  END IF;
 END LOOP;
 FOREACH f IN ARRAY ARRAY['auth.uid()'::regprocedure,'auth.jwt()'::regprocedure] LOOP
  IF NOT has_function_privilege('site_m01_executor',f,'EXECUTE') THEN
   EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO site_m01_executor',f);
  END IF;
 END LOOP;
END $auth_acl$;

-- JWT signé par Auth : aucune lecture privilégiée de auth.users et aucun user_metadata.
-- L'existence des comptes cibles est contrôlée par les FK existantes vers auth.users.
CREATE OR REPLACE FUNCTION site_m01.identity() RETURNS uuid LANGUAGE plpgsql SET search_path='' AS $$
DECLARE u uuid:=auth.uid(); BEGIN
 IF u IS NULL OR COALESCE(auth.jwt()->>'is_anonymous','false')<>'false' THEN
  RAISE EXCEPTION 'Connexion requise' USING ERRCODE='42501';
 END IF;
 RETURN u;
END $$;
CREATE OR REPLACE FUNCTION site_m01.set_access(p_user uuid,p_team text,p_manage boolean,p_live boolean,p_enabled boolean)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE cfg site_m01.model; old_value jsonb; new_value jsonb;
BEGIN
 IF NOT site_m01.is_admin() THEN RAISE EXCEPTION 'Administration refusée' USING ERRCODE='42501'; END IF;
 SELECT * INTO STRICT cfg FROM site_m01.model;
 IF NOT cfg.access_enabled THEN RAISE EXCEPTION 'Configuration des accès désactivée' USING ERRCODE='42501'; END IF;
 IF p_manage IS NULL OR p_live IS NULL OR p_enabled IS NULL THEN RAISE EXCEPTION 'Droits explicites requis'; END IF;
 IF p_user IS NULL OR site_m01.team_row(p_team) IS NULL THEN RAISE EXCEPTION 'Utilisateur Auth ou équipe introuvable'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,1));
 SELECT to_jsonb(a) INTO old_value FROM site_m01.team_access a WHERE user_id=p_user AND team_id::text=p_team AND origin='manual';
 EXECUTE format('INSERT INTO site_m01.team_access(user_id,team_id,origin,enabled,can_manage,can_live,changed_by)
 SELECT $1,t.%I,''manual'',$3,$4,$5,auth.uid() FROM public.teams t WHERE t.%I=(jsonb_populate_record(NULL::public.teams,jsonb_build_object(%L,$2))).%I
 ON CONFLICT(user_id,team_id,origin) DO UPDATE SET enabled=excluded.enabled,can_manage=excluded.can_manage,can_live=excluded.can_live,changed_by=excluded.changed_by,changed_at=clock_timestamp()',cfg.team_pk,cfg.team_pk,cfg.team_pk,cfg.team_pk)
 USING p_user,p_team,p_enabled,p_manage,p_live;
 SELECT to_jsonb(a) INTO new_value FROM site_m01.team_access a WHERE user_id=p_user AND team_id::text=p_team AND origin='manual';
 INSERT INTO site_m01.history(actor_id,operation,subject_key,before_value,after_value) VALUES(auth.uid(),'access',p_user::text||'/'||p_team,old_value,new_value);
 RETURN true;
EXCEPTION WHEN foreign_key_violation THEN
 RAISE EXCEPTION 'Utilisateur Auth ou équipe introuvable' USING ERRCODE='23503';
END $$;

CREATE OR REPLACE FUNCTION site_m01.save_live(p_id text,p_revision bigint,p_patch jsonb) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE cfg site_m01.model; m jsonb; rule site_m01.team_rules; before_value jsonb; after_value jsonb; current_revision bigint; k text;
BEGIN
 SELECT * INTO STRICT cfg FROM site_m01.model;
 IF NOT cfg.live_enabled THEN RAISE EXCEPTION 'Écritures Live désactivées' USING ERRCODE='42501'; END IF;
 m:=site_m01.match_row(p_id,false);
 IF m IS NULL THEN RAISE EXCEPTION 'Rencontre introuvable' USING ERRCODE='P0002'; END IF;
 PERFORM site_m01.require_access('live',m->>cfg.match_team_fk);
 EXECUTE format('INSERT INTO site_m01.match_state(match_id) SELECT m.%I FROM public.matches m WHERE m.%I=(jsonb_populate_record(NULL::public.matches,jsonb_build_object(%L,$1))).%I ON CONFLICT DO NOTHING',cfg.match_pk,cfg.match_pk,cfg.match_pk,cfg.match_pk) USING p_id;
 SELECT live_revision INTO current_revision FROM site_m01.match_state WHERE match_id::text=p_id FOR UPDATE;
 IF p_revision IS NULL OR current_revision<>p_revision THEN RAISE EXCEPTION 'Version obsolète' USING ERRCODE='40001'; END IF;
 before_value:=site_m01.project(m,'live');
 IF p_patch IS NULL OR jsonb_typeof(p_patch)<>'object' THEN RAISE EXCEPTION 'Patch invalide'; END IF;
 IF (SELECT count(*) FROM jsonb_object_keys(p_patch))=1 AND p_patch?'stage' THEN
  IF jsonb_typeof(p_patch->'stage')<>'number' OR p_patch->>'stage' !~ '^[0-6]$' THEN RAISE EXCEPTION 'Étape invalide'; END IF;
  UPDATE site_m01.match_state SET stage=(p_patch->>'stage')::integer WHERE match_id::text=p_id;
 ELSIF (SELECT count(*) FROM jsonb_object_keys(p_patch))=2 AND p_patch ?& ARRAY['clubScore','opponentScore'] THEN
  SELECT * INTO rule FROM site_m01.team_rules WHERE team_id::text=m->>cfg.match_team_fk;
  IF before_value->>'scorePolicy' IS DISTINCT FROM 'numeric' OR rule.competition_code='DMU11-10-P2' THEN RAISE EXCEPTION 'Score interdit pour cette équipe' USING ERRCODE='42501'; END IF;
  FOREACH k IN ARRAY ARRAY['clubScore','opponentScore'] LOOP
   IF p_patch->k<>'null'::jsonb AND (jsonb_typeof(p_patch->k)<>'number' OR p_patch->>k !~ '^\d+$' OR (p_patch->>k)::numeric>2147483647) THEN RAISE EXCEPTION 'Score invalide'; END IF;
  END LOOP;
  UPDATE site_m01.match_state SET club_score=(p_patch->>'clubScore')::integer,opponent_score=(p_patch->>'opponentScore')::integer WHERE match_id::text=p_id;
 ELSE RAISE EXCEPTION 'Étape et score doivent être modifiés séparément'; END IF;
 UPDATE site_m01.match_state SET live_revision=live_revision+1 WHERE match_id::text=p_id;
 after_value:=site_m01.project(m,'live');
 INSERT INTO site_m01.history(actor_id,operation,subject_key,before_value,after_value) VALUES(auth.uid(),'live',p_id,before_value,after_value);
 RETURN true;
END $$;

-- ACL privées minimales : aucun accès de table à anon/authenticated.
GRANT SELECT ON site_m01.model,site_m01.administrators,site_m01.team_rules TO site_m01_executor;
GRANT SELECT,INSERT,UPDATE ON site_m01.team_access,site_m01.match_state TO site_m01_executor;
GRANT SELECT,INSERT ON site_m01.history TO site_m01_executor;
GRANT USAGE ON SEQUENCE site_m01.history_id_seq TO site_m01_executor;
GRANT SELECT ON public.matches,public.teams,public.public_calendar TO site_m01_executor;
GRANT UPDATE(scheduled_local_override,venue_name_override) ON public.matches TO site_m01_executor;

-- Le rôle d'exécution n'est propriétaire d'AUCUNE table : ces politiques s'appliquent.
CREATE POLICY site_m01_executor_read_model ON site_m01.model FOR SELECT TO site_m01_executor USING(true);
CREATE POLICY site_m01_executor_read_admins ON site_m01.administrators FOR SELECT TO site_m01_executor USING(true);
CREATE POLICY site_m01_executor_read_rules ON site_m01.team_rules FOR SELECT TO site_m01_executor
 USING(site_m01.is_admin() OR site_m01.allowed('management',team_id::text) OR site_m01.allowed('live',team_id::text));
CREATE POLICY site_m01_executor_read_access ON site_m01.team_access FOR SELECT TO site_m01_executor
 USING(user_id=(SELECT auth.uid()) OR site_m01.is_admin());
CREATE POLICY site_m01_executor_insert_access ON site_m01.team_access FOR INSERT TO site_m01_executor
 WITH CHECK(site_m01.is_admin() AND origin='manual' AND (SELECT access_enabled FROM site_m01.model));
CREATE POLICY site_m01_executor_update_access ON site_m01.team_access FOR UPDATE TO site_m01_executor
 USING(site_m01.is_admin() AND origin='manual' AND (SELECT access_enabled FROM site_m01.model))
 WITH CHECK(site_m01.is_admin() AND origin='manual' AND (SELECT access_enabled FROM site_m01.model));
CREATE POLICY site_m01_executor_read_history ON site_m01.history FOR SELECT TO site_m01_executor USING(site_m01.is_admin());
CREATE POLICY site_m01_executor_insert_history ON site_m01.history FOR INSERT TO site_m01_executor
 WITH CHECK(actor_id=site_m01.identity());

-- Politiques supplémentaires UNIQUEMENT TO site_m01_executor. Les politiques publiques
-- de lecture ne sont pas modifiées. Pas d'UPDATE pour authenticated/anon.
DO $policies$
DECLARE cfg site_m01.model; read_match text; write_match text; state_read text; state_write text;
BEGIN
 SELECT * INTO STRICT cfg FROM site_m01.model;
 EXECUTE format('CREATE POLICY site_m01_executor_read_teams ON public.teams FOR SELECT TO site_m01_executor
 USING(site_m01.is_admin() OR (is_public AND (site_m01.allowed(''management'',%I::text) OR site_m01.allowed(''live'',%I::text))))',cfg.team_pk,cfg.team_pk);
 read_match:=format('published AND NOT has_conflict AND (site_m01.allowed(''management'',%1$I::text) OR site_m01.allowed(''live'',%1$I::text)) AND EXISTS(SELECT 1 FROM public.teams t WHERE t.%2$I=matches.%1$I AND t.is_public)',cfg.match_team_fk,cfg.team_pk);
 write_match:=format('published AND NOT has_conflict AND site_m01.allowed(''management'',%1$I::text) AND (SELECT management_enabled FROM site_m01.model) AND EXISTS(SELECT 1 FROM public.teams t WHERE t.%2$I=matches.%1$I AND t.is_public)',cfg.match_team_fk,cfg.team_pk);
 EXECUTE format('CREATE POLICY site_m01_executor_read_matches ON public.matches FOR SELECT TO site_m01_executor USING(%s)',read_match);
 EXECUTE format('CREATE POLICY site_m01_executor_update_matches ON public.matches FOR UPDATE TO site_m01_executor USING(%1$s) WITH CHECK(%1$s)',write_match);
 state_read:=format('EXISTS(SELECT 1 FROM public.matches m WHERE m.%1$I=match_state.match_id AND (site_m01.allowed(''management'',m.%2$I::text) OR site_m01.allowed(''live'',m.%2$I::text)))',cfg.match_pk,cfg.match_team_fk);
 state_write:=format('EXISTS(SELECT 1 FROM public.matches m WHERE m.%1$I=match_state.match_id AND ((site_m01.allowed(''management'',m.%2$I::text) AND (SELECT management_enabled FROM site_m01.model)) OR (site_m01.allowed(''live'',m.%2$I::text) AND (SELECT live_enabled FROM site_m01.model))))',cfg.match_pk,cfg.match_team_fk);
 EXECUTE format('CREATE POLICY site_m01_executor_read_state ON site_m01.match_state FOR SELECT TO site_m01_executor USING(%s)',state_read);
 EXECUTE format('CREATE POLICY site_m01_executor_insert_state ON site_m01.match_state FOR INSERT TO site_m01_executor WITH CHECK(%s)',state_write);
 EXECUTE format('CREATE POLICY site_m01_executor_update_state ON site_m01.match_state FOR UPDATE TO site_m01_executor USING(%1$s) WITH CHECK(%1$s)',state_write);
END $policies$;

-- Propriétaire des fonctions différent du propriétaire des tables ; pas de bypass implicite.
DO $owners$ DECLARE f record; BEGIN
 FOR f IN SELECT p.oid::regprocedure AS signature FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='site_m01' LOOP
  EXECUTE format('ALTER FUNCTION %s OWNER TO site_m01_executor',f.signature);
  EXECUTE format('ALTER FUNCTION %s SET row_security=on',f.signature);
 END LOOP;
END $owners$;
REVOKE CREATE ON SCHEMA site_m01 FROM site_m01_executor;
-- Aucune appartenance ni SET ROLE pour les rôles clients ; ACL des helpers maintenues.
DO $check$ BEGIN
 IF pg_has_role('authenticated','site_m01_executor','MEMBER') OR pg_has_role('anon','site_m01_executor','MEMBER') THEN RAISE EXCEPTION 'Appartenance client interdite'; END IF;
 IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname='site_m01_executor' AND (rolsuper OR rolbypassrls OR rolcanlogin OR rolcreaterole)) THEN RAISE EXCEPTION 'Rôle trop privilégié'; END IF;
 IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname=current_user AND NOT rolinherit) THEN RAISE EXCEPTION 'Opérateur de maintenance INHERIT requis'; END IF;
 IF EXISTS(SELECT 1 FROM pg_auth_members WHERE member='site_m01_executor'::regrole OR (roleid='site_m01_executor'::regrole AND member<>(SELECT nspowner FROM pg_namespace WHERE nspname='site_m01'))) THEN RAISE EXCEPTION 'Délégation du rôle interne hors opérateur propriétaire interdite'; END IF;
 IF EXISTS(SELECT 1 FROM pg_class WHERE relnamespace='site_m01'::regnamespace AND relowner=(SELECT oid FROM pg_roles WHERE rolname='site_m01_executor')) THEN RAISE EXCEPTION 'Le rôle ne doit pas posséder les tables'; END IF;
END $check$;
COMMIT;
