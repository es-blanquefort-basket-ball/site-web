-- Une seule lecture de métadonnées pour finaliser les correspondances et le patch.
-- Aucun accès aux comptes, habilitations personnelles ou lignes sportives.
SELECT jsonb_build_object(
 'columns',(SELECT jsonb_agg(jsonb_build_object('table',table_name,'column',column_name,'type',data_type) ORDER BY table_name,ordinal_position)
 FROM information_schema.columns WHERE table_schema='public' AND table_name IN ('matches','teams','public_calendar')),
 'constraints',(SELECT jsonb_agg(pg_get_constraintdef(oid,true)) FROM pg_constraint WHERE conrelid IN ('public.matches'::regclass,'public.teams'::regclass)),
 'calendar_definition',pg_get_viewdef('public.public_calendar'::regclass,true),
 'calendar_options',(SELECT reloptions FROM pg_class WHERE oid='public.public_calendar'::regclass),
 'policies',(SELECT jsonb_agg(to_jsonb(p)) FROM pg_policies p WHERE schemaname='public' AND tablename IN ('matches','teams'))
) AS site_m01_schema;
