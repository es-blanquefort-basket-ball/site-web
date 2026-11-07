# SITE-M01 — Scénario de recette du projet existant

Cible : `fgswygeqstgagmipltpq`, après validation explicite de l’installation puis des essais.
**Tous les scénarios hébergés ci-dessous sont à exécuter, pas déclarés réussis.**
Les tests automatisés déjà exécutés utilisent Postgres local et des données fictives.

## Paramètres à configurer au moment de la validation

Aucun nom/adresse n’est demandé et aucun utilisateur n’est créé maintenant.

| Acteur symbolique | UUID Auth existant à choisir | Droits à attribuer |
| --- | --- | --- |
| ADMIN | [À COMPLÉTER] | Administrateur d’habilitations, sans Gestion/Live implicite |
| GESTION | [À COMPLÉTER] | Gestion de l’équipe M1 choisie, pas Live |
| LIVE | [À COMPLÉTER] | Live de M1 seulement, pas Gestion ni équipe M2 |
| MIXTE | [À COMPLÉTER] | Gestion et Live pour les seules équipes choisies |
| MINI | [À COMPLÉTER] | Live pour les UUID M2/U9 choisis, pas Gestion |
| SANS-DROIT | [À COMPLÉTER] | Compte Auth existant, aucune habilitation |

Choisir les UUID réels d’équipes dans teams et les UUID de rencontres **déjà existantes**
dans matches : M1 (DMU11-4-P2), M2 (DMU11-10-P2), U9, et si nécessaire U18/U13/U15 pour
les trois branches de salle. Ne pas réaffecter une rencontre, ne pas créer de match de test
sur le projet réel et ne pas rapprocher les équipes par un nom approchant.

Avant tout essai d’écriture, consigner pour chaque match choisi : UUID, équipe, date/heure
et salle actuelles, éventuels overrides actuels, versions, étape et score Live existants,
valeurs exactes autorisées pour le test et action de restauration approuvée. Ne pas
inventer un score ou un nouvel horaire pour une rencontre réelle. Les exemples fictifs
des tests automatisés ne doivent pas être importés en production.

## Séquence de recette

| N° | Action après validation | Résultat attendu |
| --- | --- | --- |
| 1 | Contrôle 05 avant attribution | Rôle sans bypass, politiques ciblées, flags fermés, source public_calendar invoker |
| 2 | Ouvrir l’interface sans session | Connexion requise ; pas de lecture privée ou mutation |
| 3 | Auth e-mail OTP avec compte existant désigné | Code réellement reçu, vérifié une seule fois ; create_user:false ; code invalide/expiré refusé |
| 4 | Connecter SANS-DROIT | Aucun espace autorisé ; RPC de mutation refusées |
| 5 | Connecter GESTION puis LIVE | Seul l’espace attribué et les équipes attribuées sont accessibles |
| 6 | Demander directement une autre équipe par RPC | Refus ou aucune ligne autorisée ; aucune information privée révélée |
| 7 | Demander Gestion avec LIVE et Live avec GESTION | Mutation refusée ; aucune donnée modifiée |
| 8 | Après accord d’écriture, corriger un champ Gestion puis recharger | Les seuls overrides concernés changent ; sources/résultats FFBB inchangés ; vue publique concordante |
| 9 | Tester les salles MiniBasket/U18/U13-U15 choisies | Override prioritaire dans chaque branche, filtres/horaires et security_invoker=true inchangés |
| 10 | Date seule avec heure inconnue | Refus explicite, pas de création d’horaire ; une date/heure explicites nécessitent un accord distinct |
| 11 | Annuler le formulaire de Gestion | Aucune écriture, aucun historique de modification |
| 12 | LIVE : sept étapes, précédent et suivant | Bornes respectées ; étape seule indépendante d’un score ; retour possible |
| 13 | M1 : score facultatif validé, puis étape | Score conservé ; résultat officiel FFBB inchangé ; score corrigible à toute étape |
| 14 | M2/U9 : UI et appels SQL/RPC directs | Champs de score absents des réponses, tentative de score refusée, étapes utilisables |
| 15 | Envoyer une version périmée | Conflit/refus ; pas d’écrasement silencieux d’une correction concurrente |
| 16 | ADMIN retire une habilitation, conserver l’ancienne session | Droits retirés à l’appel suivant ; pas de renouvellement JWT nécessaire pour la révocation |
| 17 | Historique après mutation approuvée | Auteur Auth réel, date, avant/après ; lecture admin seulement, aucune identité publique |
| 18 | Ordi et téléphone, erreur réseau/reconnexion | États clairs ; aucune réussite affichée avant réponse et relecture concordantes |
| 19 | Actionner 03-disable après le dernier essai | Mutations publiques/privées refusées ; RLS ferme les overrides ; historique conservé |

Un refus « rencontre introuvable » peut être la protection RLS d’une ligne hors périmètre ;
il ne faut pas révéler l’existence d’une autre équipe pour différencier les messages.

## Trace de validation

Pour chaque scénario : PASS/FAIL/non exécuté, heure, acteur symbolique, équipe et UUID de
match, résultat constaté et éventuel historique privé. Ne pas copier les JWT, codes OTP,
e-mails ou identités dans un compte rendu public ou le dépôt.

Les essais sur le calendrier concernent la lecture de la vue ; aucune modification de
calendrier.html ou calendrier.js n’est nécessaire. Les demandes de dérogation restent
hors des valeurs publiques : circuit existant à identifier par le contrôle ciblé, sans
création automatique d’un nouveau suivi.

## Conditions de sortie

Accord du club sur les résultats et corrections conservées/restaurées ; validation du
circuit de suivi privé s’il fait partie de l’usage attendu ; décision distincte de laisser
les écritures fermées ou de les ouvrir pour des personnes/équipes précises. Aucune fusion
main, publication Hostinger ou réouverture implicite après un arrêt.
