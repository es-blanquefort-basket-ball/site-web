// Valeurs publiques existantes. Aucun secret et aucune liste d’adresses ici.
export const config = Object.freeze({
  url: 'https://fgswygeqstgagmipltpq.supabase.co',
  key: 'sb_publishable_dsoHXhS222GToiMUIpGkCA_lFPAJm-A',
  // RPC finalisées depuis le snapshot réel. Installation/activation distinctes :
  // voir validation/site-m01/ACTIVATION.md. Aucun basculement automatique.
  binding: Object.freeze({ protocol: 'site-m01-rpc' }),
  // Passer à true seulement après installation validée et configuration serveur.
  backendReady: false,
  // Le verrou ne remplace pas RLS. Activation après validation humaine des écritures.
  writesApproved: false,
  liveWritesApproved: false,
  accessWritesApproved: false
});
