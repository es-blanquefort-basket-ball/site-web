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
