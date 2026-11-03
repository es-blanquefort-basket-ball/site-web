# Audit horaires et calendriers — ES Blanquefort Basket

Audit du 3 novembre 2026, branche `codex/audit-horaires-calendriers`, base `885bd84` (main et origin/main identiques après fetch).
Document de revue du dépôt, non destiné à être téléversé sur Hostinger.

## Résultat

Les horaires hebdomadaires U18 et SG2 sont déjà corrects dans main : mercredi 19h00–20h30 au Port du Roy ; vendredi 21h00–22h30 au Béchon. Aucun horaire n'a été modifié.

Les jeunes ne sont pas exclus du calendrier : la vue publique contient leurs matchs de septembre–octobre. Les nouveaux engagements FFBB de phase 2 ne sont pas présents dans cette vue. Les quatre accès directs vérifiés à la phase 2 sont ajoutés sur Équipes et Calendrier. **Cela ne synchronise pas les nouvelles rencontres dans la grille mensuelle.**

## Audit des fichiers

| Fichier vérifié | Constat | Traitement |
| --- | --- | --- |
| `planning.html` | U18 et SG2 : deux créneaux conformes au tableau fourni ; lieux Port du Roy et Béchon | Inchangé |
| `equipes.html` | Même conformité ; anciens liens FFBB jeunes ; U18 encore « Équipe en création / Engagement à venir » | Quatre liens phase 2 ajoutés ; statut métier U18 à valider |
| `inscriptions.html` | Données des fiches U18 et SG2 conformes ; titre U18 et détail U18M | Inchangé ; appellation publique à confirmer |
| `essais.html` | Liste de secours de séances datées de mai–juin 2026, fusionnée par ID avec `getCreneauxEssais` (Google Apps Script) ; U18M jeudi 20h–21h30 au lycée agricole et mercredi 18h–20h30 ; Seniors regroupés, notamment mercredi 20h30–22h30 | Pas de conversion de séances historiques en entraînements hebdomadaires ; dates et distinction SG1/SG2 à faire valider ; source distante non modifiée |
| `index.html` | Aucun créneau U18/SG2 à corriger | Inchangé |
| `script.js` | Comportements communs, pas de source d'horaires U18/SG2 | Inchangé |
| `calendrier.html` | Liens vers cinq engagements historiques, aucun accès U18 | Liens phase 2 pour U13F/U13M/U15M ; carte U18 réutilisant le composant existant |
| `calendrier.js` | Lecture publique Supabase par mois, sans sélection d'équipe ; aucune récupération FFBB directe | Inchangé |
| `matchs.html` | Redirection vers `calendrier.html` | Inchangé |
| `contact.html` | Béchon identifié comme gymnase du lycée Jean Monnet | Inchangé ; pas de renommage ni de modification des liens Maps |
| Documentation | AGENTS, ARBORESCENCE, README, COMPOSANTS, CONVENTIONS consultés ; `CARNET_DE_CONCEPTION_SITE.md` absent | Absence signalée |

L'espace `app/` est hors périmètre et n'a pas été modifié. Aucun autre horaire, tarif, coach, contenu métier ou style n'a été modifié.

## Fonctionnement et données réellement publiées

`calendrier.html` charge `calendrier.js`, qui effectue un GET sur `/rest/v1/public_calendar` du projet Supabase déclaré dans ce script, avec sa clé publishable publique. La requête sélectionne les champs de rencontre, filtre `local_date` entre le premier jour du mois inclus et celui du mois suivant exclu, puis trie par date et heure. Les lignes sans date/heure au format attendu sont écartées.

Lecture réelle de la vue publique, sans filtre de mois : réponse `Content-Range: 0-32/33`, soit 33 lignes, aucune heure absente. Aucun doublon détecté sur la paire `(team_code, ffbb_match_url)` parmi les URL non vides. Ce contrôle ne garantit pas l'absence de doublons ayant des identifiants FFBB différents.

| Équipe | Calendrier trouvé | Connexion actuelle à la grille | Anomalie | Correction réalisée / donnée manquante |
| --- | --- | --- | --- | --- |
| SG1 | FFBB `200000005338623` | 10 matchs, du 20/09 au 13/12/2026 | Aucune anomalie de connexion constatée | Préservée |
| SG2 | FFBB `200000005365625` | 10 matchs, du 20/09 au 13/12/2026 | Aucune anomalie de connexion constatée | Préservée |
| U13F | Ancien `200000005370982` ; phase 2 `200000005408294` | 5 matchs, du 19/09 au 17/10/2026 | Phase 2 absente de la vue | Lien direct phase 2 ajouté sur les deux pages ; raccordement amont à effectuer |
| U13M | Ancien DMU13-5 `200000005371520` ; phase 2 DMU13-4 `200000005416665` | 4 matchs, du 26/09 au 17/10/2026 | Phase 2 absente ; deux engagements visibles sur la fiche club | Lien phase 2 ajouté sans supprimer l'ancien ; correspondance à conserver explicitement dans l'import |
| U15M | Ancien `200000005371206` ; phase 2 `200000005414841` | 4 matchs, du 19/09 au 17/10/2026 | Phase 2 absente de la vue | Lien direct phase 2 ajouté sur les deux pages ; raccordement amont à effectuer |
| U18 / U18M | Phase 2 DMU18-4 `200000005419968` | Aucune ligne | Engagement FFBB trouvé, mais statut local « en création » | Lien direct ajouté sur les deux pages ; statut, libellé public et code de correspondance Supabase à valider |
| U9 | Aucun engagement identifié dans les sources examinées | Aucune ligne | Page Équipes annonce des matchs après Toussaint | Source officielle des plateaux/rencontres et identifiant requis |
| U11 | Aucun engagement identifié dans les sources examinées | Aucune ligne | Même constat que U9 | Source officielle des plateaux/rencontres et identifiant requis |
| U5, U7 | Aucun calendrier identifié | Aucune ligne | Groupes présentés comme essais ; pas de preuve d'engagement | Ne pas supposer l'existence d'un calendrier ; besoin à confirmer |
| U15F | Aucun engagement autonome identifié | Aucune ligne | Catégorie présente dans le parcours d'essais, orientée vers U13F | Engagement autonome et source à confirmer avant toute connexion |
| U21 | Aucun engagement identifié | Aucune ligne | Catégorie présente dans les essais historiques | Existence d'une équipe engagée et source à confirmer |
| Loisirs | Aucun calendrier identifié | Aucune ligne | Section de pratique, pas de compétition identifiée | Source d'événements éventuelle à fournir |

U9F/U9M et U11F/U11M sont mentionnés dans la cartographie documentaire, mais les pages actuelles regroupent U9 et U11. Aucun engagement distinct n'a été déduit de cette documentation.

Le navigateur confirme 12 rencontres en octobre (dont les trois jeunes le 17 octobre) et 8 en novembre (Seniors seulement). La vue n'alimente actuellement que des matchs : bien que le rendu prévoie des groupes entraînements/événements, le normaliseur donne toujours `type: 'match'`. Aucun flux événement distinct n'est configuré dans ce script. Aucun flux, événement ou match existant n'a été supprimé.

## Sources FFBB vérifiées

La [fiche officielle du club](https://competitions.ffbb.com/ligues/naq/comites/0033/clubs/naq0033034) ouverte en navigateur affiche les engagements de phase 2. Les résultats web indexés étaient partiellement anciens ; la vérification finale repose sur les pages affichées en navigateur.

| Équipe | Calendrier de phase 2 | Phase | Poule |
| --- | --- | --- | --- |
| U13F | [200000005408294](https://competitions.ffbb.com/ligues/naq/comites/0033/clubs/naq0033034/equipes/200000005408294) | 200000002902208 | 200000003064585 |
| U13M | [200000005416665](https://competitions.ffbb.com/ligues/naq/comites/0033/clubs/naq0033034/equipes/200000005416665) | 200000002902520 | 200000003065651 |
| U15M | [200000005414841](https://competitions.ffbb.com/ligues/naq/comites/0033/clubs/naq0033034/equipes/200000005414841) | 200000002902453 | 200000003065402 |
| U18 | [200000005419968](https://competitions.ffbb.com/ligues/naq/comites/0033/clubs/naq0033034/equipes/200000005419968) | 200000002902228 | 200000003064624 |

Les pages FFBB présentent des rencontres de novembre–décembre. Plusieurs entrées U13F/U18 se répètent visuellement ; certaines heures U13F/U13M/U15M valent 00h00 ou 01h00. Ne pas les interpréter automatiquement comme des horaires confirmés ni fusionner des matchs uniquement sur leur date/adversaire. L'import existant doit être examiné pour utiliser les identifiants de rencontre et arbitrer ces anomalies.

Les 15 anciens liens équipe/classement/poule et les quatre nouveaux liens de calendrier ont été ouverts en navigateur : pages FFBB correspondant aux équipes/compétitions attendues. Les requêtes HTTP automatisées avaient reçu 403 sur plusieurs URL ; cela ne constituait pas une preuve de lien cassé. Les anciens liens sont conservés à l'identique, y compris les paramètres phase/poule/journée.

## Raccordement restant à préparer dans le système existant

Le dépôt ne contient ni schéma SQL de la vue, ni fonction d'import FFBB, ni configuration d'équipes de cet import, ni tâche de synchronisation. La méthode d'affichage Seniors est réutilisée automatiquement pour toute ligne présente dans la vue, mais la méthode d'alimentation en amont n'est pas identifiable dans ce checkout.

Pour compléter la grille mensuelle, fournir l'emplacement du code/configuration de l'import existant et la définition de `public_calendar` (sans transmettre de secret). Y ajouter les quatre engagements vérifiés après contrôle des correspondances, conserver les données historiques et les autres événements, puis vérifier l'idempotence de l'import et les horaires. Aucun accès aux tables privées, aucune écriture Supabase, aucun nouveau synchroniseur n'a été tenté.

## Vérifications

- Recherche des occurrences U18/U18M, SG2, Seniors, horaires et gymnases dans le site public : aucune ancienne occurrence « mercredi 19h30–21h00 » pour U18/SG2 dans les trois pages d'entraînements actuels. Les différences des essais datés sont signalées ci-dessus.
- Serveur local HTTP et vrai flux public Supabase, sans données de match simulées.
- Avant modification : Planning, Équipes, Inscriptions et Calendrier consultés à 390, 768 et 1440 pixels ; pas de débordement horizontal mesuré. Menu mobile Planning ouvert/fermé.
- Après modification : Équipes et Calendrier rechargés à 390, 768 et 1440 pixels ; quatre liens phase 2 présents dans chaque page ; largeur du document inférieure ou égale à la largeur de fenêtre. Cartes Calendrier U15M/U18/Seniors examinées visuellement sur mobile.
- Calendrier après modification : navigation novembre vers octobre, affichage des trois rencontres jeunes du 17 octobre, ouverture/fermeture du panneau de détail ; aucune erreur console relevée dans ce contrôle.
- Aucune image manquante détectée sur les pages contrôlées. Vérification statique des liens ajoutés et du diff ; JavaScript et CSS inchangés.
- Pas de validation sur téléphone physique/Safari. Pas d'envoi du formulaire d'essai, pas de modification ni de test d'écriture du backend.

## Livraison et points à valider

Diff applicatif : 15 lignes ajoutées, uniquement dans `equipes.html` et `calendrier.html`. Le présent rapport complète la revue. Aucun changement à `planning.html`, `inscriptions.html`, `essais.html`, `calendrier.js`, `script.js`, `style.css` ou `app/`.

À valider : raccordement de phase 2 dans l'import existant, ambiguïtés horaires/doublons FFBB, statut et appellation U18/U18M, séances d'essai historiques et sources U9/U11. La PR doit rester sans fusion jusqu'à validation du club ; aucun fichier n'est publié sur Hostinger.
