# Livraison du raccordement MiniBasket — 3 novembre 2026

## Réalisé

- Un seul calendrier : lecture de `public.public_calendar`, sans fichier de rencontres parallèle chargé par le site.
- Cinq accès depuis les fiches Équipes, via `?equipe=U9F`, `U9M1`, `U9M2`, `U11%20Mixte`, `U11%20M`.
- Filtre exact sur `team_code` dans REST et contrôle défensif dans le rendu. La poule commune aux U9M ne sert jamais d'identifiant.
- Sélecteur d'équipe, retour général, absence de publication signalée explicitement après vérification indépendante du mois affiché.
- Cinq cartes MiniBasket avec uniquement la vérification des publications ; U18 renommé U18M dans le titre uniquement. Liens FFBB existants conservés.
- Aucun score demandé à Supabase ou rendu par le calendrier.

## Staging et import contrôlé

`rencontres-staging.csv` est la copie intégrale, non modifiée, du fichier joint.
`apercu-import.json` contient les 24 propositions selon le contrat de lecture de la vue, plus leur clé de traçabilité ; ce n'est PAS un fichier à importer directement dans une table inconnue.
`horaires-a-confirmer.json` conserve les 11 lignes concernées, avec heure d'origine, fichier et ligne Excel.

Contrôles effectués : 24 lignes, répartition 5/5/5/4/5, 24 clés source distinctes, aucun doublon équipe/date/adversaire, aucun adversaire Exempt, 11 heures vides dont l'origine est 00:00, cinq correspondances FBI cohérentes avec la demande. Aucun champ score ou donnée personnelle dans le staging ou l'aperçu.
L'exemption est absente du staging ; son exclusion depuis l'export Excel original n'a pas été recontrôlée, cet export n'étant pas joint.
Les noms, dates, salles, numéros et références d'origine restent dans le CSV. Les champs publics vides sont proposés à null ; aucune adresse, heure ou URL inventée.

La clé `source_match_key` est unique dans ce lot. Sa portée intersaisons et sa compatibilité avec la contrainte réelle ne sont pas établies : la saison 2026-2027 doit faire partie du rapprochement amont si nécessaire. Les codes sont ceux PROPOSÉS par le staging, pas des identifiants de table confirmés. Le filtre attend leur publication exacte dans `team_code` ; une autre convention nécessitera une correspondance vérifiée.
Les 24 propositions sont absentes des 33 publications ; cela ne prouve pas leur absence des tables privées ou non publiées. Aucun INSERT/UPSERT, modification de vue ou RLS n'a été exécuté. L'idempotence réelle n'est pas encore testable.

## Supabase : état réel et seule intervention immédiate nécessaire

GET réel de `public_calendar` : HTTP 200, 33 entrées (U13F 5, U13M 4, U15M 4, SG1 10, SG2 10), aucun MiniBasket ni U18. Instantané public conservé dans `etat-public-calendar-avant.json`. Un second GET après les tests confirme que les 33 lignes sont strictement identiques. OpenAPI : HTTP 401. Aucun connecteur Supabase disponible ; accès par contrôle de l'interface refusé faute de permissions système. La table alimentant la vue, ses contraintes et l'import amont restent non identifiés.

**Administrateur : dans le projet `fgswygeqstgagmipltpq`, SQL Editor, exécuter exactement les trois SELECT du fichier `../DIAGNOSTIC_SUPABASE_MINIBASKET.sql` et retourner les résultats utiles, sans secret.** Ce script existant est en lecture seule : définition de vue, dépendances, colonnes, contraintes, index et noms des déclencheurs. Ne pas exécuter d'import et ne pas modifier RLS.

Ces résultats permettront de fixer la table cible, le mapping et la cible de conflit, puis de préparer l'aperçu créations/mises à jour/conflits selon le mécanisme existant. Toute écriture production restera soumise à validation humaine explicite. Ne pas contourner le blocage en publiant le staging comme autre source du site.

## Tests

- Syntaxe JS, normalisation des heures et `git diff --check` : réussis.
- `validation/calendrier-filtres.cjs` : Chrome avec réponses REST simulées à partir du staging réel + instantané public. Aux largeurs 390, 768, 1440 : cinq filtres, 24 rencontres, 11 heures inconnues, détails par équipe, retour général, filtre par formulaire et URL, liens des fiches, images et absence de débordement. Erreur réseau gérée, aucun score sélectionné/rendu. U18 : fixture explicitement simulée ; aucune rencontre U18 réelle disponible.
- Navigateur avec vrai flux Supabase : les deux pages aux trois largeurs, détail SG1/SG2 du 8 novembre, aucun débordement ni erreur JavaScript. Captures examinées. Les contrôles U13/U15 utilisent aussi l'instantané des publications réelles injecté dans le test ; aucun import Supabase simulé présenté comme réel.
- Pas de test sur téléphone physique. Pas de test d'écriture ou de synchronisation production.

## Déploiement

`../DEPLOIEMENT_HOSTINGER_CALENDRIERS/` contient uniquement `equipes.html`, `calendrier.html`, `calendrier.js`. Ces fichiers remplacent leurs homologues à la racine du site après sauvegarde et validation. Ne pas téléverser ce dossier de préparation, les tests, le staging ou le SQL dans le site public.
Aucune publication, branche, fusion ou modification de l'accueil, planning, images, animations ou Design System.
