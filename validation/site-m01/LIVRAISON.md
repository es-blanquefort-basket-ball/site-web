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
