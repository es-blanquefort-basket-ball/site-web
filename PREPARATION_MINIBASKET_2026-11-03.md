# MiniBasket — préparation de l'intégration

Branche : `codex/audit-horaires-calendriers`, reprise du commit `6eb5992`.
Document de revue, à conserver hors de la livraison Hostinger.

## Données confirmées par le club

| Équipe distincte | Compétition FBI | Export attendu | Rencontres | Exemptions |
| --- | --- | --- | --- | --- |
| U9 filles | DFU9-10-P2 | (16) | 5 | 0 |
| U9 garçons 1 | DMU9-10-P2 | (21), BLANQUEFORT - 1 | 5 | 0 |
| U9 garçons 2 | DMU9-10-P2 | (21), BLANQUEFORT - 2 | 5 | 0 |
| U11 garçons 1 | DMU11-4-P2 | (18) | 4 | 1 |
| U11 garçons 2 | DMU11-10-P2 | (17) | 5 | 0 |
| **Total attendu** | | | **24** | **1** |

Ces totaux viennent de la demande du club. Ils n'ont pas encore été recomptés dans les fichiers : aucun export XLS/XLSX/CSV n'est disponible dans le dépôt ou les pièces jointes examinées le 3 novembre 2026.

## Page Équipes

Les deux fiches génériques U9/U11 sont déclinées en cinq fiches nommées, avec les composants existants, leur compétition confirmée et le statut Compétition. Les horaires existants sont conservés et explicitement intitulés « Créneaux de la catégorie U9/U11 » : aucun horaire spécifique d'équipe n'est déduit des exports absents. Aucun coach, lien FFBB ou résultat n'est ajouté. U5, U7 et toutes les autres équipes sont conservés.

L'accueil, les horaires U18/SG2 et les liens FFBB précédemment vérifiés restent inchangés.

## Mécanisme actuel et compatibilité

`calendrier.html` charge `calendrier.js`. Celui-ci lit la vue publique Supabase `public_calendar` via REST, avec la clé publishable publique déjà utilisée par le site. La requête filtre le mois sur `local_date`, trie par date et heure et affiche toutes les équipes reçues.

Lecture réelle de la vue le 3 novembre 2026 : 33 lignes (Content-Range 0-32/33), SG1 10, SG2 10, U13F 5, U13M 4, U15M 4. Aucune des cinq équipes MiniBasket ne figure dans cette réponse.

La consultation du schéma OpenAPI public a reçu HTTP 401. Le dépôt ne contient pas la définition SQL, les tables d'écriture, leurs contraintes, les correspondances d'équipes ni le code de l'import existant. Le contrat de lecture est identifié ; **la compatibilité du schéma d'écriture n'est pas encore vérifiable**. Aucun droit supplémentaire ni secret n'a été recherché.

| Champ de lecture actuel | Normalisation à préparer à partir des exports | Validation requise |
| --- | --- | --- |
| team_code | Identité distincte de chacune des cinq équipes | Correspondance avec les codes/identifiants existants à fournir ; division seule interdite comme identifiant |
| opponent_name | Adversaire exact de la ligne source | Vérifier quelle équipe est le club à domicile ou à l'extérieur ; Exempt exclu |
| home_away | home ou away selon les colonnes recevant/visiteur | Conserver BLANQUEFORT - 1 et BLANQUEFORT - 2 distincts |
| local_date | Date réelle de la rencontre au format ISO | Vérifier le format Excel et la date d'origine ; aucune date déduite |
| local_time | Heure confirmée, sinon null proposé | 00:00 signifie heure non renseignée dans ce périmètre ; nullabilité et conversion de la vue à contrôler |
| venue_name / venue_address | Valeurs exactes disponibles, sinon absence de valeur | Ne pas compléter une adresse ou une salle par supposition |
| round_label | Journée si fournie | Préserver sa valeur source |
| ffbb_match_url / ffbb_team_url | null si aucun lien officiel fourni et vérifié | Ne pas construire de lien à partir d'un numéro FBI |

Le code d'affichage actuel rejette une ligne dont l'heure est absente et affiche 00:00 comme 00h00. Avant toute intégration, il faudra convenir du traitement dans la vue et adapter ce rendu pour accepter une heure inconnue et afficher « Horaire à confirmer ». Ne pas contourner cette limite en créant une heure fictive. Aucune modification de ce comportement n'est réalisée sans les données et le schéma nécessaires.

Le contrat de lecture actuel ne sélectionne aucun score. Les valeurs 19 ne doivent être ni converties en score validé, ni déplacées dans un autre champ métier. Leur colonne et leur signification restent à examiner dans les exports.

## Règles de rapprochement dans l'import existant

1. Lire les quatre exports (16), (21), (18), (17), inventorier feuilles et colonnes, conserver les références fichier/feuille/ligne dans le dossier de contrôle.
2. Pour (21), sélectionner l'équipe par son nom FBI complet et son éventuel identifiant officiel. La compétition DMU9-10-P2 est commune aux deux équipes : elle ne suffit jamais au rapprochement.
3. Isoler la ligne Exempt de U11 garçons 1 dans le relevé des exclusions. Ne créer ni rencontre ni adversaire « Exempt » dans le calendrier.
4. Recompter les rencontres par équipe puis le total : 24 rencontres et 1 exclusion attendues. Toute différence ou ambiguïté bloque l'écriture.
5. Si un identifiant de rencontre officiel existe, utiliser celui-ci avec sa portée et l'identité d'équipe pour le rapprochement. Sinon, proposer une clé candidate comprenant saison, équipe FBI complète, compétition/phase/poule si présentes et numéro de rencontre. Vérifier son unicité avant d'en faire une clé d'import.
6. En l'absence d'identifiant stable, utiliser date, équipes recevant/visiteur et journée uniquement pour rechercher des correspondances candidates. Ne pas supprimer/fusionner automatiquement deux lignes ressemblantes ; signaler les conflits. Une modification d'horaire ou de salle ne doit pas créer un nouveau match.
7. Comparer les candidats aux rencontres déjà stockées par le mécanisme existant. La vue publique ne suffit pas à prouver l'absence de lignes privées/non publiées. Préparer les listes créations, mises à jour, inchangés, exclusions et conflits.
8. Présenter l'aperçu normalisé réel (équipe, référence source, date, heure ou statut inconnu, adversaire, domicile/extérieur, salle, journée, clé candidate et action proposée). Attendre validation humaine avant toute écriture.
9. Après validation du schéma et des données, réutiliser l'import existant. Vérifier qu'un second passage des mêmes données ne crée aucune rencontre supplémentaire et que les autres matchs/événements sont préservés.

## Aperçu et blocages

**Aucune ligne de rencontre normalisée n'est produite à ce stade**, car dates, adversaires, salles, heures et numéros de rencontre ne sont pas fournis. Le tableau ci-dessus est une préparation du mapping, pas un aperçu d'import validé.

À fournir pour poursuivre :

- Les quatre exports Excel (16), (21), (18), (17), comprenant les deux équipes U9 garçons du fichier (21).
- La définition de `public_calendar`, le schéma des tables cibles et leurs contraintes, ainsi que les correspondances des cinq équipes et le code/configuration de l'import existant (sans secret).
- La validation de l'aperçu réel et du traitement des heures inconnues avant toute écriture Supabase.

Aucun système d'import, calendrier parallèle, fichier de rencontres fictives ou écriture Supabase n'est créé. Aucune fusion dans main ni publication Hostinger n'est effectuée.

## Vérifications de cette préparation

- Cinq fiches distinctes présentes une seule fois dans le HTML et dans le navigateur.
- Page rechargée à 390, 768 et 1440 px : aucun débordement horizontal ni image manquante détecté ; aucune erreur console relevée. Fiches examinées visuellement sur ordinateur et mobile.
- Comparaison avec `6eb5992` : liens FFBB identiques ; cartes U5, U7, U13F, U13M, U15M, U18, SG1 et SG2 identiques ; accueil, calendrier, planning, styles et scripts inchangés.
- `git diff --check` réussi. Aucun test d'import réel possible avant réception des exports et du schéma d'écriture. Aucun contrôle sur téléphone physique effectué.
