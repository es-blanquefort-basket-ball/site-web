# Publication manuelle ciblée — 5 novembre 2026

État : fusion GitHub effectuée par la PR https://github.com/es-blanquefort-basket-ball/site-web/pull/1 (fusion 34e3d6e). Aucune publication Hostinger effectuée. Aucun essai de connexion Google effectué. Aucun autre site concerné.

1. Connectez-vous vous-même à votre compte Hostinger professionnel de développeur. Ouvrez Sites web, puis le tableau de bord du seul domaine es-blanquefort-basketball.fr.
2. Ouvrez Fichiers → Gestionnaire de fichiers. Entrez dans le dossier web de ce domaine, généralement public_html. Vérifiez la présence de calendrier.html, calendrier.js et equipes.html ; ne choisissez pas le dossier d'un autre site.
3. Avant remplacement, téléchargez ces trois fichiers actuels dans un dossier local sauvegarde-calendrier-date-heure. Conservez-le hors du dossier public. Une sauvegarde des fichiers servis publiquement au début de cette intervention se trouve également dans sauvegarde-production/ ; si la version a changé depuis, arrêtez le remplacement pour la comparer.
4. Téléversez uniquement les trois fichiers du dossier fichiers-publics/ de cette livraison, directement à la racine web du domaine. Confirmez le remplacement de ces trois noms. Ne téléversez pas le dossier de livraison entier, les rapports, sauvegardes, captures, SQL ou archives. Aucun autre fichier à remplacer.
5. Si nécessaire, videz le cache du seul site concerné dans Hostinger, puis rechargez les pages publiques sans cache.
6. Sur ordinateur puis téléphone, ouvrez https://es-blanquefort-basketball.fr/calendrier.html. Vérifiez la date « Mis à jour le 4 novembre 2026 », le filtre d'équipe, les journées du 7 et 14 novembre (7 et 8 matchs), le défilement jusqu'au dernier match, le titre et la fermeture accessibles. Vérifiez les liens Google Maps : adresse existante conservée, sinon nom de salle avec « Adresse à vérifier ».
7. Depuis equipes.html, vérifiez les cinq boutons U9/U11 « Voir les matchs » et le filtrage de l'équipe ; conservez les liens FFBB des autres équipes. Vérifiez également le menu mobile, le changement de mois et les 77 rencontres disponibles. La lecture publique avant publication confirme HTTP 200 et 77 rencontres ; les tests de la nouvelle version en production restent à effectuer après téléversement.

En cas de régression : restaurez uniquement les trois fichiers de votre sauvegarde préalable, videz le cache du domaine puis vérifiez le site. Ne touchez ni à Supabase, ni aux imports SQL, ni au cron.

# Dates des pastilles

La livraison validée reste strictement identique au commit d455b49. Calendrier : 4 novembre 2026. Équipes : 3 novembre 2026, conservé comme date métier existante ; le changement de boutons du 4 novembre ne prouve pas une actualisation des données des équipes. Planning : 22 septembre 2026, conservé ; l'historique montre une modification des contenus ce jour-là, puis uniquement du lien de navigation le 23 septembre. Aucune nouvelle date métier inventée. Les classes et le Design System restent inchangés. Voir audit-dates.json pour l'inventaire des pages effectivement consultées et les éventuelles erreurs réseau.
