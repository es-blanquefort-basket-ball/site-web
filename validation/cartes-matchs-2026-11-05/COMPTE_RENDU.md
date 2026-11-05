# Cartes de matchs et date globale — 5 novembre 2026

## Modifications effectuées

Branche dédiée : codex/cartes-matchs-dates-2026-11-05, créée depuis main à jour (34e3d6e) après fetch. Aucune fusion de ce chantier dans main, aucun téléversement Hostinger, aucune écriture Supabase.

- Les adresses publiques de contact.html sont utilisées en secours lorsque l'adresse du match est vide. Correspondance par une liste explicite d'alias normalisés, sans rapprochement approximatif d'un gymnase inconnu. Les adresses importées renseignées restent prioritaires. Aucune contradiction matérielle relevée pour les gymnases du club : les adresses Port du Roy et Fongravey importées sont moins détaillées, mais ne désignent pas une autre rue. Les indications approximatives du Béchon sont conservées comme telles.
- Une URL individuelle FFBB doit utiliser HTTPS, le domaine competitions.ffbb.com et un chemin terminé par /match/numéro. Libellé : « Fiche officielle du match ». Le lien d'équipe éventuel reste explicitement une page d'équipe, avec indication que la fiche du match est indisponible. Liens externes avec target=_blank et rel=noopener.
- Une pastille globale est ajoutée aux 12 pages publiques non redirigées. Réutilisation de la forme et des couleurs du badge existant, sans modification des règles des cartes ou du Design System. Les deux petits fichiers site-update.js/css sont isolés pour fonctionner aussi sur la page Mentions légales, qui possède ses propres styles et ne charge pas le JavaScript commun. script.js et style.css restent inchangés.
- La date globale est centralisée dans SITE_RELEASE_DATE (site-update.js). Elle reste null en prévisualisation : « Prévisualisation — livraison non publiée ». Lors de la publication validée, renseigner la date réelle au format ISO. Le 5 novembre 2026 donne « Site mis à jour le 5 novembre 2026 » ; une publication ultérieure doit porter sa date effective. Aucune date de publication fictive annoncée.
- Les trois dates métier existantes restent inchangées : calendrier 4 novembre, équipes 3 novembre, planning 22 septembre. Aucun horaire, résultat ou date sportive modifié.

## Fichiers modifiés

12 pages : 404.html, calendrier.html, contact.html, equipes.html, essais.html, index.html, inscriptions.html, le-club.html, mentions_legales_ESBB.html, partenaires.html, planning.html, sponsors.html.

Fonction du calendrier : calendrier.js. Deux fichiers communs ajoutés : site-update.css et site-update.js. matchs.html (redirection) et tout app/ inchangés. Documentation, CSV et preuves propres au chantier dans ce dossier validation.

## Vérifications effectuées

- Lecture publique Supabase : HTTP 200, 77 rencontres. Aucun POST/PATCH/DELETE et aucun score chargé. 33 URL individuelles enregistrées au format accepté ; 44 rencontres sans URL individuelle (fiches-ffbb-manquantes.csv).
- Répartition des 44 liens manquants : U9F, U9M1, U9M2, U11 M, U13F, U13M, U15M, U18M : 5 chacune ; U11 Mixte : 4.
- Le navigateur a ouvert la véritable fiche SG1–B.Izon 200000014548774 : B.Izon–Entente Sportive Blanquefort, journée 8, 29 novembre à 15h00, Gymnase Les Costauds, Rue des Écoles, 33450 Izon. Aucune dérogation appliquée. Les 32 autres destinations FFBB ne sont pas toutes revisitées : leur présence et leur format sont vérifiés, pas une nouvelle certification exhaustive du contenu FFBB.
- 19 rencontres sans adresse à Port du Roy bénéficient du référentiel du site. Après ce secours, 25 rencontres restent sans adresse, réparties sur 22 noms de salles (adresses-a-verifier.csv). Aucun rapprochement arbitraire d'une salle générique : « Gymnase du Collège », « Salle des Sports », « COSEC » notamment restent à vérifier si leur adresse manque.
- Ordinateur 1440×900, tablette 768×1024, téléphone 390×844 : huit matchs affichés le 14 novembre ; panneau avec overflow auto, contenu défilant, fermeture accessible. Défilement réel jusqu'au huitième match confirmé sur ordinateur et téléphone (captures ordinateur-bas.jpg et mobile-bas.jpg).
- Journée du 15 novembre : U18M et SG1 sur fond vert foncé, SG2 extérieur sur fond blanc. Couleurs, pastilles, équipes, adversaires, heures et journées conservés. Les règles CSS home/away ne sont pas modifiées.
- Les 12 pages ont une seule pastille ; contrôle DOM des 12 pages aux trois largeurs : aucun débordement horizontal détecté (pages-responsive.json). Filtre U9F : trois rencontres de novembre, équipe U9F sélectionnée.
- Syntaxe JavaScript contrôlée ; verification-date.cjs valide l'absence de fausse date en prévisualisation et les dates de livraison du 5 et du 12 novembre ; verification-liens.cjs vérifie les rejets de pages d'équipe, de domaines étrangers et les alias des salles.
- git diff --check sans erreur. Les fichiers métier locaux antérieurs sont conservés. Le seul écart par rapport au manifeste de la précédente intervention concerne .DS_Store, métadonnée macOS changée pendant l'utilisation du sélecteur de fichiers ; elle n'est ni restaurée ni incluse dans le commit. Le fichier local validation/calendrier-horaires.cjs n'est pas inclus.

## Prévisualisation et points à valider

GitHub Pages actuellement configuré sur main : https://es-blanquefort-basket-ball.github.io/site-web/ affiche la version précédente, PAS ce chantier. Aucun réglage Pages modifié. Une branche distante du même nom a été créée depuis main, mais le téléversement des changements y a été bloqué avant envoi : l'extension Chrome exige « Allow access to file URLs ». Aucune permission élargie. Le push Git n'a pas d'authentification utilisable dans cet environnement ; le connecteur GitHub avait déjà refusé les écritures lors de l'intervention précédente.

Le commit local peut être publié avec GitHub Desktop : sélectionner la branche codex/cartes-matchs-dates-2026-11-05 et faire Push origin. Pour la prévisualisation demandée, dans Settings → Pages → Deploy from a branch, sélectionner cette branche et / (root), puis Save ; attendre la réussite du déploiement et vérifier l'URL Pages ci-dessus. Ne pas fusionner dans main. Cette sélection ne concerne que le site Pages de ce dépôt, sans toucher à Hostinger.

Prévisualisation locale disponible sur http://127.0.0.1:8765/calendrier.html tant que le serveur de revue reste démarré. Le dossier de validation n'est pas destiné à Hostinger.

À valider : rendu local, publication de la branche et déploiement GitHub Pages, puis date effective et livraison Hostinger. Lors de la livraison, sauvegarder les 12 HTML concernés et calendrier.js, ajouter uniquement les deux ressources site-update, renseigner la date réelle, purger le cache du seul domaine et contrôler ordinateur/mobile. Les anciennes instructions limitées à trois fichiers ne suffisent pas à ce nouveau chantier. Aucune mise en production effectuée.
