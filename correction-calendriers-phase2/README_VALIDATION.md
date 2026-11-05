# Correction locale des calendriers U13F / U13M / U15M / U18M

Préparée le 3 novembre 2026. **Aucun déploiement, aucune écriture Supabase, aucun appel au ffbb-sync de production, aucun changement du cron ni publication Hostinger.** Les deux scripts SQL d’application et de retour restent sur un mode sans écriture par défaut. Les fichiers publics et les scripts MiniBasket existants ne sont pas modifiés par ce correctif.

## État réel

Les résultats de `sync_runs` transmis par le club sont acquis dans `sync-runs-confirmes.json` : 33 rencontres correctement synchronisées le 28 septembre, premières erreurs 403 le 30 septembre, puis cinq équipes en 403 et zéro rencontre le 23 octobre malgré le statut success. Aucun nouveau diagnostic de ces logs n'est demandé.

**L'accès depuis l'infrastructure Supabase n'est pas encore prouvé.** Les mesures réelles effectuées ici sont des lectures HTTP depuis ce Mac avec les mêmes en-têtes FFBB que le candidat, pas des appels depuis une Edge Function. Le code ne contourne pas un HTTP 403 et ne prétend pas le résoudre en changeant d'URL ou de User-Agent.

- Quatre pages d'équipes : HTTP 200, liens de matchs trouvés 9 / 5 / 5 / 13.
- Preview réel local : 32 fiches individuelles lues, toutes HTTP 200 et correctement extraites après adaptation au HTML serveur diffusé par fragments. Pas de navigateur ni de JavaScript de page exécuté par le parseur.
- 21 entrées signalées `MULTIPLE_OFFICIAL_IDS`, non admissibles à l'application automatique ; elles ne sont pas fusionnées ni choisies par ordre d'arrivée. Les 32 fiches ne constituent donc pas 32 rencontres approuvées.
- 13 entrées sans heure : date conservée, `local_time=NULL`, aucun timestamp à minuit fabriqué.
- Résultats exacts : `resultat-acces-local.json`, `resultat-preview-local.json`. Les aperçus sont des données publiques sportives, sans téléphone, licence, coordonnées de licencié ni score collecté.

## Fichiers techniques

| Fichier | Rôle |
| --- | --- |
| `_shared/targets.mjs` | Quatre engagements phase 2 avec vrais IDs équipe, phase, poule et URL vérifiées. |
| `_shared/phase2-core.mjs` | Transport HTTP borné, extraction des vrais IDs dans les liens, lecture indépendante de chaque fiche, vérification phase/poule/club, dates Europe/Paris et UTC, détection des ambiguïtés, aucun client DB. |
| `ffbb-source-probe/index.ts` | Sonde autonome sans client Supabase : modes probe/preview, aucune écriture de données ou de logs DB. À déployer d'abord dans un projet non productif après validation. |
| `ffbb-sync/index.ts` | Candidat local basé sur l'export existant. Ajoute `phase2_probe` / `phase2_preview` avant toute écriture de journal. Corrige les faux succès des 403/extractions vides et bloque le traitement des nouveaux engagements par l'ancien algorithme à clés de journée. |
| `ffbb-sync.patch` | Diff de revue du candidat contre l'export original, non appliqué à une fonction distante. Les modules partagés doivent aussi être livrés. |
| `APPLIQUER_PHASE2.sql` | Aperçu par défaut ; application uniquement de candidats revus et d'une liste d'approbation MD5 exacte, après validation du transport Edge. |
| `RETOUR_PHASE2.sql` | Vérification par défaut ; retour arrière des seuls nouveaux UUID explicitement listés, refus si données ou vue modifiées depuis l'import. |
| `tests/` | Tests HTTP/parser/contrôleur simulés et PostgreSQL local avec les contraintes connues. |
| `tester-acces.cjs` | Test HTTP réel local, sans client Supabase, sans invocation distante de fonction et sans écriture DB. |

## Principe de raccordement et préservation des 57

Le mode phase 2 utilise `_shared/targets.mjs` pour résoudre l'engagement FFBB et le code public stable. Il ne dépend pas du champ historique `teams.ffbb_team_id` pour déterminer l'engagement de novembre. Lors de l'application, le code public résout le même `teams.id` interne.

Les trois parents U13/U15 sont volontairement conservés à l'identique : remplacer leur libellé de compétition ou leur URL globale pourrait modifier l'affichage historique des 57 publications. Les nouveaux matchs portent leur engagement et leur URL dans leur provenance, et leur compétition dans `matches.competition_name`. Leur branche de la vue expose ces informations par rencontre, avec les vrais `id`, `team_name`, `competition_label`, `starts_local`, `status`, `updated_at`, liens et salle.

U18M est créé uniquement si un candidat U18M approuvé est appliqué. Il est public, avec son vrai ID FFBB, et `is_competition_active=false` pour ne pas l'envoyer dans l'ancien import à clés synthétiques. Cette désactivation du chemin historique n'empêche ni le preview phase 2 explicite ni l'affichage des matchs publiés. Toute activation d'une automatisation nouvelle sera une décision séparée.

Les 57 UUID de référence sont inscrits dans le SQL. Sous verrou, l'import prend en plus un instantané de toutes les lignes existantes, des équipes et de toute la vue publique. Il ne les met pas à jour. Les assertions comparent leurs valeurs complètes après application et annulent toute la transaction en cas de changement. La vue conserve son OID, ses options et ses droits. Sa branche existante, incluant MiniBasket, est réutilisée intégralement ; la substitution des nouvelles lignes se fait exclusivement par `matches.id`.

L'identité des nouvelles rencontres est le vrai nombre final de l'URL `/match/ID`, jamais équipe/journée ou date/adversaire. Une ancienne clé synthétique portant déjà la même URL fait arrêter l'import pour rapprochement manuel. Les regroupements par date/adversaire ne servent qu'à signaler des ambiguïtés, jamais à fusionner des identités.

Les champs `scheduled_local_ffbb` et les champs UTC des nouvelles lignes sont alimentés de façon cohérente. Une heure inconnue conserve la date en JSONB sans inventer de timestamp. Les anciens overrides ne sont pas modifiés. Une relance identique ne crée rien ; un changement de candidat pour une rencontre déjà importée est soumis à un nouveau contrôle et n'écrase rien automatiquement.

Le chemin historique sans mode reste celui de l'export pour les équipes historiques, avec des journaux corrigés. Il peut, comme auparavant, mettre à jour les anciennes lignes lors d'un véritable run. **Ne pas le lancer pour tester ce chantier ni pour importer les nouveaux engagements.** Les garanties de conservation des 57 concernent l'application contrôlée fournie, pas l'arrêt des effets d'un cron déjà existant. Les nouveaux engagements connus sont exclus de ce chemin à clés de journée, même si leurs champs sont ultérieurement activés dans teams.

## Tests effectués

Tests simulés, sans connexion DB distante :

```sh
node correction-calendriers-phase2/tests/test-core.cjs
node correction-calendriers-phase2/tests/test-import.cjs
```

Le Node fourni par Codex se trouve dans `/Users/laurence/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node`. Le chargeur de test utilise `ESBB_TEST_DEPS`, par défaut `/private/tmp/esbb-sql-validation`, où sont installés `linkedom@0.18.12`, `luxon@3.7.2` et `@electric-sql/pglite@0.5.14`. Pour réinstaller les tests hors du cache temporaire, installer les dépendances épinglées de `tests/package.json` dans `tests/` ; le chargeur détecte ces dépendances locales automatiquement. Il réécrit seulement les imports `npm:` pour Node ; les fonctions testées sont celles du module partagé. Le contrôleur utilise un client Supabase simulé. Le SDK distant et le bundle hébergé n'ont pas été exécutés.

Cas validés :

- Vrai ID, phase/poule incohérente refusée, deux IDs semblables conservés et signalés.
- HTML serveur à plusieurs racines et contenu diffusé hors du main ; aucun script de page exécuté.
- Heure connue / inconnue, conversion hiver Europe/Paris ↔ UTC, date conservée, exclusion des données de téléphone.
- HTTP 403 global, partiel ou sur une fiche, shell HTTP 200 sans calendrier, redirection hors FFBB et requête invalide.
- Cinq équipes en HTTP 403 : log simulé `error`, réponse `success=false`, HTTP 502, aucune écriture de match.
- Modes probe/preview sans écriture du journal ou des matchs ; point d'entrée Deno de la sonde simulé.
- Refus SQL sans preuve de transport Edge ou sans approbation exacte ; refus des ambiguïtés et de 00:00.
- Base locale : 57 → 59 → 57 ; relance strictement identique ; conservation de toutes les anciennes lignes, de leurs publications, de leurs parents, des droits/options et de la définition de vue après retour arrière complet.
- Correction club postérieure : retour arrière refusé, aucune donnée modifiée détruite.
- Données HTTP réelles injectées uniquement dans la base simulée : 11 candidats non ambigus, 57 → 68 → 57, préservation complète des 57 publications. Ces candidats ne sont pas approuvés pour la production par ce test.

Les deux rencontres supplémentaires des tests SQL sont des fixtures simulées, pas des rencontres approuvées pour Supabase. Les aperçus HTTP réels restent dans les fichiers de résultat, pas dans les blocs d'entrée des SQL. `git diff --check` réussi. Aucun changement visuel, donc aucun nouveau test responsive requis pour ces fichiers serveur.

## Validation avant déploiement : actions précises

1. **Revue du code et sauvegarde de la version distante actuellement déployée.** Comparer avec l'export d'origine avant toute substitution ; le diff fourni ne prouve pas que la production est encore identique à cet export. Conserver le payload et la programmation du cron ; tester sa compatibilité sans les changer.
2. **Test Edge non productif.** Copier les répertoires `_shared/` et `ffbb-source-probe/` sous `supabase/functions/` d'un projet non productif. Conserver l'authentification/JWT de la plateforme. Après autorisation de ce déploiement de test, appeler la sonde avec `{"mode":"probe"}`, puis `{"mode":"preview"}`. Vérifier les quatre pages ET toutes les fiches, les codes HTTP et les motifs d'échec. Ne rien appliquer sur un 403, timeout, extraction vide ou fiche incomplète. Les tests Node et navigateur ne remplacent pas cette preuve réseau depuis Supabase.
3. **Validation des identités actives.** Arbitrer les 21 entrées U13F/U18M signalées avant de préparer leur publication. Ne pas effacer les issues pour contourner le contrôle. Les candidats non ambigus peuvent être sélectionnés séparément après contrôle du club.
4. **Autorisation de production distincte.** Après accord, déployer le candidat et les modules partagés, sans toucher au cron. Avant tout import, refaire probe/preview depuis le projet de production. **Ne jamais envoyer `phase2_probe` à l'ancienne fonction déployée : elle ignore ce paramètre et écrirait en base.** Utiliser auparavant uniquement la sonde autonome non productive.
5. **Application contrôlée, seulement après ces validations.** Copier dans `$candidates$` uniquement les JSON complets validés du preview, laisser d'abord `action='preview'` et lire les empreintes/résultats. Reporter les identifiants et MD5 approuvés dans `$approval$`. `transport_edge_verified=true` atteste manuellement la preuve réellement obtenue, pas un simple succès local. Autoriser ensuite seulement `action='apply'`. Les SQL fournis restent livrés vides, avec leurs modes sans écriture.
6. **Contrôle puis annulation éventuelle.** Vérifier les quatre filtres, les dates, les horaires inconnus, les salles et la comparaison des 57 publications. Conserver la sortie privée UUID/current_md5. Pour annuler le lot complet non modifié, la fournir à `RETOUR_PHASE2.sql` et faire vérifier le plan avant de sélectionner `rollback`. Une actualisation ou modification ultérieure fait refuser ce retour automatique.

Si les 403 persistent depuis Supabase, la synchronisation automatique n'est pas réparée : ne pas augmenter les tentatives, ne pas introduire de contournement de protection et ne pas modifier le cron. Le repli est un export autorisé avec IDs/URL officiels ou rapprochement contrôlé ; un numéro de journée n'est pas un ID FFBB.

Références techniques : [environnement et runtime Edge Supabase](https://supabase.com/docs/guides/functions/development-environment), [parseur LinkeDOM](https://github.com/WebReflection/linkedom). Aucun code de site public ou service supplémentaire n'est déployé par ce dossier.
