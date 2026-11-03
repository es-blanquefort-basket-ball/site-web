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

Avant cette intervention, le code d'affichage rejetait une ligne dont l'heure était absente et affichait 00:00 comme 00h00. Une adaptation minimale est désormais préparée dans `calendrier.js` : les heures absentes/blanches et 00:00 (avec secondes nulles éventuelles) deviennent « Horaire à confirmer » ; la date et la rencontre sont conservées. Les heures renseignées gardent leur affichage. Un `span` remplace la balise `time` pour le texte d'heure inconnue. La lecture REST et les liens restent identiques. Le traitement s'applique à toutes les lignes de la vue, sans supposer des codes MiniBasket non encore validés. La vue et les tables doivent encore accepter et transmettre une heure nulle ; ne pas contourner cette limite en créant une heure fictive.

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

## Suite de l'audit : archive et accès Supabase

L'archive annoncée `exports_FBI_minibasket_Codex_2026-11-03.zip` n'est pas présente dans les pièces jointes disponibles, le dépôt ou la recherche ciblée des téléchargements. Les 24 lignes et la liste des 11 heures inconnues ne sont donc toujours pas produites. Le total 24 + 1 et le nombre 11 sont des contrôles fournis par le club, pas des résultats recalculés sur les sources.

La recherche locale de scripts/SQL/configuration et l'historique Git des commits ayant introduit Supabase ne montrent que le lecteur public. La recherche GitHub accessible sur `public_calendar` dans l'organisation ne fournit pas d'autre résultat. Aucun connecteur Supabase n'est disponible et l'ouverture du projet dans le navigateur mène à un écran de connexion. L'emplacement de l'import amont reste **non identifié** ; cela ne prouve pas son absence hors du dépôt. La nouvelle vérification REST confirme HTTP 200 pour les mêmes 33 lignes et HTTP 401 pour OpenAPI. Aucun changement de sécurité ni tentative d'écriture.

### Procédure administrateur, sans transmettre de secret

1. Se connecter soi-même au tableau de bord Supabase et sélectionner le projet du club dont la référence est `fgswygeqstgagmipltpq`, celle déjà déclarée dans le lecteur public. Ne pas utiliser un autre projet.
2. Ouvrir le SQL Editor et exécuter les trois requêtes SELECT du fichier `DIAGNOSTIC_SUPABASE_MINIBASKET.sql`, préparées pour lecture des seules métadonnées. Elles donnent la définition de `public.public_calendar`, ses relations dépendantes, leurs colonnes/types/nullabilité/défauts, contraintes, index, noms de politiques et déclencheurs. Elles ne créent ni table ni fonction et ne lisent pas les lignes métier. Ce script n'a pas été exécuté sur le serveur, faute de session administrateur.
3. Vérifier les résultats avant partage : retirer tout éventuel littéral sensible présent dans une définition/défaut. Transmettre uniquement les résultats utiles au calendrier, sans export de comptes, licenciés, secrets ou données privées.
4. Rechercher l'origine des imports Seniors dans les requêtes enregistrées de ce projet (noms/mots-clés des relations identifiées, import FFBB), dans les tâches Cron configurées et les noms des Edge Functions, puis dans le dépôt ou outil externe du responsable de l'import. Communiquer le chemin du script, son mode de lancement et sa configuration sportive expurgée. Ne pas transmettre de variables d'environnement, jetons, commandes contenant des secrets ou journaux complets. La vue seule ne permet pas de localiser un import exécuté depuis un poste externe.
5. Confirmer la table cible et la correspondance des cinq équipes (codes/identifiants sportifs uniquement). Si les tables de correspondance ne dépendent pas directement de la vue, transmettre leur définition ciblée et les seules cinq correspondances nécessaires, après vérification de leur caractère non personnel.
6. Identifier la contrainte unique ou l'identifiant stable réellement utilisé. Le rapprochement proposé reste `(saison, compétition, phase, poule si nécessaire, numéro de rencontre, équipe FBI concernée)` tant que les fichiers et la clé existante ne sont pas examinés. La portée exacte doit être validée : ne jamais choisir la compétition seule pour les deux U9 garçons. Une rencontre interéquipes du club ne doit pas être dupliquée dans le stockage si le modèle existant représente un match physique unique.
7. Après réception des exports, préparer le tableau des 24 rencontres, l'exclusion, la liste des 11 heures à confirmer et les écarts avec les lignes déjà stockées. L'aperçu doit distinguer créations, mises à jour, inchangés et conflits. La cible de conflit et les colonnes mises à jour d'un éventuel upsert seront fixées à partir du schéma réel, pas inventées. Exécuter seulement après validation humaine via l'import existant ; deuxième passage attendu : zéro création supplémentaire. Aucune requête INSERT/UPDATE/UPSERT exécutable n'est fournie avant cette vérification.

Références de la procédure : [tables et SQL dans Supabase](https://supabase.com/docs/guides/database/tables), [fonctions de description PostgreSQL](https://www.postgresql.org/docs/current/functions-info.html). Le schéma nécessaire est un export ciblé de métadonnées, pas un nouveau schéma à créer.

### Tests de l'adaptation d'affichage

- `node validation/calendrier-horaires.cjs` : passage des heures nulles/absentes/blanches, 00:00, 00:00:00 et fractions nulles ; date préservée et texte « Horaire à confirmer ». Heures renseignées 10:30, 14:00, 19:00 et 00:30 inchangées ; aucun lien FFBB construit. Les noms utilisés sont des fixtures de test, pas des rencontres du club.
- Test navigateur local isolé avec trois lignes **simulées**, hors dépôt et sans appel Supabase : une heure nulle, 00:00:00 et 14:30:00. Aux largeurs 390, 768 et 1440 px, trois cartes visibles avec deux libellés « Horaire à confirmer » et un « 14h30 », sans débordement horizontal mesuré. Capture conservée hors dépôt.
- Test navigateur séparé avec le vrai flux public : détail du 8 novembre, SG2 à 12h00 et SG1 à 14h00, adversaires/salles/liens affichés ; aucune erreur console relevée. Ce contrôle est une lecture réelle, pas un test d'import.
- Syntaxe JavaScript et `git diff --check` réussis. Accueil, Équipes, Planning, liens Seniors et calendrier HTML conservés. Aucune donnée de production modifiée ; compatibilité SQL et idempotence réelle de l'import encore non testées.
