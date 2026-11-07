-- RETOUR EN MODE LECTURE / ARRÊT : proposition uniquement, non exécutée.
-- Préserve les corrections métier, habilitations et historique pour diagnostic.
BEGIN;
UPDATE site_m01.model SET management_enabled=false,live_enabled=false,access_enabled=false;
REVOKE EXECUTE ON FUNCTION public.site_m01_save_management(text,bigint,jsonb),
 public.site_m01_save_live(text,bigint,jsonb),
 public.site_m01_set_access(uuid,text,boolean,boolean,boolean)
 FROM PUBLIC,anon,authenticated;
-- Les entrées privées correspondantes sont également fermées.
REVOKE EXECUTE ON FUNCTION site_m01.save_management(text,bigint,jsonb),
 site_m01.save_live(text,bigint,jsonb),
 site_m01.set_access(uuid,text,boolean,boolean,boolean)
 FROM PUBLIC,anon,authenticated;
COMMIT;
-- La vue d'origine est conservée dans site_m01.view_backup. Pour la restaurer,
-- préparer CREATE OR REPLACE VIEW depuis cette définition et vérifier qu'aucune
-- modification ultérieure de la vue ne serait écrasée. Ne pas supprimer l'historique.
