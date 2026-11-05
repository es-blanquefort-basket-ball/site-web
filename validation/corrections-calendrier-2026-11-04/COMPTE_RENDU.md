# Corrections ciblées du calendrier — 4 novembre 2026

## Versions et protection du travail existant

- Consignes AGENTS.md, ARBORESCENCE_SITE.md et README_SITE.md lues.
- État initial : branche main, fichiers publics et travaux d’import locaux déjà modifiés/non suivis. Sauvegarde avant intervention dans `/private/tmp/esbb-correction-calendrier-20261104/avant/` et diff local sauvegardé à côté. Aucun stash/reset/nettoyage de ces travaux.
- `git fetch origin` effectué ; HEAD et origin/main identiques (`3d6e29b`). `git pull --ff-only origin main` : déjà à jour.
- Branche dédiée : `codex/corrections-calendrier-2026-11-04`. Aucune fusion, aucun push ni déploiement.
- Cinq fichiers publics Hostinger téléchargés en lecture seule : calendrier.html, calendrier.js, equipes.html, style.css, script.js. Les trois premiers correspondent exactement au contenu local avant correction ; CSS/JS communs identiques textuellement (différence de fins de ligne pour style.css).
- Le calendrier et les accès MiniBasket locaux/Hostinger contiennent déjà des fonctionnalités absentes de main : elles sont conservées. Ne pas remplacer ces fichiers par ceux de main.
- L’ancien `CORRECTIF_CALENDRIER_2026-11-04.patch` n’a pas été appliqué. Aucun fichier portant ce nom n’a été trouvé dans le dépôt.
- `comparaison-versions.json` conserve les comparaisons et empreintes. `diff-vs-production.patch` montre exclusivement cette intervention par rapport à la version réellement servie, à lire pour revue uniquement. Les différences globales avec main incluent les travaux antérieurs et ne doivent pas être attribuées entièrement à cette correction.

## Fichiers publics modifiés

### calendrier.html

Correction limitée aux règles du panneau pour les largeurs ≥681px : ligne de grille contrainte, hauteur minimale nulle, corps défilant qui peut rétrécir, alignement en haut, entête non rétrécissable et suppression du padding des sections internes. Cela neutralise le `section{padding:86px 0}` global sans modifier style.css ni les autres pages. Aucun changement des règles du panneau mobile ≤680px.

Les cinq boutons U9/U11 deviennent « Voir les matchs », avec labels explicites ; leurs URLs filtrées existantes sont conservées. Date affichée : « Mis à jour le 4 novembre 2026 ». Version du script `calendrier.js?v=20261104` pour éviter que l’ancien JavaScript en cache masque les corrections.

### calendrier.js

Ajout d’un lien Google Maps encodé à partir de la salle et de l’adresse disponible. Si seule la salle est connue, recherche sur son nom exact, affichage « Adresse à vérifier » et lien de recherche explicite. Aucune adresse ni lien de fiche FFBB inventé. Les adresses postales et les vrais liens FFBB existants restent visibles. Absence de salle et d’adresse : aucun faux lien Maps.

À chaque ouverture de journée, retour du corps du panneau en haut. Filtres, navigation, horaires inconnus, liens FFBB et piège de focus existants conservés.

### equipes.html

Les cinq boutons MiniBasket liés au calendrier deviennent également « Voir les matchs ». Aucun changement des horaires, catégories, autres liens FFBB, disposition ou date propre à cette page.

Aucun changement de style.css, script.js, ffbb-sync, imports SQL, cron, navigation générale ou données Supabase.

## Tests effectués

Tests réels de l’aperçu local dans Chrome, utilisant la vue publique Supabase en lecture seule :

- Ordinateur **1440×900**, tablette **768×1024**, téléphone **390×844** ; absence de débordement horizontal sur calendrier et page Équipes.
- Journées du 7 novembre (7 matchs) et du 14 novembre (8 matchs) : toutes les cartes restent présentes. À 1440px, panneau de 900px, corps défilant, première carte en haut ; après défilement la dernière carte est visible et l’entête/croix restent en place. Même résultat à 768px.
- Un seul match, via filtre U18M du 8 novembre : première carte en haut, sans étirement vertical pour remplir le panneau.
- Téléphone : panneau bas de page avec sa hauteur/rayons/règles existants, 8 cartes défilables, entête/croix accessibles. Le padding des groupes mobile est inchangé conformément à la demande de préserver ce fonctionnement.
- Ouverture d’une nouvelle journée après défilement : scroll du panneau remis à zéro.
- Les cinq boutons U9F/U9M1/U9M2/U11 Mixte/U11 M ouvrent chacun l’URL filtrée et une carte de la bonne équipe le 7 novembre. Retour « Afficher toutes les équipes » opérationnel. Contrôle des cinq liens identiques sur equipes.html.
- Menu mobile ouvert/fermé correctement. Navigation clavier dans le panneau : Tab vers la croix, Maj+Tab vers le dernier lien, Tab reboucle vers la croix ; Échap ferme et remet le focus sur le bouton du jour.
- Cartes importées sans adresse : lien Maps portant uniquement le nom de la salle + avertissement. Journée du 26 septembre : adresses postales exactes conservées dans les cartes et dans la recherche Maps, trois vrais liens de fiche FFBB conservés.
- Comparaison statique de toutes les URLs competitions.ffbb.com dans les deux HTML avant/après : aucune modification. Dix boutons renommés exactement (cinq par page). Date du calendrier corrigée.
- `node --check calendrier.js` et `git diff --check` réussis. Aucun test navigateur par pilote externe : contrôles via le navigateur connecté.
- `mesures-interface.json` et captures ordinateur/tablette/mobile conservent la preuve des dimensions, du nombre de cartes, du défilement et de l’entête fixe.

Lecture réelle de Supabase avant intervention : **77 publications**, répartition conservée dans `publications-77-lecture-seule.json`. Aucun appel d’écriture effectué : ce chantier ne change que le rendu du site. Aucun test d’import SQL ou appel de synchronisation lancé.

## Exemptions et U9 du 21 novembre

Proposition distincte dans `PROPOSITION_EXEMPTIONS_ET_U9.md`. Publication U9M2 contre Langoiran, domicile, salle Port du Roy et horaire inconnu cohérente avec le staging FBI n°81/ligne 10. U9F et U9M1 sans publication à cette date : aucune exemption déduite. Les fichiers FBI bruts MiniBasket ne sont pas disponibles pour une nouvelle vérification directe ; la page publique officielle du club ne fournit pas de calendrier U9 exploitable. Aucun match modifié.

## Livraison et points à valider

Les trois fichiers publics proposés sont prêts pour revue sur cette branche. Les scripts et dossiers d’import antérieurs sont laissés en place. Le fichier validation/calendrier-horaires.cjs avait déjà une modification locale avant cette intervention ; elle est conservée sans nouvelle modification.

Après validation humaine seulement, une publication ciblée pourrait remplacer calendrier.html, calendrier.js et equipes.html en conservant une copie de la version en ligne. Aucun fichier de validation, donnée de référence, script SQL ou ancien patch ne doit être envoyé sur Hostinger. Ne pas remplacer l’ancien dossier de déploiement automatiquement : il est resté inchangé et contient une préparation antérieure.

À valider : revue visuelle des trois fichiers ; justificatif officiel U9 autour du 21 novembre et principe de gestion des exemptions. Aucune fusion dans main ni publication effectuée.
