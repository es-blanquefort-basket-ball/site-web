# SITE-M01 — Interface V1 isolée

Branche : `codex/site-m01-interface-matchs`, depuis `main` propre à jour avec origin.
Fetch et pull fast-forward effectués ; aucun fichier existant modifié. Aucun merge ni déploiement.
Maquette V3 introuvable dans la recherche ciblée incluant les fichiers cachés/non suivis du dépôt.

## Tester maintenant

Depuis la racine :

```sh
python3 validation/site-m01/preview.py
```

Ouvrir http://127.0.0.1:8872/app/gestion-matchs.html.

- Compte fictif autorisé : `autorise@example.test`, code `123456`.
- Compte fictif refusé : `refuse@example.test`, code `123456`.
- Un autre code provoque un refus.
- Les rencontres, salles et identifiants sont explicitement fictifs. Aucun e-mail envoyé.
- Liste par semaine (lundi à dimanche, titre au samedi), filtre par identifiant d’équipe,
  ouverture d’une rencontre, date/heure/salle, récapitulatif, case de confirmation,
  annulation, déconnexion et refus d’enregistrement sont testables.
- Le serveur d’aperçu utilise les mêmes HTML/CSS/JS que la page livrée ; il remplace
  uniquement sa configuration en mémoire et les réponses réseau. Aucun appel Supabase.
- Aucun score affiché, y compris U11 M2 et U9. La gestion des résultats est reportée.
- Ne pas publier `validation/` sur Hostinger.

Tests automatisés (Node moderne, aucune installation nécessaire) :

```sh
node validation/site-m01/tests.mjs
```

## Fichiers livrés

- `app/gestion-matchs.html` : page privée sans nouvelle entrée de menu public.
- `app/gestion-matchs.css` : compléments locaux aux composants de `style.css` ; isolation
  pour ne pas modifier les styles communs du chantier calendrier/U11.
- `app/gestion-matchs.js` : interactions, états, sélection et confirmation explicite.
- `app/gestion-matchs-core.js` : validation, regroupement et adaptateur REST/Auth.
- `app/gestion-matchs-config.js` : URL et clé publishable existantes, raccordement nul,
  écritures verrouillées.
- `validation/site-m01/verification.sql` : uniquement requêtes de lecture nécessaires.
- `validation/site-m01/tests.mjs`, `preview.py` et le présent compte rendu.

## Raccordements réellement effectués

Le client utilise l’URL du projet existant et sa clé publishable publique.
Les appels Supabase Auth sont implémentés : `/auth/v1/otp` avec `create_user:false`,
`/auth/v1/verify` en mode e-mail, `/auth/v1/user`, et `/auth/v1/logout`.
Le jeton reste uniquement en mémoire, sans stockage persistant ni journalisation.
Après expiration il faut se reconnecter ; aucune création automatique de compte.
Aucune identité de correcteur n’est publiée.

L’envoi et la réception réels d’un code **n’ont pas été testés**. Il faut vérifier dans
Supabase Auth que le fournisseur e-mail est actif, que le compte existe et que le modèle
Magic Link contient `{{ .Token }}` pour envoyer un code. Référence officielle :
https://supabase.com/docs/guides/auth/auth-email-passwordless.
La documentation et le changelog ont été consultés ; aucun changement Flutter/CLI
mentionné dans le changelog ne concerne le client REST natif utilisé ici.

Le connecteur Supabase a refusé les lectures de métadonnées (`execute_sql`, `list_tables`).
L’endpoint OpenAPI public exige une clé secrète ; aucune clé secrète n’a été recherchée
ou ajoutée au navigateur. Aucun nom de champ manuel n’est donc supposé.

## Ce qui reste bloqué par Supabase

La page réelle ne charge pas de rencontres tant que `binding` reste nul. Après connexion,
elle affiche explicitement que le raccordement des données/droits est en attente.
Aucune réussite en base n’est simulée dans l’application livrée.

Exécuter `verification.sql` dans le SQL Editor du projet `fgswygeqstgagmipltpq`,
puis examiner les résultats avant de renseigner le contrat suivant :

| Propriété de binding | Vérification requise |
| --- | --- |
| `readTable` | Relation existante accessible aux seuls gestionnaires, avec valeurs effectives date/heure/salle |
| `read.id` | Identifiant stable réel de `matches`, jamais un index ni un libellé |
| `read.teamId` | Identifiant de relation équipe, jamais une déduction du nom |
| `read.teamLabel`, `read.opponent` | Colonnes existantes d’affichage |
| `read.date`, `read.time`, `read.venue` | Valeurs effectives tenant compte de la priorité manuelle |
| `read.homeAway` | Valeur actuelle, avec convention home/away à vérifier |
| `read.ffbbMatchUrl`, `read.ffbbTeamUrl` | Liens FFBB existants, si disponibles |
| `accessRpc` | Fonction existante sans argument renvoyant un booléen fondé sur auth.uid() et les droits en base |
| `matchId`, `publicId` | Colonnes permettant de relire exactement le même match en privé et dans public_calendar |
| `manual.date`, `manual.time`, `manual.venue` | Uniquement les champs manuels réellement prévus dans matches |

Ce contrat est interne au navigateur, pas une proposition de nouveaux noms SQL.
Si la structure existante ne correspond pas (jointure équipe nécessaire, correction via
un autre mécanisme, absence de RPC existante), adapter l’adaptateur aux résultats vérifiés ;
ne pas créer de vue, fonction, table ou politique pour satisfaire ce contrat sans validation.
Les tests utilisent des noms TEST_ONLY qui ne doivent jamais être reportés en production.

Contrôler RLS SELECT et UPDATE, les prédicats d’autorisation réels, WITH CHECK et les
privilèges de colonnes. Une simple session authenticated ou une adresse saisie ne donne
aucun droit de correction. La RPC de précontrôle ne remplace pas RLS sur chaque opération.
Vérifier aussi la relation d’autorisation référencée par les politiques si nécessaire,
sans exporter les adresses ou auth.users.

Confirmer U11 M1 = DMU11-4-P2 et U11 M2 = DMU11-10-P2 par relation réelle, puis
renseigner les libellés vérifiés. Aucune rencontre n’est réaffectée par le client.

Conserver `writesApproved:false` jusqu’à vérification du schéma, contrôle des droits et
validation humaine d’un environnement d’écriture. Le code de sauvegarde est préparé mais
non activé : PATCH limité aux seuls champs manuels modifiés, vérification d’une seule ligne,
relecture de public_calendar par identifiant et rechargement de la liste privée.
Aucun enregistrement ni contrôle de propagation réel n’a été exécuté.

## Vérifications exécutées

- 15 contrôles automatisés locaux réussis avec transport factice : absence de session,
  compte refusé, identifiants, filtrage U11/U9, regroupement des dates, champs invalides,
  champs inconnus inchangés, liens sûrs, verrou sans réseau, payload manuel restreint,
  zéro ligne autorisée, propagation manquante, HTTP 403, schéma absent, déconnexion.
- Navigateur sur aperçu fictif : connexion, liste de quatre rencontres, filtre U11 M2
  excluant M1/U9, formulaire portant TEST-M2, récapitulatif, confirmation obligatoire,
  refus d’écriture même après confirmation, annulation et compte non autorisé.
- Largeurs 390, 820 et 1280 pixels : largeur du document égale à celle du viewport,
  formulaire et composants adaptatifs ; capture de l’aperçu conservée hors dépôt.
- Syntaxe Python et chemins des ressources HTML vérifiés.
- Test historique `validation/calendrier-horaires.cjs` tenté : son contexte factice
  est incompatible avec le calendrier actuel (URLSearchParams absent, puis setAttribute
  absent après complément du contexte). Aucun fichier de ce chantier corrigé.
- Non-régression du calendrier : fichiers publics, styles communs, équipes et données
  strictement inchangés. Pas de validation navigateur du calendrier en production.
- Aucune écriture Supabase, aucun envoi d’e-mail réel, aucune migration, aucun déploiement.

## V2

Modification domicile/extérieur, résultats et historique privé auteur/date/avant/après.
Aucune colonne de résultats ou d’historique supposée ni créée. Les règles sans scores
publics pour U11 M2 et U9 restent à contrôler lors de leur raccordement futur.

---

# V2 — Suivi Live (7 novembre 2026)

La V1 a été conservée au commit `0552f5d` sur `codex/site-m01-interface-matchs`.
La V2 part de ce commit sur `codex/site-m01-suivi-live`. Aucun changement des fichiers
publics, aucune fusion dans main et aucun déploiement. Le compte rendu V1 ci-dessus
reste l’historique de sa livraison ; les indications V2 ci-dessous le complètent.

## Essai local V2

La commande `python3 validation/site-m01/preview.py` reste identique.
Ouvrir http://127.0.0.1:8872/app/gestion-matchs.html et utiliser le code fictif `123456`.

| Compte fictif | Gestion | Live |
| --- | --- | --- |
| autorise@example.test | Toutes les rencontres de test | Toutes les équipes de test |
| gestion@example.test | Oui | Non |
| live@example.test | Non | U11 M1 de test uniquement |
| mini@example.test | Non | U11 M2 et U9 de test uniquement |
| refuse@example.test | Non | Non |

L’aperçu sauvegarde le Live **uniquement en mémoire du serveur local**. Un redémarrage
réinitialise les étapes et les scores. La configuration temporaire est générée par ce
serveur et pointe exclusivement vers 127.0.0.1 ; elle n’est pas inscrite dans les fichiers
applicatifs. Les corrections organisationnelles restent verrouillées, même en simulation.
Aucun envoi d’e-mail réel ni appel Supabase dans cet aperçu.

## Comportements livrés

Une porte d’entrée et une connexion, deux espaces accessibles selon des droits séparés.
Les commandes de gestion V1 sont conservées. Un référent Live ne charge pas les données
de gestion. Les rencontres Live sont demandées par identifiant d’équipe autorisé ; une
réponse contenant une autre équipe est refusée. La sauvegarde revérifie l’identité et
les droits avant chaque opération. Ces contrôles clients ne remplacent pas les RLS.

Le Live présente les sept étapes validées, avec précédent/suivant et bornes. Un clic
sauvegarde uniquement l’étape ; il ne requiert ni ne modifie le score. Le score facultatif
peut être corrigé, ou effacé pour redevenir inconnu, à toute étape. Il s’enregistre avec
une commande distincte. Un score saisi mais non enregistré reste indiqué comme tel,
y compris lorsqu’une étape est sauvegardée. Une confirmation protège l’abandon du brouillon.

La règle `scorePolicy` est un contrat de l’adaptateur alimenté par la règle réelle de
chaque équipe, jamais inférée d’un nom ressemblant ou d’une catégorie. Seule la valeur
explicite `numeric` permet les champs de score ; DMU11-10-P2 reste bloqué même si cette
valeur était reçue par erreur. Les règles U9 et MiniBasket sont sans score. La simulation
applique ces interdictions aussi côté serveur et retire les scores de ses réponses.
Le résultat FFBB n’est ni lu ni modifié par le suivi Live.

La fonction `publicLive()` prépare une projection limitée aux identifiants, équipe,
adversaire, étape et scores autorisés. Elle exclut les identités et tout score interdit.
**Ce n’est pas une protection d’une API publique** : avant la future page publique, la
base devra produire cette projection sûre elle-même. Aucune page Live publique, aucun
lien partageable et aucun abonnement Realtime n’ont été publiés ou activés.

## Adaptations Supabase à vérifier

`binding` reste nul dans le fichier applicatif, `writesApproved:false` et
`liveWritesApproved:false`. L’OTP réel et les RLS ne sont toujours pas validés.
Aucune nouvelle tentative d’écriture ni création de table/politique/fonction.

Les requêtes 7 à 9 de `verification.sql` ajoutent seulement la lecture ciblée des colonnes,
politiques et fonctions Live existantes. Avec les résultats des requêtes V1, elles serviront
à identifier la relation réelle entre utilisateurs et équipes, ainsi que les mécanismes
existants de statut/score. Aucune migration DDL n’est proposée : la nécessité d’une nouvelle
table ou colonne ne peut pas être établie sans ces résultats. Préparer une migration à
ce stade supposerait les types, clés et politiques, ce que la mission interdit.

Contrat interne supplémentaire à raccorder aux éléments existants vérifiés :

| Propriété `binding.live` | Contrat attendu après vérification |
| --- | --- |
| `accessRpc` | Fonction existante sans argument, fondée sur auth.uid(), renvoyant les identifiants réels des équipes autorisées, tableau vide sinon |
| `readTable` | Relation privée existante, RLS limitée aux équipes autorisées, une ligne par identifiant réel de rencontre |
| `read` | Correspondance des champs d’affichage V1, plus stage, clubScore, opponentScore, scorePolicy, competitionCode et revision |
| `stage` dans les lignes normalisées | Entier 0 à 6 ; adapter les statuts SQL réels si leur représentation diffère |
| `scorePolicy` dans les lignes normalisées | Règle d’équipe validée : numeric, minibasket-no-score, u9-no-score ; une règle inconnue interdit le score |
| `revision` dans les lignes normalisées | Version non nulle permettant un contrôle atomique des modifications concurrentes |
| `saveRpc` | Fonction atomique vérifiée : identité, équipe, règle de score, version, champs Live exclusivement ; réponse true après écriture effective |
| `args.id`, `args.revision`, `args.patch` | Correspondance aux noms réels des arguments SQL, jamais des noms déduits |

Les noms TEST_ONLY du serveur local sont fictifs et ne doivent pas être créés en production.
Si aucune fonction existante ne satisfait ce contrat, adapter l’adaptateur au schéma vérifié
ou préparer ensuite une migration minimale pour validation, sans l’exécuter.
La RPC Live doit refuser les champs organisationnels et les résultats officiels, protéger
contre les conflits de version, empêcher tout score U9/MiniBasket et ne jamais accorder
implicitement les droits de gestion. Pour la future lecture publique, supprimer les identités
et les scores interdits côté SQL/API, avant transmission au navigateur.

La sauvegarde réelle préparée requiert un retour positif, puis une relecture concordante ;
aucune mise à jour optimiste n’est présentée comme enregistrée. Les erreurs 403, 404, 409,
le réseau indisponible et les réponses non confirmées sont signalés. Aucun test de sauvegarde
ou de propagation Supabase réel n’a été exécuté.

## Tests V2 exécutés

- 15 contrôles V1 : tous réussis avec transport fictif, après les changements Live.
- 21 contrôles Live : tous réussis (sept étapes, retour, indépendance score/étape,
  champs facultatifs, corrections, valeurs invalides, politiques équipe, projection,
  authentification, équipes autorisées, écriture verrouillée, refus, versions et relecture).
- 13 contrôles HTTP contre le serveur local : tous réussis. Ils vérifient des refus
  directement côté serveur de simulation, y compris en contournant l’interface.
- Navigateur : compte live@example.test sans gestion et avec M1 seul ; étape sans score,
  score 12–10 sauvegardé en mémoire, étape suivante puis précédente conservant ce score ;
  correction à 11–10 sans changement d’étape. Compte mini@example.test : M2/U9 sans champs
  de score et changement d’étape M2 réussi. Compte autorise : récapitulatif gestion V1,
  annulation, bascule Gestion/Live.
- Téléphone 390 px, tablette 820 px et ordinateur 1280 px : largeur du document égale
  au viewport ; saisie et sauvegarde du score testées sur téléphone. Console navigateur
  sans erreur au contrôle final. Capture mobile conservée hors dépôt.
- Syntaxe Python, chemins locaux, différences Git et absence de changement des fichiers
  calendrier/U11 contrôlés. Aucun test en production.

Reproduire les tests :

```sh
node validation/site-m01/tests.mjs
node validation/site-m01/tests-live.mjs
# Avec le serveur de simulation démarré :
python3 validation/site-m01/tests-preview.py
```

## Fichiers V2

Modifiés : `app/gestion-matchs.html`, `.css`, `.js`, `gestion-matchs-core.js`,
`gestion-matchs-config.js`, `validation/site-m01/preview.py`, `verification.sql`, `LIVRAISON.md`.
Ajoutés : `app/gestion-matchs-live.js`, `app/gestion-matchs-live-ui.js`,
`validation/site-m01/tests-live.mjs`, `validation/site-m01/tests-preview.py`.
Le fichier de tests V1 est conservé sans modification.

---

# Préparation du raccordement réel et accès mixtes — 7 novembre 2026

Branche `codex/site-m01-raccordement-acces` créée depuis la V2 `bbcbbbe`.
V1 et V2 conservées dans l’historique. Le fichier local `.DS_Store` préexistant est laissé
intact et n’est pas inclus dans les changements.

## Ce qui est préparé

Le client possède maintenant un adaptateur RPC concret pour la proposition SQL fournie.
L’interface et le fonctionnement Live ne changent pas. Le mode de simulation V2 reste
compatible. Aucune nouvelle interface d’administration n’est ajoutée : le mécanisme
serveur et les méthodes clientes sont prêts pour une future interface ou un usage contrôlé
par le club. Aucun utilisateur réel ni habilitation réelle n’est créé.

Les éléments confirmés par le club sont réutilisés : `public.matches`, `public.teams`,
`scheduled_local_override`, `venue_name_override`, RLS existantes et absence d’UPDATE
accordé à anon/authenticated. Les clés primaires et la relation matches → teams sont
découvertes automatiquement par la proposition SQL ; leurs noms et types ne sont pas
supposés. Une structure composite ou ambiguë est refusée avant installation complète.

`app/gestion-matchs-config.js` conserve tous les verrous :

- `backendReady:false` bloque le raccordement réel en lecture tant qu’il n’est pas installé.
- `writesApproved:false`, `liveWritesApproved:false`, `accessWritesApproved:false`.
- Trois verrous indépendants côté base sont eux aussi initialisés à false.

## Propositions SQL, non déployées

Les fichiers ordonnés dans `validation/site-m01/sql/` sont des propositions à relire,
**pas des migrations inscrites dans l’historique Supabase**. Le CLI Supabase n’est pas
installé dans cet environnement ; aucun nom de migration horodatée n’est fabriqué.
Après validation, les intégrer au processus de migration du projet réel.

1. `00-schema-snapshot.sql` : une seule lecture de métadonnées suffit à finaliser les
   correspondances restantes et récupérer la définition exacte de public_calendar.
   Aucun compte ni aucune ligne sportive n’est lu par cette requête.
2. `01-access-live.sql` : transaction d’installation du mécanisme privé et des façades RPC.
   Aucun INSERT de compte, d’habilitation, de règle sportive ou de rencontre.
3. `02-configure.sql` : cinq noms de colonnes encore non fournis doivent être confirmés
   une fois : timestamp local source, adversaire, libellé équipe, compétition du match,
   identifiant stable exposé par public_calendar. Le script refuse les noms absents et
   types incompatibles. Les clés réelles et les champs override ne sont pas à reconfigurer.
   Des recettes commentées préparent le bootstrap d’un administrateur Auth existant et
   les règles des équipes par identifiant réel, sans aucun utilisateur à créer maintenant.
4. Le générateur `calendar-view-patch.py` prépare le DDL ciblé depuis la définition réelle.
5. `03-disable.sql` prépare un arrêt des écritures sans supprimer l’historique ni les données.

Les cinq correspondances restent des points techniques, pas des données à inventer.
Si le calendrier n’expose aucun identifiant stable de matches, la vérification publique
ne peut pas être raccordée telle quelle : il faudra préparer une adaptation ciblée après
lecture de la définition, sans rapprocher les matchs par nom/date/adversaire.
Si la source est un timestamptz ou des colonnes date/heure séparées, adapter explicitement
le petit projecteur plutôt que convertir silencieusement une heure en supposant son fuseau.

## Structure privée et permissions

Le schéma `site_m01` ne doit pas être ajouté aux schémas exposés dans Data API.
Toutes ses tables ont RLS activée et aucun accès direct pour anon/authenticated :

| Élément | Rôle |
| --- | --- |
| `administrators` | UUID Supabase Auth des seuls administrateurs des habilitations |
| `team_access` | UUID Auth + équipe réelle + origine manual/club_app ; enabled, Gestion, Live |
| `team_rules` | Règle de score par équipe réelle et compétition validée |
| `match_state` | Sept étapes, scores Live facultatifs et deux versions distinctes, FK sur matches |
| `history` | Auteur UUID, date, opération, ancienne et nouvelle valeur ; accès admin uniquement |
| `model` | Correspondances techniques et verrous d’activation serveur |

Les clés étrangères des habilitations/règles pointent vers les équipes existantes avec
leur type natif ; les états Live pointent vers les rencontres existantes. Ce n’est pas un
second catalogue de matchs. Les scores officiels et sources FFBB ne sont jamais modifiés.

L’identité est vérifiée par auth.uid() et l’existence du compte Auth non anonyme. Aucun
`user_metadata`, e-mail saisi ou rôle de l’interface n’accorde de droit. Les habilitations
sont relues en base pour chaque opération. Les mutations d’accès et sauvegardes d’un même
utilisateur partagent un verrou transactionnel, et les versions détectent les modifications
obsolètes. Les tests vérifient ces versions ; aucun test de charge multiclient n’est revendiqué.

Une ligne manuelle a priorité sur une future ligne club_app pour la même personne/équipe.
La révocation manuelle reste une ligne `enabled:false` : elle ne révèle pas indirectement
un ancien droit importé. `external_ref` est réservé à une future correspondance externe.
Aucune synchronisation ni droit d’écriture client sur l’origine club_app n’est développé.
Un administrateur des habilitations ne reçoit pas automatiquement Gestion/Live.

Les façades RPC publiques sont **SECURITY INVOKER**, révoquées pour PUBLIC/anon et
accordées à authenticated. Les points d’entrée privilégiés sont privés, avec search_path
vide et contrôles explicites d’identité, équipe, opération et verrous. Ce choix SECURITY
DEFINER est délibéré pour effectuer une mutation limitée et son audit atomique sans
accorder UPDATE directement sur matches ; ces fonctions contournent donc RLS en tant que
propriétaire et leurs contrôles internes doivent être revus avant validation. Les helpers
n’ont aucun EXECUTE client. Aucune politique existante n’est remplacée ou élargie.

Références techniques consultées :
https://supabase.com/docs/guides/database/functions et
https://supabase.com/docs/guides/database/postgres/row-level-security.

## API préparée

- `site_m01_teams(p_scope)` : équipes réellement autorisées pour management ou live.
- `site_m01_list(...)` : projection limitée aux équipes autorisées, pagination.
- `site_m01_save_management(p_id,p_revision,p_patch)` : uniquement date/heure/salle.
- `site_m01_save_live(p_id,p_revision,p_patch)` : uniquement étape OU score Live.
- `site_m01_public_match(p_id)` : vérification privée ciblée des valeurs de la vue publique.
- `site_m01_set_access(...)` : administrateur identifié, UUID Auth existant, équipe réelle,
  trois booléens explicites ; permet attribution, modification et révocation.
- `site_m01_access_list(...)` : liste paginée des habilitations, administrateur seulement.
- `site_m01_audit(...)` : historique paginé, administrateur seulement.

Les méthodes clientes `setAccess()` et `listAccess()` sont préparées ; aucune saisie de
nom ou d’adresse des futurs utilisateurs n’est nécessaire à cette étape.

Une correction d’heure seule conserve la date ; une correction de date seule conserve
l’heure et les secondes. Le serveur combine ces éléments dans scheduled_local_override.
Si date ou heure indispensable est inconnue, il refuse plutôt que créer une valeur.
Une correction de salle ne touche que venue_name_override. Aucun champ FFBB source ni
résultat officiel n’est dans les SET de la fonction. Une sauvegarde Gestion est confirmée
au client seulement après relecture privée et concordance avec public_calendar.

U11 M1 = DMU11-4-P2 n’autorise le score qu’avec sa règle d’équipe explicitement configurée.
DMU11-10-P2 reste bloqué même en cas de règle numérique erronée. Les U9 sont configurés
par identifiant réel avec u9-no-score ; les appels Live ne peuvent modifier ces règles.
Une règle absente/inconnue ou une compétition différente masque et interdit le score.
Les réponses SQL Live omettent les champs de score pour ces équipes, avant transmission.
Aucune identité de correcteur ne figure dans les réponses destinées aux rencontres.

## Correction de salle de public_calendar

```sh
# definition.sql = texte exact du SELECT retourné par pg_get_viewdef, sans réécriture.
python3 validation/site-m01/calendar-view-patch.py definition.sql > proposition-vue.sql
```

Le parseur AST ne transforme que la colonne de sortie venue_name, y compris dans les
branches UNION et CASE. Les références directes à matches.venue_name_raw deviennent
COALESCE(matches.venue_name_override,matches.venue_name_raw). Les branches déjà corrigées
et les autres colonnes/filtres restent sémantiquement inchangés. Les sources ambiguës,
CTE ou sous-requêtes complexes sont refusées pour éviter une réécriture hasardeuse.
Le DDL généré verrouille la vue, vérifie sa définition exacte et sauvegarde l’ancienne
définition en privé. Les options existantes sont réappliquées explicitement lors du CREATE OR REPLACE ;
les accès sont conservés : vérifié localement
avec un droit SELECT anon et security_barrier=true. La définition réelle n’étant pas
accessible, aucun faux fichier de migration de cette vue n’est présenté comme définitif.

## Tests exécutés

- 15 tests V1 et 21 tests Live existants réussis après raccordement de l’adaptateur.
- 25 contrôles dans un vrai moteur Postgres local (PGlite 0.3.14), avec uniquement des
  UUID, équipes et matchs de test : installation, découverte des clés, ACL, droits par
  équipe, Live sans Gestion et inversement, administration, révocation, priorité manuelle,
  champs manuels, conservation date/heure/secondes, scores facultatifs, interdictions
  U11 M2/U9 côté SQL, historique privé et annulation intégrale si l’audit échoue.
- Ces contrôles incluent le client RPC contre les fonctions SQL locales : détection de
  la vue non corrigée, génération et application réelle du patch sur la vue de test,
  sauvegarde privée de sa définition, maintien des ACL/options, refus d’un patch périmé,
  puis confirmation de propagation de la salle.
- 9 tests du générateur AST : UNION, CASE, conservation des autres colonnes et refus des
  sources ambiguës/requêtes hors périmètre.
- Aucun compte ni habilitation réel, aucun DDL/DML en production. Le connecteur a encore
  refusé la seule tentative de lecture ciblée ; les documentations ont pu être consultées.
- L’interface n’a pas été modifiée visuellement ; les validations responsive V2 restent
  applicables. Aucun nouveau contrôle navigateur du raccordement réel n’est revendiqué.

Dépendances de développement uniquement (installées dans /tmp pour ces tests) :
`@electric-sql/pglite@0.3.14`, `pglast==7.22` dans requirements-test.txt.

Exemple de reproduction sans dépendance ajoutée au site :

```sh
pnpm --dir /tmp/site-m01-pg add @electric-sql/pglite@0.3.14
python3 -m pip install --target /tmp/site-m01-pg/python -r validation/site-m01/requirements-test.txt
PYTHONPATH=/tmp/site-m01-pg/python \
SITE_M01_PGLITE_PATH=/tmp/site-m01-pg/node_modules/@electric-sql/pglite/dist/index.js \
node validation/site-m01/tests-database.mjs
PYTHONPATH=/tmp/site-m01-pg/python python3 validation/site-m01/tests-calendar-patch.py
```

## Fichiers de cette étape

Modifiés : `app/gestion-matchs-config.js`, `app/gestion-matchs-core.js`, ce compte rendu.
Ajoutés : `sql/00-schema-snapshot.sql`, `sql/01-access-live.sql`, `sql/02-configure.sql`,
`sql/03-disable.sql`, `calendar-view-patch.py`, `tests-calendar-patch.py`,
`tests-database.mjs`, `requirements-test.txt`, tous sous `validation/site-m01/`.

## Restant à valider, une seule passe technique

Récupérer le snapshot de métadonnées, finaliser les cinq correspondances et le patch exact
de vue, puis revoir les propositions et les politiques existantes dans un environnement
Supabase de test autorisé. Contrôler notamment les triggers existants et l’absence de
mécanisme Live réutilisable non présent dans le dépôt avant d’adopter match_state.
Configurer ensuite les identifiants réels des équipes et les administrateurs Auth existants
lorsque le club décidera d’attribuer les accès. L’OTP e-mail réel, PostgREST et les politiques
hébergées restent à tester. Aucun de ces points n’autorise l’activation en production.

---

# Finalisation depuis le snapshot réel reçu — 7 novembre 2026

Les paragraphes antérieurs décrivent l’historique des livraisons. Les cinq correspondances
techniques et le patch de la vue ne sont **plus en attente** : voir `ACTIVATION.md` pour
la procédure courante soumise à validation.

Le fichier reçu commence au bloc des colonnes teams ; il ne contient pas le début de la
liste des colonnes matches. Sa définition de public_calendar est complète. Les noms
utilisés par cette définition suffisent à finaliser les correspondances sans reconstruire
un faux snapshot complet. L’extrait reçu est normalisé dans `reference/schema-received.json`,
avec son empreinte et une note de provenance, et le SELECT exact est conservé séparément.
Les contrôles SQL restent bloquants si un type réel ne correspond pas au contrat attendu.
Aucune lecture ou exécution supplémentaire sur le projet réel n’a été réalisée.

Correspondances finalisées : matches.scheduled_local_ffbb, matches.opponent_name,
teams.name, matches.competition_name et public_calendar.id. Les clés UUID sont conservées.
Le code de compétition de la règle d’équipe reste distinct du libellé competition_name :
`team_rules.source_competition` le relie au libellé effectif de la vue. Un changement de
compétition non configuré masque et interdit le score plutôt que l’attribuer à tort.

Le projecteur privé réutilise la vue pour les dates/heures effectives : les heures inconnues
MiniBasket/U9 restent inconnues. Il conserve aussi les secondes connues pour les corrections
partielles. Le client vérifie la précision exposée par la vue publique (minute pour la
branche historique) tout en contrôlant les secondes exactes lors de la relecture privée.
La vérification privilégiée refuse de prétendre publier une rencontre exclue par les
conditions published/has_conflict/is_public.

`sql/04-public-calendar-venue.sql` est maintenant le patch final généré depuis le SELECT
reçu. Trois expressions de salle sont corrigées : branches esbb_minibasket, esbb_u18m_fbi,
esbb_u13_u15_fbi. L’AST est comparé au SELECT d’origine avec ces seules substitutions :
aucune autre projection, clause WHERE, exclusion, UNION ou règle d’horaire n’est modifiée.
La branche historique était déjà corrigée. Le script vérifie la définition et les options
exactes du snapshot, sauvegarde l’ancienne vue en privé et maintient security_invoker=true.
Les alias imbriqués legacy sont suivis par le générateur sans visiter les autres colonnes
ou les sous-requêtes des filtres.

Tests finaux ajoutés : `tests-real-schema.mjs` utilise les noms/UUID et la vue imbriquée
réelle, avec uniquement des lignes fictives. Le garde du script final est exécuté tel quel :
la définition canonique locale est identique au SELECT reçu, sans substitution du garde.
Les résultats et colonnes sont comparés avant/après, ainsi que les ACL, la sécurité invoker,
les règles de lecture, la séparation des équipes et les heures inconnues. Le client V2
est testé contre ces RPC SQL locales pour la propagation et la précision des horaires.

Résultats de la dernière passe :

- 15 contrôles V1 réussis, 21 contrôles Live réussis.
- 25 contrôles Postgres génériques réussis (droits, révocations, overrides, audit, rollback).
- 15 contrôles Postgres avec la définition réelle et des données fictives réussis.
- 12 contrôles AST réussis, dont la comparaison intégrale des trois seules substitutions
  et la reproductibilité exacte du script final.
- Total : 88 contrôles locaux. Aucun test hébergé Auth/OTP/PostgREST n’est revendiqué.
- Fichiers calendrier.html, calendrier.js, équipes, style commun, HTML/CSS et interactions
  V2 conservés. Aucun nouveau contrôle responsive requis par un changement visuel.

Reproduire le nouveau test (PGlite 0.3.14, aucune connexion réseau) :

```sh
SITE_M01_PGLITE_PATH=/tmp/site-m01-pg/node_modules/@electric-sql/pglite/dist/index.js \
node validation/site-m01/tests-real-schema.mjs
```

Fichiers de cette finalisation : configuration/commentaires et adaptateur RPC client,
`sql/01-access-live.sql`, `sql/02-configure.sql`, `sql/04-public-calendar-venue.sql`,
`calendar-view-patch.py`, tests SQL/AST, références du snapshot, ce compte rendu et
`ACTIVATION.md`. Aucun fichier du calendrier public modifié. Les fichiers .DS_Store locaux
préexistants sont laissés intacts et non inclus dans les changements.

Restent à décider/configurer lors de la recette autorisée : UUID des administrateurs et
utilisateurs Auth existants, UUID réels d’équipes, règles sportives par compétition et
validation OTP/HTTP hébergée. Il ne manque plus de correspondance technique du snapshot.
Aucun compte réel, habilitation réelle ou règle d’équipe réelle créé ; aucune migration
réelle exécutée ; aucun verrou ouvert, fusion main ou déploiement Hostinger.
