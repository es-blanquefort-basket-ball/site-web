# SITE-M01 — Procédure d’activation soumise à validation

**État livré : aucune installation en production, aucune création de compte ou habilitation
réelle, tous les verrous clients et serveurs désactivés. Cette procédure n’autorise pas son
exécution. Aucune fusion dans main ni publication Hostinger.**

## 1. Fichiers finalisés

| Élément | Fichier |
| --- | --- |
| Installation privée, RPC, habilitations et audit | `sql/01-access-live.sql` |
| Cinq correspondances finalisées | `sql/02-configure.sql` |
| Patch exact de la vue reçue | `sql/04-public-calendar-venue.sql` |
| Arrêt des écritures sans perte d’historique | `sql/03-disable.sql` |
| Référence reçue et définition d’origine | `reference/schema-received.json`, `reference/public-calendar.before.sql` |

Le snapshot `00-schema-snapshot.sql` n’est pas à réexécuter pour cette préparation.
Les scripts sont proposés dans le dépôt ; aucun n’est enregistré comme migration Supabase
appliquée. Pour un projet géré par le CLI, les intégrer à son processus de migrations après
validation. Ne pas exécuter tous les fichiers SQL avec un joker : `03-disable.sql` est un
script d’arrêt, pas une étape d’installation.

Les cinq correspondances sont maintenant fixées :

| Usage | Source réelle |
| --- | --- |
| Horodatage FFBB local | `matches.scheduled_local_ffbb` |
| Adversaire | `matches.opponent_name` |
| Libellé d’équipe | `teams.name` |
| Libellé de compétition du match | `matches.competition_name` |
| Identifiant public stable | `public_calendar.id`, lié à `matches.id` |

`matches.id`, `matches.team_id` et `teams.id` restent des UUID. Les corrections ne visent
que `scheduled_local_override` et `venue_name_override`. La vue existante reste la source
des dates/heures effectives et des règles de dates MiniBasket/U18/U13/U15. Les secondes
connues sont conservées en privé même lorsque la vue publique affiche seulement la minute.

## 2. Première validation sur un environnement de test autorisé

Avant toute exécution, valider explicitement l’environnement et conserver sa définition
actuelle de vue et son schéma. Utiliser une copie avec données de test et comptes Auth de
test existants. Ne pas pointer une interface de recette vers la production.

Ordre d’installation proposé :

1. `01-access-live.sql` crée uniquement le schéma privé et les façades RPC. Les gardes
   vérifient clés, relation équipe, RLS et types. La transaction échoue intégralement si
   le schéma est incompatible ou déjà installé ; ne pas supprimer un schéma existant
   pour contourner cette erreur.
2. `02-configure.sql` fixe les cinq noms réels. Il vérifie les identifiants UUID, le type
   du timestamp local source et `security_invoker=true`. Il n’active aucune écriture et
   ne crée aucun compte, administrateur, droit ou règle de score.
3. `04-public-calendar-venue.sql` verrouille la vue et exige sa définition et ses options
   exactes telles que reçues. Il sauvegarde définition/options en privé puis corrige
   seulement les trois projections de salle. Les options de sécurité sont réappliquées.
   Si le garde échoue, ne pas le retirer : rapprocher la nouvelle définition de la version
   reçue et régénérer un patch ciblé. Aucun remplacement automatique d’une vue différente.

Le schéma `site_m01` doit rester hors des schémas exposés Data API. Les seules entrées API
sont les fonctions publiques SECURITY INVOKER prévues. Aucun UPDATE n’est accordé à anon
ou authenticated sur matches. Les contrôles d’autorisation résident dans les entrées
privées privilégiées, qui doivent être relues avant approbation de la migration.

## 3. Configuration des habilitations — recette seulement

Aucun compte n’est à créer dans cette livraison. Pour la recette ultérieure :

- Choisir les UUID Auth **déjà existants** des comptes de test fournis pour la recette.
- Un opérateur habilité inscrit uniquement l’administrateur de test dans
  `site_m01.administrators`. Aucun rôle n’est tiré de user_metadata ou d’un e-mail saisi.
- Après validation, activer uniquement `site_m01.model.access_enabled` dans le bac de test.
- Pour cet usage administratif, configurer une copie du client sur le projet de test,
  avec `backendReady:true` et `accessWritesApproved:true` seulement. Garder les verrous
  Gestion/Live fermés et refermer le verrou administratif à la fin de cette configuration.
- L’administrateur connecté peut appeler `site_m01_set_access` (méthode cliente
  `setAccess`) avec l’UUID Auth cible, l’UUID réel d’équipe et les booléens Gestion,
  Live, enabled. `site_m01_access_list` permet de relire les droits, sans e-mails.
- Préparer au moins : Gestion seule, Live seul sur une équipe, Gestion+Live, aucun droit.
  Les matchs d’une autre équipe doivent rester refusés.
- Pour retirer un accès, passer `enabled:false`. Conserver la ligne manuelle : elle
  interdit qu’un droit club_app futur réapparaisse après révocation. Aucun moteur de
  synchronisation ni écriture client de l’origine club_app n’est installé.

L’administrateur des habilitations ne reçoit pas automatiquement le droit Gestion ou Live.
Les changements d’habilitations sont journalisés avec l’UUID de l’administrateur connecté.
Ne pas utiliser des modifications directes des tables privées comme parcours courant.

## 4. Règles sportives à configurer par identifiant réel

Ces données de configuration du club ne sont pas des correspondances techniques manquantes.
Le snapshot est structurel et ne contient pas les UUID d’équipes ni les valeurs de leurs
libellés de compétition. Aucune association n’a donc été inventée ou insérée.

Dans le bac de test, renseigner `site_m01.team_rules` pour les UUID réellement choisis :

- U11 M1 : code validé `DMU11-4-P2`, politique `numeric`.
- U11 M2 : code validé `DMU11-10-P2`, politique `minibasket-no-score`.
- U9 : code réel de la compétition concernée, politique `u9-no-score`.

`source_competition` doit reproduire exactement le libellé effectif
`public_calendar.competition_label` de ces rencontres. **Un libellé competition_name n’est
pas un code DMU11.** Une règle absente ou un libellé qui ne concorde plus interdit et
masque les scores. Le code DMU11-10-P2 reste interdit même avec une politique numeric
erronée. Les règles sont configurées par l’opérateur de confiance, pas par le référent Live.

Les recettes commentées de `02-configure.sql` précisent les colonnes. Ne pas rapprocher
les équipes par un nom approchant et ne pas copier les UUID fictifs des tests.

## 5. Activer progressivement la copie de test

Après installation et configuration autorisées, dans **la copie de recette uniquement** :

1. Configurer l’URL et la clé publishable du projet de test. Mettre `backendReady:true`.
   Conserver `writesApproved`, `liveWritesApproved`, `accessWritesApproved` à false lors
   du premier contrôle en lecture, sauf le seul accès administratif explicitement testé.
2. Vérifier l’OTP : fournisseur e-mail actif, modèle comportant `{{ .Token }}`, compte
   Auth de test existant. Pas de création automatique de compte (`create_user:false`).
3. Tester les espaces visibles, les équipes filtrées par UUID et les appels directs
   refusés pour un compte non habilité. Aucun secret service_role dans le client.
4. Après autorisation de la recette d’écriture, ouvrir séparément les verrous serveur
   `management_enabled` / `live_enabled` et leurs homologues clients dans cette copie.
   Ne pas reporter ces changements dans la configuration de production livrée.
5. Tester une correction date seule, heure seule et salle seule ; vérifier les anciennes
   valeurs conservées, la relecture privée et la propagation dans public_calendar.
   Une date seule est refusée si l’heure est inconnue, plutôt que créer un horaire.
6. Tester les sept étapes, précédent/suivant, score facultatif indépendant, conservation
   du score, U11 M1 numérique et U11 M2/U9 sans champ numérique dans les réponses SQL.
7. Tester le refus d’un référent Live sur une RPC Gestion, le refus d’une autre équipe,
   la révocation sans renouvellement du JWT, le conflit de version et l’historique privé.
8. Tester le parcours V2 sur ordinateur et téléphone avec le service hébergé réel de test.
   Les tests locaux ne remplacent pas cette recette Auth/HTTP/PostgREST.

L’identité des correcteurs reste dans l’historique privé, réservé aux administrateurs.
Aucune page Live publique ni publication de scores ou d’identités n’est activée ici.

## 6. Décision de production distincte

Conserver les résultats de recette et soumettre les scripts, leurs différences et la
configuration prévue au club. **Une validation humaine séparée est indispensable avant
migration ou activation en production.** Aucun compte réel ne sera créé implicitement.
La fusion main et la publication Hostinger nécessitent également leur validation.

La configuration actuellement versionnée reste : backendReady=false et les trois
writesApproved=false. Les valeurs serveur initiales restent également false.

## 7. Arrêt / retour arrière

Sur l’environnement ultérieurement autorisé, `03-disable.sql` ferme les écritures et
révoque les EXECUTE de mutation tout en conservant données et historique. Remettre aussi
les verrous clients à false. Ce script a été testé localement.

Pour un retour de la vue, utiliser la définition et les options sauvegardées, après
vérification qu’aucune évolution ultérieure ne serait écrasée. Les overrides des rencontres
ne sont pas annulés en masse et l’historique n’est pas supprimé. En cas de script arrêté
par un garde, conserver le verrou et examiner l’écart ; ne pas forcer le passage.
