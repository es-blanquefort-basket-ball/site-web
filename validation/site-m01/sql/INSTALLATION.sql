-- INSTALLATION ATOMIQUE PROPOS�E pour fgswygeqstgagmipltpq.
-- Ne pas ex�cuter sans validation humaine. Aucun compte/droit m�tier cr��.
-- Source : build-installation.py ; 03-disable.sql reste s�par�.
BEGIN;

-- Composant : 01-access-live.sql
-- SHA256 : f03ad495c0d9ac161f19c75f8c443a8a9aaa4a3a9381c8d8efbf12bec2a58fc6
-- PROPOSITION UNIQUEMENT. Ne pas exécuter en production sans validation.
-- Transaction atomique ; aucun compte, droit, règle sportive ou rencontre créé.
-- Schéma privé NON exposé dans les réglages Data API.

CREATE SCHEMA site_m01;
REVOKE ALL ON SCHEMA site_m01 FROM PUBLIC, anon, authenticated;
CREATE TABLE site_m01.model (
 singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton),
 match_pk name NOT NULL, team_pk name NOT NULL, match_team_fk name NOT NULL,
 scheduled_type text NOT NULL,
 -- Un seul raccordement à compléter avec les noms réels, jamais des valeurs métier.
 scheduled_source name, opponent name, team_label name, competition name,
 public_match_id name,
 management_enabled boolean NOT NULL DEFAULT false,
 live_enabled boolean NOT NULL DEFAULT false,
 access_enabled boolean NOT NULL DEFAULT false
);
DO $preflight$
DECLARE mp name; tp name; fk name; mt text; tt text; st text;
BEGIN
 SELECT a.attname,format_type(a.atttypid,a.atttypmod) INTO STRICT mp,mt
 FROM pg_constraint c JOIN pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=c.conkey[1]
 WHERE c.conrelid='public.matches'::regclass AND c.contype='p' AND cardinality(c.conkey)=1;
 SELECT a.attname,format_type(a.atttypid,a.atttypmod) INTO STRICT tp,tt
 FROM pg_constraint c JOIN pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=c.conkey[1]
 WHERE c.conrelid='public.teams'::regclass AND c.contype='p' AND cardinality(c.conkey)=1;
 SELECT a.attname INTO STRICT fk FROM pg_constraint c
 JOIN pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=c.conkey[1]
 WHERE c.conrelid='public.matches'::regclass AND c.confrelid='public.teams'::regclass
 AND c.contype='f' AND cardinality(c.conkey)=1 AND c.confkey[1]=
 (SELECT attnum FROM pg_attribute WHERE attrelid='public.teams'::regclass AND attname=tp);
 SELECT format_type(atttypid,atttypmod) INTO STRICT st FROM pg_attribute
 WHERE attrelid='public.matches'::regclass AND attname='scheduled_local_override' AND NOT attisdropped;
 IF st NOT IN ('timestamp without time zone','timestamp with time zone') THEN RAISE EXCEPTION 'Type scheduled_local_override non pris en charge : %',st; END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_attribute WHERE attrelid='public.matches'::regclass AND attname='venue_name_override' AND atttypid IN ('text'::regtype,'varchar'::regtype)) THEN RAISE EXCEPTION 'venue_name_override texte requis'; END IF;
 IF EXISTS(SELECT 1 FROM pg_class WHERE oid IN ('public.matches'::regclass,'public.teams'::regclass) AND NOT relrowsecurity) THEN RAISE EXCEPTION 'RLS requise'; END IF;
 IF EXISTS(SELECT 1 FROM pg_roles r WHERE r.rolname IN ('anon','authenticated') AND has_table_privilege(r.oid,'public.matches','UPDATE')) THEN RAISE EXCEPTION 'UPDATE direct préexistant : revoir avant installation'; END IF;
 INSERT INTO site_m01.model(match_pk,team_pk,match_team_fk,scheduled_type) VALUES(mp,tp,fk,st);
 EXECUTE format('CREATE TABLE site_m01.team_access (
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 team_id %s NOT NULL REFERENCES public.teams(%I) ON DELETE CASCADE,
 origin text NOT NULL DEFAULT ''manual'' CHECK(origin IN (''manual'',''club_app'')),
 enabled boolean NOT NULL DEFAULT true, can_manage boolean NOT NULL DEFAULT false,
 can_live boolean NOT NULL DEFAULT false, external_ref text,
 changed_at timestamptz NOT NULL DEFAULT clock_timestamp(), changed_by uuid,
 PRIMARY KEY(user_id,team_id,origin))',tt,tp);
 EXECUTE format('CREATE TABLE site_m01.team_rules (
 team_id %s PRIMARY KEY REFERENCES public.teams(%I) ON DELETE CASCADE,
 competition_code text NOT NULL, score_policy text NOT NULL
 CHECK(score_policy IN (''numeric'',''minibasket-no-score'',''u9-no-score'')),
 source_competition text NOT NULL,
 CHECK(competition_code <> ''DMU11-10-P2'' OR score_policy=''minibasket-no-score''))',tt,tp);
 EXECUTE format('CREATE TABLE site_m01.match_state (
 match_id %s PRIMARY KEY REFERENCES public.matches(%I) ON DELETE CASCADE,
 stage integer NOT NULL DEFAULT 0 CHECK(stage BETWEEN 0 AND 6),
 club_score integer CHECK(club_score>=0), opponent_score integer CHECK(opponent_score>=0),
 live_revision bigint NOT NULL DEFAULT 0, management_revision bigint NOT NULL DEFAULT 0)',mt,mp);
 -- Petits adaptateurs natifs : clés réelles, index PK conservés, aucun nom supposé.
 EXECUTE format($ddl$CREATE FUNCTION site_m01.team_row(p_id text) RETURNS jsonb LANGUAGE sql SET search_path='' AS $body$
 SELECT to_jsonb(t) FROM public.teams t WHERE t.%1$I=(jsonb_populate_record(NULL::public.teams,jsonb_build_object(%2$L,p_id))).%1$I $body$$ddl$,tp,tp);
 EXECUTE format($ddl$CREATE FUNCTION site_m01.match_row(p_id text,p_lock boolean DEFAULT false) RETURNS jsonb LANGUAGE plpgsql SET search_path='' AS $body$
 DECLARE r jsonb; BEGIN
 IF p_lock THEN SELECT to_jsonb(m) INTO r FROM public.matches m WHERE m.%1$I=(jsonb_populate_record(NULL::public.matches,jsonb_build_object(%2$L,p_id))).%1$I FOR UPDATE;
 ELSE SELECT to_jsonb(m) INTO r FROM public.matches m WHERE m.%1$I=(jsonb_populate_record(NULL::public.matches,jsonb_build_object(%2$L,p_id))).%1$I; END IF;
 RETURN r; END $body$$ddl$,mp,mp);
END $preflight$;
CREATE TABLE site_m01.administrators(user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE);
CREATE TABLE site_m01.history (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 occurred_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 actor_id uuid NOT NULL, operation text NOT NULL CHECK(operation IN ('access','management','live')),
 subject_key text NOT NULL, before_value jsonb, after_value jsonb
);
CREATE INDEX ON site_m01.history(subject_key,occurred_at);
DO $rls$ DECLARE t record; BEGIN
 FOR t IN SELECT tablename FROM pg_tables WHERE schemaname='site_m01' LOOP
 EXECUTE format('ALTER TABLE site_m01.%I ENABLE ROW LEVEL SECURITY',t.tablename);
 EXECUTE format('REVOKE ALL ON TABLE site_m01.%I FROM PUBLIC,anon,authenticated',t.tablename);
 END LOOP;
END $rls$;

CREATE FUNCTION site_m01.identity() RETURNS uuid LANGUAGE plpgsql SET search_path='' AS $$
DECLARE u uuid:=auth.uid(); BEGIN
 IF u IS NULL OR NOT EXISTS(SELECT 1 FROM auth.users WHERE id=u AND NOT is_anonymous) THEN RAISE EXCEPTION 'Connexion requise' USING ERRCODE='42501'; END IF;
 RETURN u;
END $$;
CREATE FUNCTION site_m01.is_admin() RETURNS boolean LANGUAGE sql SET search_path='' AS $$
 SELECT EXISTS(SELECT 1 FROM site_m01.administrators WHERE user_id=site_m01.identity())
$$;
CREATE FUNCTION site_m01.allowed(p_scope text,p_team text) RETURNS boolean LANGUAGE sql SET search_path='' AS $$
 SELECT COALESCE((SELECT enabled AND CASE p_scope WHEN 'management' THEN can_manage WHEN 'live' THEN can_live ELSE false END
 FROM site_m01.team_access WHERE user_id=site_m01.identity() AND team_id::text=p_team
 ORDER BY (origin='manual') DESC LIMIT 1),false)
$$;
CREATE FUNCTION site_m01.teams(p_scope text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb; BEGIN
 PERFORM site_m01.identity();
 IF p_scope NOT IN ('management','live') THEN RAISE EXCEPTION 'Espace invalide'; END IF;
 SELECT COALESCE(jsonb_agg(team_key),'[]') INTO result FROM
 (SELECT DISTINCT team_id::text AS team_key FROM site_m01.team_access WHERE user_id=auth.uid() AND site_m01.allowed(p_scope,team_id::text)) t;
 RETURN result;
END $$;
CREATE FUNCTION site_m01.require_access(p_scope text,p_team text) RETURNS void LANGUAGE plpgsql SET search_path='' AS $$
BEGIN
 PERFORM site_m01.identity();
 -- Verrou partagé par les mutations d'accès et les sauvegardes : révocation sérialisée.
 PERFORM pg_advisory_xact_lock(hashtextextended(auth.uid()::text,1));
 IF NOT site_m01.allowed(p_scope,p_team) THEN RAISE EXCEPTION 'Accès refusé pour cette équipe' USING ERRCODE='42501'; END IF;
END $$;

CREATE FUNCTION site_m01.project(m jsonb,p_scope text) RETURNS jsonb LANGUAGE plpgsql SET search_path='' AS $$
DECLARE cfg site_m01.model; t jsonb; local_start timestamp; rule site_m01.team_rules;
 state site_m01.match_state; result jsonb; team_key text; mid text; calendar_row jsonb; calendar_rows jsonb; effective_competition text;
BEGIN
 SELECT * INTO STRICT cfg FROM site_m01.model;
 IF cfg.scheduled_source IS NULL OR cfg.opponent IS NULL OR cfg.team_label IS NULL OR cfg.competition IS NULL THEN RAISE EXCEPTION 'Raccordement source à configurer une seule fois'; END IF;
 mid:=m->>cfg.match_pk; team_key:=m->>cfg.match_team_fk; t:=site_m01.team_row(team_key);
 IF m->>'scheduled_local_override' IS NOT NULL THEN
  IF cfg.scheduled_type='timestamp with time zone' THEN local_start:=(m->>'scheduled_local_override')::timestamptz AT TIME ZONE 'Europe/Paris';
  ELSE local_start:=(m->>'scheduled_local_override')::timestamp; END IF;
 ELSE
  -- Le mapping source désigne un timestamp local réel, validé avant activation.
  local_start:=(m->>cfg.scheduled_source)::timestamp;
 END IF;
 -- La vue réelle porte les règles MiniBasket/U18/U13/U15 : ne pas les dupliquer.
 IF cfg.public_match_id IS NULL THEN RAISE EXCEPTION 'Identifiant public non raccordé'; END IF;
 EXECUTE format('SELECT jsonb_agg(to_jsonb(v)) FROM public.public_calendar v WHERE v.%I::text=$1',cfg.public_match_id) INTO calendar_rows USING mid;
 IF COALESCE(jsonb_array_length(calendar_rows),0)>1 THEN RAISE EXCEPTION 'Identifiant public dupliqué'; END IF;
 calendar_row:=calendar_rows->0;
 effective_competition:=COALESCE(calendar_row->>'competition_label',m->>cfg.competition);
 SELECT * INTO state FROM site_m01.match_state WHERE match_id::text=mid;
 result:=jsonb_build_object('id',mid,'teamId',team_key,'teamLabel',t->>cfg.team_label,'opponent',m->>cfg.opponent,
 'date',COALESCE(calendar_row->>'local_date',to_char(local_start,'YYYY-MM-DD')),
 'time',CASE WHEN calendar_row->>'local_time' IS NULL OR calendar_row->>'local_time' IN ('','00:00','00:00:00') THEN NULL
 ELSE COALESCE(to_char(local_start,'HH24:MI:SS'),calendar_row->>'local_time') END,
 'venue',COALESCE(m->>'venue_name_override',m->>'venue_name_raw'),
 'revision',COALESCE(state.management_revision,0));
 -- Champs facultatifs uniquement s'ils existent : aucun lien ni lieu inventé.
 result:=result||jsonb_build_object('homeAway',m->>'home_away','ffbbMatchUrl',m->>'ffbb_match_url','ffbbTeamUrl',t->>'ffbb_team_url');
 IF p_scope='live' THEN
  SELECT * INTO rule FROM site_m01.team_rules WHERE team_id::text=team_key;
  result:=result||jsonb_build_object('stage',COALESCE(state.stage,0),'revision',COALESCE(state.live_revision,0),
  'competitionCode',rule.competition_code,'scorePolicy',CASE WHEN rule.source_competition=effective_competition THEN rule.score_policy ELSE NULL END);
  IF rule.score_policy='numeric' AND rule.source_competition=effective_competition AND rule.competition_code<>'DMU11-10-P2' THEN
   result:=result||jsonb_build_object('clubScore',state.club_score,'opponentScore',state.opponent_score);
  END IF;
 END IF;
 RETURN result;
END $$;
CREATE FUNCTION site_m01.list_matches(p_scope text,p_team text DEFAULT NULL,p_offset integer DEFAULT 0,p_limit integer DEFAULT 500)
RETURNS SETOF jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE cfg site_m01.model; r record;
BEGIN
 PERFORM site_m01.identity(); SELECT * INTO STRICT cfg FROM site_m01.model;
 IF p_scope NOT IN ('management','live') OR p_offset<0 OR p_limit NOT BETWEEN 1 AND 500 THEN RAISE EXCEPTION 'Requête invalide'; END IF;
 IF p_team IS NOT NULL AND NOT site_m01.allowed(p_scope,p_team) THEN RAISE EXCEPTION 'Accès refusé' USING ERRCODE='42501'; END IF;
 FOR r IN EXECUTE format('SELECT to_jsonb(m) AS row FROM public.matches m WHERE site_m01.allowed($1,m.%1$I::text) AND ($2 IS NULL OR m.%1$I::text=$2) ORDER BY m.%2$I OFFSET $3 LIMIT $4',cfg.match_team_fk,cfg.match_pk)
 USING p_scope,p_team,p_offset,p_limit LOOP RETURN NEXT site_m01.project(r.row,p_scope); END LOOP;
END $$;

CREATE FUNCTION site_m01.set_access(p_user uuid,p_team text,p_manage boolean,p_live boolean,p_enabled boolean)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE cfg site_m01.model; old_value jsonb; new_value jsonb;
BEGIN
 IF NOT site_m01.is_admin() THEN RAISE EXCEPTION 'Administration refusée' USING ERRCODE='42501'; END IF;
 SELECT * INTO STRICT cfg FROM site_m01.model;
 IF NOT cfg.access_enabled THEN RAISE EXCEPTION 'Configuration des accès désactivée' USING ERRCODE='42501'; END IF;
 IF p_manage IS NULL OR p_live IS NULL OR p_enabled IS NULL THEN RAISE EXCEPTION 'Droits explicites requis'; END IF;
 IF NOT EXISTS(SELECT 1 FROM auth.users WHERE id=p_user AND NOT is_anonymous) OR site_m01.team_row(p_team) IS NULL THEN RAISE EXCEPTION 'Utilisateur Auth ou équipe introuvable'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended(p_user::text,1));
 SELECT to_jsonb(a) INTO old_value FROM site_m01.team_access a WHERE user_id=p_user AND team_id::text=p_team AND origin='manual';
 EXECUTE format('INSERT INTO site_m01.team_access(user_id,team_id,origin,enabled,can_manage,can_live,changed_by)
 SELECT $1,t.%I,''manual'',$3,$4,$5,auth.uid() FROM public.teams t WHERE t.%I=(jsonb_populate_record(NULL::public.teams,jsonb_build_object(%L,$2))).%I
 ON CONFLICT(user_id,team_id,origin) DO UPDATE SET enabled=excluded.enabled,can_manage=excluded.can_manage,can_live=excluded.can_live,changed_by=excluded.changed_by,changed_at=clock_timestamp()',cfg.team_pk,cfg.team_pk,cfg.team_pk,cfg.team_pk)
 USING p_user,p_team,p_enabled,p_manage,p_live;
 SELECT to_jsonb(a) INTO new_value FROM site_m01.team_access a WHERE user_id=p_user AND team_id::text=p_team AND origin='manual';
 INSERT INTO site_m01.history(actor_id,operation,subject_key,before_value,after_value) VALUES(auth.uid(),'access',p_user::text||'/'||p_team,old_value,new_value);
 RETURN true;
END $$;

CREATE FUNCTION site_m01.save_management(p_id text,p_revision bigint,p_patch jsonb) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE cfg site_m01.model; m jsonb; before_value jsonb; after_value jsonb; current_revision bigint;
 date_value date; time_value time; local_start timestamp; override_value text; schedule_changed boolean; assignments text;
BEGIN
 SELECT * INTO STRICT cfg FROM site_m01.model;
 IF NOT cfg.management_enabled THEN RAISE EXCEPTION 'Écritures Gestion désactivées' USING ERRCODE='42501'; END IF;
 m:=site_m01.match_row(p_id,true);
 IF m IS NULL THEN RAISE EXCEPTION 'Rencontre introuvable' USING ERRCODE='P0002'; END IF;
 PERFORM site_m01.require_access('management',m->>cfg.match_team_fk);
 IF p_patch IS NULL OR jsonb_typeof(p_patch)<>'object' OR p_patch='{}' OR EXISTS(SELECT 1 FROM jsonb_object_keys(p_patch) k WHERE k NOT IN ('date','time','venue')) THEN RAISE EXCEPTION 'Champs Gestion invalides'; END IF;
 EXECUTE format('INSERT INTO site_m01.match_state(match_id) SELECT m.%I FROM public.matches m WHERE m.%I=(jsonb_populate_record(NULL::public.matches,jsonb_build_object(%L,$1))).%I ON CONFLICT DO NOTHING',cfg.match_pk,cfg.match_pk,cfg.match_pk,cfg.match_pk) USING p_id;
 SELECT management_revision INTO current_revision FROM site_m01.match_state WHERE match_id::text=p_id FOR UPDATE;
 IF p_revision IS NULL OR current_revision<>p_revision THEN RAISE EXCEPTION 'Version obsolète' USING ERRCODE='40001'; END IF;
 before_value:=site_m01.project(m,'management'); schedule_changed:=p_patch ?| ARRAY['date','time'];
 IF schedule_changed THEN
  IF p_patch ? 'date' AND (p_patch->>'date' IS NULL OR p_patch->>'date' !~ '^\d{4}-\d{2}-\d{2}$') THEN RAISE EXCEPTION 'Date invalide'; END IF;
  IF p_patch ? 'time' AND (p_patch->>'time' IS NULL OR p_patch->>'time' !~ '^([01][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$') THEN RAISE EXCEPTION 'Horaire invalide'; END IF;
  date_value:=COALESCE(p_patch->>'date',before_value->>'date')::date;
  time_value:=COALESCE(p_patch->>'time',before_value->>'time')::time;
  IF date_value IS NULL OR time_value IS NULL OR date_value NOT BETWEEN DATE '1900-01-01' AND DATE '2100-12-31' THEN RAISE EXCEPTION 'Date et horaire nécessaires pour une correction planifiée'; END IF;
  local_start:=date_value+time_value;
  IF cfg.scheduled_type='timestamp with time zone' THEN
   IF ((local_start AT TIME ZONE 'Europe/Paris') AT TIME ZONE 'Europe/Paris')<>local_start THEN RAISE EXCEPTION 'Horaire inexistant au changement d’heure'; END IF;
   override_value:=(local_start AT TIME ZONE 'Europe/Paris')::text;
  ELSE override_value:=local_start::text; END IF;
 END IF;
 IF p_patch ? 'venue' AND (jsonb_typeof(p_patch->'venue')<>'string' OR p_patch->>'venue' IS NULL OR length(btrim(p_patch->>'venue')) NOT BETWEEN 1 AND 200 OR p_patch->>'venue' ~ '[[:cntrl:]]') THEN RAISE EXCEPTION 'Salle invalide'; END IF;
 -- Seulement les deux champs manuels confirmés. Aucun UPDATE client sur matches.
 assignments:=CASE WHEN schedule_changed THEN format('scheduled_local_override=$2::%s',cfg.scheduled_type) ELSE '' END;
 IF p_patch?'venue' THEN assignments:=assignments||CASE WHEN assignments<>'' THEN ', ' ELSE '' END||'venue_name_override=btrim($3)'; END IF;
 EXECUTE format('UPDATE public.matches m SET %s WHERE m.%I=(jsonb_populate_record(NULL::public.matches,jsonb_build_object(%L,$1))).%I',assignments,cfg.match_pk,cfg.match_pk,cfg.match_pk)
 USING p_id,override_value,p_patch->>'venue';
 UPDATE site_m01.match_state SET management_revision=management_revision+1 WHERE match_id::text=p_id;
 after_value:=site_m01.project(site_m01.match_row(p_id),'management');
 INSERT INTO site_m01.history(actor_id,operation,subject_key,before_value,after_value) VALUES(auth.uid(),'management',p_id,before_value,after_value);
 RETURN true;
END $$;

CREATE FUNCTION site_m01.save_live(p_id text,p_revision bigint,p_patch jsonb) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE cfg site_m01.model; m jsonb; rule site_m01.team_rules; before_value jsonb; after_value jsonb; current_revision bigint; k text;
BEGIN
 SELECT * INTO STRICT cfg FROM site_m01.model;
 IF NOT cfg.live_enabled THEN RAISE EXCEPTION 'Écritures Live désactivées' USING ERRCODE='42501'; END IF;
 m:=site_m01.match_row(p_id,true);
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

CREATE FUNCTION site_m01.audit(p_offset integer DEFAULT 0,p_limit integer DEFAULT 100) RETURNS SETOF site_m01.history
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NOT site_m01.is_admin() THEN RAISE EXCEPTION 'Historique privé' USING ERRCODE='42501'; END IF;
 IF p_offset<0 OR p_limit NOT BETWEEN 1 AND 100 THEN RAISE EXCEPTION 'Pagination invalide'; END IF;
 RETURN QUERY SELECT * FROM site_m01.history ORDER BY id DESC OFFSET p_offset LIMIT p_limit;
END $$;
CREATE FUNCTION site_m01.access_list(p_user uuid DEFAULT NULL,p_offset integer DEFAULT 0,p_limit integer DEFAULT 100)
RETURNS SETOF site_m01.team_access LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NOT site_m01.is_admin() THEN RAISE EXCEPTION 'Administration refusée' USING ERRCODE='42501'; END IF;
 IF p_offset<0 OR p_limit NOT BETWEEN 1 AND 100 THEN RAISE EXCEPTION 'Pagination invalide'; END IF;
 RETURN QUERY SELECT * FROM site_m01.team_access WHERE p_user IS NULL OR user_id=p_user ORDER BY user_id,team_id,origin OFFSET p_offset LIMIT p_limit;
END $$;
-- Relecture ciblée de la vue publique par identifiant réel, jamais par libellé.
CREATE FUNCTION site_m01.public_match(p_id text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE cfg site_m01.model; m jsonb; rows jsonb;
BEGIN
 SELECT * INTO STRICT cfg FROM site_m01.model;
 m:=site_m01.match_row(p_id);
 IF m IS NULL THEN RAISE EXCEPTION 'Rencontre introuvable'; END IF;
 PERFORM site_m01.require_access('management',m->>cfg.match_team_fk);
 IF (m->>'published') IS DISTINCT FROM 'true' OR (m->>'has_conflict') IS DISTINCT FROM 'false' OR (site_m01.team_row(m->>cfg.match_team_fk)->>'is_public') IS DISTINCT FROM 'true' THEN RAISE EXCEPTION 'Rencontre non publique : propagation non confirmée'; END IF;
 IF cfg.public_match_id IS NULL THEN RAISE EXCEPTION 'Identifiant public non raccordé'; END IF;
 EXECUTE format('SELECT jsonb_agg(jsonb_build_object(''local_date'',v.local_date,''local_time'',v.local_time,''venue_name'',v.venue_name)) FROM public.public_calendar v WHERE v.%I::text=$1',cfg.public_match_id) INTO rows USING p_id;
 IF rows IS NULL OR jsonb_array_length(rows)<>1 THEN RAISE EXCEPTION 'Propagation publique non vérifiable'; END IF;
 RETURN rows->0;
END $$;
-- Façades INVOKER publiques uniquement. Les fonctions privilégiées restent privées.
CREATE FUNCTION public.site_m01_teams(p_scope text) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT site_m01.teams(p_scope) $$;
CREATE FUNCTION public.site_m01_list(p_scope text,p_team text DEFAULT NULL,p_offset integer DEFAULT 0,p_limit integer DEFAULT 500) RETURNS SETOF jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT * FROM site_m01.list_matches(p_scope,p_team,p_offset,p_limit) $$;
CREATE FUNCTION public.site_m01_save_management(p_id text,p_revision bigint,p_patch jsonb) RETURNS boolean LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT site_m01.save_management(p_id,p_revision,p_patch) $$;
CREATE FUNCTION public.site_m01_save_live(p_id text,p_revision bigint,p_patch jsonb) RETURNS boolean LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT site_m01.save_live(p_id,p_revision,p_patch) $$;
CREATE FUNCTION public.site_m01_set_access(p_user uuid,p_team text,p_manage boolean,p_live boolean,p_enabled boolean) RETURNS boolean LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT site_m01.set_access(p_user,p_team,p_manage,p_live,p_enabled) $$;
CREATE FUNCTION public.site_m01_audit(p_offset integer DEFAULT 0,p_limit integer DEFAULT 100) RETURNS SETOF site_m01.history LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT * FROM site_m01.audit(p_offset,p_limit) $$;
CREATE FUNCTION public.site_m01_public_match(p_id text) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT site_m01.public_match(p_id) $$;
CREATE FUNCTION public.site_m01_access_list(p_user uuid DEFAULT NULL,p_offset integer DEFAULT 0,p_limit integer DEFAULT 100) RETURNS SETOF site_m01.team_access LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT * FROM site_m01.access_list(p_user,p_offset,p_limit) $$;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA site_m01 FROM PUBLIC,anon,authenticated;
GRANT USAGE ON SCHEMA site_m01 TO authenticated;
-- ACL limitée aux seules entrées ; aucun privilège direct sur tables ou helpers.
GRANT EXECUTE ON FUNCTION site_m01.teams(text),site_m01.list_matches(text,text,integer,integer),site_m01.save_management(text,bigint,jsonb),site_m01.save_live(text,bigint,jsonb),site_m01.set_access(uuid,text,boolean,boolean,boolean),site_m01.audit(integer,integer),site_m01.public_match(text),site_m01.access_list(uuid,integer,integer) TO authenticated;
DO $acl$ DECLARE f record; BEGIN
 FOR f IN SELECT signature FROM (VALUES ('public.site_m01_teams(text)'),('public.site_m01_list(text,text,integer,integer)'),('public.site_m01_save_management(text,bigint,jsonb)'),('public.site_m01_save_live(text,bigint,jsonb)'),('public.site_m01_set_access(uuid,text,boolean,boolean,boolean)'),('public.site_m01_audit(integer,integer)'),('public.site_m01_public_match(text)'),('public.site_m01_access_list(uuid,integer,integer)')) v(signature) LOOP
 EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC,anon,authenticated',f.signature);
 EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated',f.signature);
 END LOOP;
END $acl$;
-- Aucun GRANT UPDATE sur public.matches, aucune politique permissive ajoutée.



-- Composant : 01a-rls-executor.sql
-- SHA256 : 82e2b14611590f1a93bd4d646bba3d8a65ceb59f128e33cf65bb4a56916584c2
-- DURCISSEMENT OBLIGATOIRE après 01, avant toute configuration/activation.
-- Proposition NON EXÉCUTÉE en production. Aucun compte ni droit métier créé.
-- Les tables restent au propriétaire d'installation ; les fonctions privées sont
-- exécutées par un rôle distinct, sans LOGIN, SUPERUSER, BYPASSRLS ou appartenance app.

CREATE ROLE site_m01_executor NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
GRANT site_m01_executor TO CURRENT_USER;
-- Seul l'opérateur SQL propriétaire du schéma conserve cette appartenance pour
-- maintenir/arrêter les fonctions. Aucune appartenance pour les rôles applicatifs.
GRANT USAGE ON SCHEMA site_m01 TO site_m01_executor;
GRANT CREATE ON SCHEMA site_m01 TO site_m01_executor;
-- Relais SQL à corps préanalysé : résolution Auth par l'installateur à la création,
-- puis EXECUTE sous l'appelant, sans USAGE auth ni privilège de délégation requis.
-- Ne pas remplacer RETURN par un corps AS $$ ... $$ résolu à l'exécution.
DO $auth_precondition$ BEGIN
 IF NOT has_schema_privilege(current_user,'auth','USAGE') THEN
  RAISE EXCEPTION 'USAGE auth requis pour l''installateur, sans option de délégation';
 END IF;
 IF NOT has_function_privilege('site_m01_executor','auth.uid()','EXECUTE') OR NOT has_function_privilege('site_m01_executor','auth.jwt()','EXECUTE') THEN
  RAISE EXCEPTION 'EXECUTE des deux fonctions Auth requis sans délégation automatique';
 END IF;
END $auth_precondition$;
CREATE FUNCTION site_m01.auth_uid() RETURNS uuid LANGUAGE sql STABLE SECURITY INVOKER
 SET search_path='' RETURN auth.uid();
CREATE FUNCTION site_m01.auth_jwt() RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER
 SET search_path='' RETURN auth.jwt();
REVOKE ALL ON FUNCTION site_m01.auth_uid(),site_m01.auth_jwt() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION site_m01.auth_uid(),site_m01.auth_jwt() TO site_m01_executor;
-- public est nécessaire aux relations et façades ; aucune délégation Auth.
DO $public_acl$ BEGIN
 IF NOT has_schema_privilege('site_m01_executor','public','USAGE') THEN
  GRANT USAGE ON SCHEMA public TO site_m01_executor;
 END IF;
END $public_acl$;

-- Conserver les fonctions validées de 01 ; seuls leurs appels Auth changent.
DO $bind_auth$ DECLARE f record; definition text; BEGIN
 FOR f IN SELECT p.oid FROM pg_proc p WHERE p.pronamespace='site_m01'::regnamespace
  AND p.proname NOT IN ('auth_uid','auth_jwt') LOOP
  definition:=pg_get_functiondef(f.oid);
  EXECUTE replace(replace(definition,'auth.uid()','site_m01.auth_uid()'),'auth.jwt()','site_m01.auth_jwt()');
 END LOOP;
END $bind_auth$;

-- JWT signé par Auth : aucune lecture privilégiée de auth.users et aucun user_metadata.
-- L'existence des comptes cibles est contrôlée par les FK existantes vers auth.users.
CREATE OR REPLACE FUNCTION site_m01.identity() RETURNS uuid LANGUAGE plpgsql SET search_path='' AS $$
DECLARE u uuid:=site_m01.auth_uid(); BEGIN
 IF u IS NULL OR COALESCE(site_m01.auth_jwt()->>'is_anonymous','false')<>'false' THEN
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
 SELECT $1,t.%I,''manual'',$3,$4,$5,site_m01.auth_uid() FROM public.teams t WHERE t.%I=(jsonb_populate_record(NULL::public.teams,jsonb_build_object(%L,$2))).%I
 ON CONFLICT(user_id,team_id,origin) DO UPDATE SET enabled=excluded.enabled,can_manage=excluded.can_manage,can_live=excluded.can_live,changed_by=excluded.changed_by,changed_at=clock_timestamp()',cfg.team_pk,cfg.team_pk,cfg.team_pk,cfg.team_pk)
 USING p_user,p_team,p_enabled,p_manage,p_live;
 SELECT to_jsonb(a) INTO new_value FROM site_m01.team_access a WHERE user_id=p_user AND team_id::text=p_team AND origin='manual';
 INSERT INTO site_m01.history(actor_id,operation,subject_key,before_value,after_value) VALUES(site_m01.auth_uid(),'access',p_user::text||'/'||p_team,old_value,new_value);
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
 INSERT INTO site_m01.history(actor_id,operation,subject_key,before_value,after_value) VALUES(site_m01.auth_uid(),'live',p_id,before_value,after_value);
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
 USING(user_id=(SELECT site_m01.auth_uid()) OR site_m01.is_admin());
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
-- Sonde locale au rôle interne : échoue et annule le lot si une implémentation
-- Auth hébergée a une dépendance interne incompatible. Aucun JWT n'est affiché.
SET LOCAL ROLE site_m01_executor;
DO $auth_probe$ BEGIN
 PERFORM site_m01.auth_uid();
 PERFORM site_m01.auth_jwt();
END $auth_probe$;
RESET ROLE;



-- Composant : 02-configure.sql
-- SHA256 : 2405bba084f93d6604962921213f4cfc31a9ff7108e0a084dea867438945522f
-- CONFIGURATION FINALISÉE depuis la définition réelle fournie. NON EXÉCUTÉE.
-- Aucun compte, aucune habilitation et aucune règle sportive ne sont insérés.
-- Le bloc échoue et annule tout si un nom/type est absent ou incompatible.

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


-- Composant : 05-verify-installation.sql
-- SHA256 : de6265697e59d329a2f8dd8bd56c6a5c94b6912a08a3b40d2f7c4eb5481975a9
-- Contrôle bloquant EN LECTURE SEULE après 01 -> 01a -> 02.
-- À exécuter AVANT toute attribution/activation. N'ouvre aucun verrou.

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



-- Rafra�chir PostgREST seulement si toute la transaction est valid�e.
NOTIFY pgrst, 'reload schema';
COMMIT;
