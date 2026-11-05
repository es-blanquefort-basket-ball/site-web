# Intégration minimale depuis les sources officielles conservées

État du 4 novembre 2026. Aucun accès Supabase, aucun import, aucun changement de ffbb-sync, cron ou Hostinger pendant cette préparation. La piste réseau Edge est arrêtée. Les fichiers publics ne sont pas modifiés.

## Lot disponible

Consulter RAPPROCHEMENT.md : 11 candidats sans ambiguïté détectée (U13F : 1, U13M : 5, U15M : 5, U18M : 0), 7 horaires inconnus, 6 salles absentes. Candidats techniquement admissibles après contrôle du fichier conservé, mais pas encore approuvés par le club ni rapprochés avec l'état actuel de production.
Les 21 autres entrées représentent 9 groupes à arbitrer : 4 U13F et 5 U18M. Le tableau conserve tous les IDs, horaires, dates, adversaires, salles et liens disponibles. Il ne conclut pas à 21 rencontres réelles distinctes.

## Import initial : deux passages, aucune automatisation

1. Faire approuver par le club les 11 lignes du tableau (ou un sous-ensemble). Les données proviennent de la collecte officielle locale du 3 novembre ; sa provenance et son SHA-256 sont dans provenance.json. Ne pas déclarer transport_edge_verified=true : les appels Edge ont échoué. IMPORT_OFFICIEL_PHASE2.sql est un parcours distinct dont la condition est la revue humaine de cette source.
2. Après autorisation d'un aperçu SQL dans le bon projet calendrier, sauvegarder l'état concerné et la définition/droits/options de la vue actuelle. Exécuter IMPORT_OFFICIEL_PHASE2.sql avec action='preview', source_export_reviewed=false et approbations vides (état livré). Seuls des objets temporaires sont créés ; aucune donnée persistante ne change. Les 11 candidats sont préremplis. Le plan donne chaque vrai ID et son MD5 JSONB. Lire les éventuels conflits avec une ligne existante ou une ancienne clé synthétique ; ne rien écraser pour les résoudre.
3. Faire approuver les IDs et MD5 exacts du plan. Ajouter uniquement ces couples dans $approval$ et retirer du bloc $candidates$ toutes les lignes non retenues. Refaire l'aperçu. Le MD5 protège l'intégrité du candidat revu ; ce n'est pas une signature d'autorisation.
4. Seulement après validation explicite de l'application, passer action='apply' et source_export_reviewed=true. L'exécution se fait dans une transaction avec verrous et assertions. Les 57 UUID publiés doivent toujours être présents. Toutes les rencontres, tous les parents d'équipes et toutes les anciennes publications sont instantanés puis comparés intégralement : toute différence annule la transaction. Aucun UPDATE d'une rencontre existante pour changer ses données sportives. Les corrections actuelles du club et scheduled_local_override sont préservées. Les parents U13/U15 restent inchangés. U18M ne sera créé que lors d'un futur lot U18M approuvé, hors import historique automatique.
5. Si les 11 IDs sont tous nouveaux et admis : total attendu 57 → 68 (pas une promesse si l'état distant a changé). Relance identique : aucune création. Contrôler les filtres U13F/U13M/U15M, dates, salles et les 7 libellés « Horaire à confirmer ». Le code calendrier existant utilise déjà ce libellé pour local_time NULL. Les dates sont conservées dans la provenance même quand les timestamps sont NULL ; aucune heure à minuit inventée.
6. Conserver la sortie UUID/current_md5 et utiliser ../RETOUR_PHASE2.sql en mode verify pour examiner le retour du lot. Après autorisation distincte, rollback du lot uniquement s'il n'a pas changé ; une correction ultérieure fait refuser le retour automatique. Aucune suppression corrective improvisée.

La garantie de l'import porte sur sa transaction. Elle ne certifie pas les effets d'un cron historique ultérieur : ffbb-sync et son cron restent inchangés et ne doivent pas être lancés manuellement pour cette intégration.

## Actualisations ultérieures depuis de nouveaux exports

Le mécanisme prévu reste privé et manuel, similaire à ACTUALISER_MINIBASKET.sql, mais ce dernier ne doit pas être exécuté sur les rencontres phase 2 : son origine et ses clés sont propres au MiniBasket.

- Conserver chaque export officiel brut daté et son SHA-256 ; normaliser dans le format candidates existant sans inventer de colonne ni déduire un ID depuis équipe/journée. Si FBI n'expose pas l'ID web, exiger la correspondance officielle. Le format brut du prochain export n'étant pas fourni, aucun parseur FBI supposé n'est livré.
- Comparer la nouvelle collecte normalisée au dernier lot source avec comparer-exports.py. Le programme ne fait aucun appel réseau/DB et ne produit que du JSON de rapprochement. Il signale les nouveaux IDs, changements d'identité, données modifiées, ambiguïtés et absences ; une absence ne supprime jamais une rencontre.
- Pour un nouvel ID non ambigu, utiliser un nouveau lot du même import contrôlé, avec approbation. Une modification d'un ID déjà importé est refusée par l'import initial : elle ne peut pas servir de mise à jour silencieuse.
- Pour actualiser un ID existant, prévoir un aperçu privé ciblé par origine esbb_ffbb_phase2 + vrai ffbb_match_id + équipe, avec copie complète de la ligne actuelle et comparaison à source_data.candidate (source initiale), ou à la dernière source approuvée historisée. Conserver l'UUID et ne jamais toucher aux 57 UUID protégés.
- Tout champ courant différent de la dernière valeur fournisseur, ou marqué comme validé par le club, est protégé. Ne jamais modifier scheduled_local_override. Soumettre chaque différence date/heure/salle/adversaire/statut au club ; une heure retirée dans la source ne doit pas effacer une correction du club. Un changement d'identité ou une collision exige un rapprochement, pas un UPDATE automatique.
- Le futur apply d'actualisation devra exiger la ligne courante exacte revue (ou son empreinte sous verrou), les champs explicitement approuvés et le nouvel export exact. Si la ligne a changé depuis l'aperçu, refuser. Historiser avant/après et provenance ; vérifier les autres lignes/publications inchangées. Aucun cron ni fonction publique.

Cette livraison fournit le comparateur et le protocole d'actualisation ; aucun SQL d'UPDATE distant n'est livré comme prêt à appliquer avant examen d'un nouvel export et des corrections concernées. Cette limite préserve les corrections validées et ne bloque pas l'import initial.

Exemple de comparaison locale (sortie seulement, aucune base modifiée) :

```sh
python3 correction-calendriers-phase2/import-officiel/comparer-exports.py \
  correction-calendriers-phase2/import-officiel/candidats-11.json \
  /chemin/vers/nouvel-export-normalise.json
```

## Données manquantes

Uniquement celles listées dans RAPPROCHEMENT.md : statuts/IDs actifs des 9 groupes, 7 horaires et 6 salles pour compléter le lot non ambigu. Les horaires/salles inconnus peuvent rester inconnus après accord. Aucun nouveau diagnostic sync_runs nécessaire.

## Tests effectués sur cette livraison

- Vérification locale de la collecte : 32 IDs distincts correspondant exactement à leurs URL officielles, engagements/phases/poules cohérents, dates valides et conversions Europe/Paris ↔ UTC cohérentes ; 11 candidats sans issues et 21 entrées ambiguës.
- Tests du module source simulés réussis ; aucun nouvel accès FFBB.
- Script d'import officiel testé en PostgreSQL local PGlite : aperçu sans modification persistante, refus sans revue source/approbation, 57 → 59 → 57 et lot réel 57 → 68 → 57, relance idempotente, protections de toutes les anciennes lignes/équipes/publications/droits/options/vue, rollback refusé après correction du club, ambiguïtés et minuit refusés. Il s'agit de tests locaux, aucune approbation de production.
- Comparateur : export identique (11 inchangés, 21 bloqués), changements et absences vérifiés localement.

Commande SQL de test locale :

```sh
ESBB_IMPORT_SQL="$PWD/correction-calendriers-phase2/import-officiel/IMPORT_OFFICIEL_PHASE2.sql" \
/Users/laurence/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node \
correction-calendriers-phase2/tests/test-import.cjs
```

Le script d'origine APPLIQUER_PHASE2.sql conserve sa condition Edge ; ffbb-sync et ses modules partagés ne sont pas modifiés. Seul le test SQL a été adapté pour accepter un chemin de candidat SQL différent.
