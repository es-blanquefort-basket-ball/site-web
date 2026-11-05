# Proposition séparée : exemptions et U9 du 21 novembre 2026

Aucune modification de rencontre, aucun ajout d’exemption et aucune modification Supabase ne sont appliqués.

## Constat sur le 21 novembre

Lecture réelle du calendrier public : 77 publications. Le 21 novembre 2026 comporte U9M2, U11 Mixte, U11 M et U13M. Toutes ces heures sont actuellement inconnues. Pour les U9 :

| Équipe | Publication du 21 novembre | Source disponible | Conclusion autorisée |
| --- | --- | --- | --- |
| U9F | Aucune | Staging DFU9-10-P2 conservé : aucune ligne pour cette date | Situation non confirmée. Ne pas afficher « Exempt ». |
| U9M1 | Aucune | Staging DMU9-10-P2 conservé : aucune ligne pour cette date | Situation non confirmée. Ne pas afficher « Exempt ». |
| U9M2 | Contre LES PETITS MOUSSES LANGOIRAN (1), domicile, SALLE PORT DU ROY, horaire à confirmer | Staging DMU9-10-P2, FBI n°81, clé `DMU9-10-P2|U9M2|81`, source déclarée `rechercherRencontre (21).xlsx`, ligne 10 | Concordance entre publication et staging. Conserver la rencontre ; pas de changement de date ou d’heure sans nouveau justificatif officiel. |

Les exports MiniBasket bruts cités dans le staging ne sont pas disponibles ici ; l’export Downloads `rechercherRencontre.xlsx` concerne les U18M, pas ces U9. On ne peut donc pas revérifier directement le numéro 81 dans sa feuille d’origine ou déterminer le motif de l’absence des U9F/U9M1.

La page officielle du club a aussi été consultée : https://competitions.ffbb.com/ligues/naq/comites/0033/clubs/naq0033034 . Elle présente les catégories U13/U15/U18/Séniors dans sa liste actuelle, sans calendrier U9 exploitable pour cette vérification. Cette absence publique ne constitue pas une preuve d’exemption. La recherche web ciblée n’a pas fourni de source officielle pour les U9 du 21 novembre.

**Reste à valider uniquement :** un extrait FBI/avis officiel de la compétition pour les U9F, U9M1 et U9M2 autour du 21 novembre, indiquant soit la rencontre, soit l’exemption explicite, soit un report/coupe/changement de calendrier. Pour U9M2, la ligne de source FBI n°81 suffit à confirmer ou corriger la date actuellement conservée. Aucun score ou donnée de licencié nécessaire.

## Proposition de fonctionnement à valider avant développement

1. Conserver le message actuel « Aucune rencontre publiée » quand il n’existe aucune donnée. Ne jamais le traduire automatiquement en « Exempt ».
2. N’autoriser le statut « Exempt confirmé » qu’avec une source officielle explicite, liée à la saison, compétition/phase/poule, équipe exacte et journée/date concernée, puis validation du club.
3. Traiter séparément « Report confirmé », « Week-end de coupe confirmé » et « Situation non confirmée ». Le nombre de matchs publiés n’est pas une preuve de l’un de ces statuts.
4. Conserver la référence de source (nom du fichier, ligne/numéro ou URL officielle), sa date et la décision du club. Ne pas créer une fausse rencontre, un faux adversaire « Exempt » ou un ID FFBB fictif dans matches.
5. Après validation du principe, choisir le support minimal des informations validées et leur affichage dans le calendrier. Aucune nouvelle table, fonction, import ou interaction n’est créée par cette proposition.
