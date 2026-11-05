# Test réel Edge Supabase — 4 novembre 2026

Projet exclusif : FFBB PROBE TEST (`upjjbmrfmpkihkfwlhxb`).
Sonde ffbb-source-probe déployée via le dashboard avec index.ts, ../_shared/phase2-core.mjs et ../_shared/targets.mjs. Les trois contenus saisis ont été comparés intégralement aux sources locales : identiques.
JWT de plateforme actif avant et après les appels : Verify JWT with legacy secret = ON. Aucune erreur 401 observée.

| Équipe | HTTP FFBB probe | HTTP FFBB preview | Liens de fiches | Candidats |
| --- | --- | --- | --- | --- |
| U13F | 403 | 403 | 0 | 0 |
| U13M | 403 | 403 | 0 | 0 |
| U15M | 403 | 403 | 0 | 0 |
| U18M | 403 | 403 | 0 | 0 |

Deux POST manuels via Dashboard > Test, probe puis preview. Les deux réponses de sonde sont HTTP 502, success=false, status=error, failed_teams=4, production_write=false. Chaque équipe porte FFBB_HTTP_403.

Zéro rencontre récupérée. Les pages d'équipes sont refusées avant extraction : aucune fiche individuelle n'a pu être appelée par ce parcours. Leur accès depuis Supabase reste non vérifié. Dates, horaires connus/inconnus, identifiants de rencontres et ambiguïtés : non évaluables, faute de candidats. L'absence de candidats ne prouve pas l'absence d'ambiguïtés. Aucun résultat local antérieur n'est substitué à ces mesures Edge.

Le champ execution_environment=not_attested est une constante de la sonde, conservée telle quelle. La provenance Supabase est établie par le déploiement et les réponses du panneau Test du projet indiqué, et non par ce champ.

Revue complète du code : aucun client Supabase, secret, SQL, appel REST DB, insert/update/upsert/delete/rpc. Seules requêtes : lectures HTTP bornées vers competitions.ffbb.com, redirections validées. Aucun script des pages exécuté. Aucune écriture applicative en base ou dans un journal DB ; seuls les journaux techniques normaux de la plateforme accompagnent le déploiement et les invocations.

Aucun cron, import, publication Hostinger ou changement des trois autres projets. Aucune nouvelle modification de production préparée.

Conclusion : récupération bloquée depuis ce projet Supabase par HTTP 403 sur les quatre calendriers. La synchronisation n'est pas réparée. Aucune relance supplémentaire ni contournement effectué. Prochaine voie à valider : export FFBB autorisé avec vrais identifiants et URL officiels, ou accès officiel autorisé depuis Supabase.

Preuves : probe.json, preview.json (réponses brutes enveloppées avec référence du projet, transport observé et statut HTTP), preview-dashboard.jpg, jwt-actif.jpg.
