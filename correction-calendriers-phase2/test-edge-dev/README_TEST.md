# Test Edge DEV — préparation du 4 novembre 2026

Sonde déployée après autorisation uniquement dans FFBB PROBE TEST. Deux appels réels le 4 novembre 2026 : probe puis preview. Voir [le bilan](resultats/BILAN_TEST_EDGE.md). Aucun secret dans ce dossier. Ne pas publier sur Hostinger.

## Vérification en lecture seule

Dashboard connecté, organisation ES BLANQUEFORT BASKET BALL :
- CLUB APPLI DEV : `hwnkoksgwmxaodpjjwze`, projet actuellement en pause.
- APPLI CLUB : `zpedbcaoxqzhnpxvntmn`, projet distinct listé dans la même organisation.
- Calendrier public : `fgswygeqstgagmipltpq`, référence de calendrier.js et du chantier précédent.

Le badge main PRODUCTION du dashboard DEV désigne sa branche principale ; les références de projets sont bien distinctes.
La pause empêche de vérifier ici les fonctions et programmations existantes. L'absence de raccordement d'une autre application à DEV n'est pas certifiée par le seul nom du projet.

## Projet isolé créé le 4 novembre 2026

Nom : FFBB PROBE TEST
Référence : `upjjbmrfmpkihkfwlhxb`
Dashboard : https://supabase.com/dashboard/project/upjjbmrfmpkihkfwlhxb
Organisation : ES BLANQUEFORT BASKET BALL, forfait FREE.
Tarif vérifié avant création : offre Free à 0 USD/mois (https://supabase.com/pricing), aucun supplément ni passage à un forfait payant proposé dans le formulaire.
Projet créé neuf, région Europe, sans intégration GitHub ni import. Data API désactivée dès la création, inutile à la sonde. Aucun cron configuré. Les trois projets existants n'ont pas été modifiés.

Déploiement autorisé et effectué via le dashboard dans ce seul projet. JWT actif ; aucun cron ni import. Résultat : HTTP 403 sur les quatre pages, deux réponses de sonde HTTP 502, zéro candidat.

## Déploiement de test, uniquement après accord explicite

Les trois sources sont copiées à l'identique depuis le correctif parent. Configuration JWT conservée. Le CLI Supabase n'était pas disponible dans le shell de cette session ; les commandes ci-dessous sont préparées, non exécutées.
Depuis ce dossier, avec le CLI officiel disponible et authentifié :

```sh
supabase functions deploy ffbb-source-probe --project-ref upjjbmrfmpkihkfwlhxb
```

Ne pas ajouter --no-verify-jwt. Aucun link, db push, migration, SQL d'application, secret métier ou cron nécessaire à cette sonde. Ne pas déployer ffbb-sync.

## Appels manuels après déploiement autorisé

Dans Edge Functions > ffbb-source-probe > Test du projet FFBB PROBE TEST, conserver une authentification JWT acceptée par la plateforme. Ne pas désactiver la vérification en cas de 401.
Méthode POST ; Content-Type: application/json ; corps successifs :

```json
{"mode":"probe"}
```

```json
{"mode":"preview"}
```

Conserver séparément les réponses complètes et les statuts HTTP. Contrôler les quatre pages U13F/U13M/U15M/U18M et toutes les fiches du preview, les erreurs et les extractions. Stopper la validation sur 403, timeout, extraction vide ou fiche incomplète. Les ambiguïtés MULTIPLE_OFFICIAL_IDS restent à arbitrer ; aucun import n'est autorisé par un succès réseau.

Ne jamais envoyer phase2_probe à l'ancienne fonction ffbb-sync de production. Aucun nouveau diagnostic sync_runs à demander. La preuve réseau Edge est obtenue : HTTP 403 sur les quatre pages pour probe et preview ; voir resultats/.

## Repli

Si DEV ne peut être réactivé ou si son usage est incompatible, proposer un projet Supabase dédié vide pour cette seule sonde, après validation de sa création et du déploiement. Pas de copie de données du club. Un test local ne remplace pas un appel depuis Supabase.
