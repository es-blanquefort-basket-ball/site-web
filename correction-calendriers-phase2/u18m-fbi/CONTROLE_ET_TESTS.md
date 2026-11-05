# U18M — import contrôlé FBI

Préparation locale du 4 novembre 2026. Aucun appel Supabase ni publication Hostinger.

## Script à contrôler

`IMPORT_U18M_FBI.sql` livre les cinq rencontres validées de `rechercherRencontre.xlsx`, A2:G6, sans colonnes de scores :

| FBI | Date | Heure Paris | Domicile/extérieur | Adversaire | Salle |
| --- | --- | --- | --- | --- | --- |
| 15 | 08/11/2026 | 11:00 | Extérieur | STE EULALIE BASKET BALL | Salle Valériane Ayayi |
| 16 | 15/11/2026 | 11:00 | Domicile | IE - CTC BASKET HAUTE GIRONDE - BASKET CLUB ESTUAIRE GIRONDE - 1 | SALLE PORT DU ROY |
| 20 | 29/11/2026 | 11:00 | Domicile | UNION SPORTIVE BAZAS - 2 | SALLE PORT DU ROY |
| 23 | 06/12/2026 | 11:00 | Extérieur | COUTRAS GUITRES BASKET - 2 | SALLE DOURSAT |
| 26 | 13/12/2026 | 11:00 | Extérieur | LES PETITS MOUSSES LANGOIRAN - 2 | SALLE RENE BAILLET |

Origine : `esbb_u18m_fbi`. Saison : `2026-2027`. Clé : `DMU18-4-P2|U18M|15` (puis 16, 20, 23, 26). La date, l’heure, l’adversaire, la salle et l’ordre des lignes ne font pas partie de la clé. Un index unique partiel protège `(season_scope, source_match_key)` pour cette origine, même avec `ffbb_match_id=NULL`.

Les cinq `ffbb_match_id` et `ffbb_match_url` restent NULL. Aucun choix parmi les 13 variantes, aucun numéro FBI placé dans le champ ID FFBB. Pas de score, adresse de salle ou journée inventée : `venue_address_raw`, `venue_id` et `round_label` restent NULL faute de champ correspondant dans l’export utilisé.

U18M est créé uniquement s’il manque, avec `is_public=true`, `is_competition_active=false`, `ffbb_team_id=NULL`. Un parent existant public et inactif est conservé intégralement. Un parent privé ou actif, ou des rencontres U18M préexistantes hors lot, provoquent un refus pour revue. Aucun changement automatique de ces données. L’import initial est volontairement strict : lot complet de cinq, ou aucune ligne.

## Vérification et application

La seule ligne de commande interne est livrée ainsi :

```sql
INSERT INTO u18_options VALUES ('verify',false);
```

- `verify` : contrôle les cinq sources et les 57 publications protégées ; affiche le plan et le nombre de lignes intactes. Tables/vues temporaires seulement, aucun index persistant ni donnée persistante créés. Après import, vérifie aussi les cinq publications U18M.
- `import` : requiert `approved=true`, à sélectionner uniquement après revue et autorisation humaine de l’écriture. Crée le parent manquant, les cinq lignes et l’index de provenance ; adapte `public_calendar` dans la même transaction. Une relance identique n’insère rien. Toute correction du club, nouvel export différent, provenance déjà utilisée ou ID canonique ajouté fait refuser la relance plutôt que l’écraser.
- `rollback` : requiert également `approved=true`, après revue et autorisation. Ne supprime que les cinq UUID retrouvés par cette origine/saison/clé/lot et intégralement inchangés. Refuse après correction, rapprochement canonique ou évolution de la vue. Supprime le parent uniquement s’il a été créé par ce lot, est inchangé et vide. Un parent préexistant reste en place. Restaure la définition exacte de la vue antérieure. L’index unique dédié reste installé pour éviter un futur doublon.

Avant une application distante autorisée : conserver une sauvegarde des tables concernées et de la définition/droits/options de la vue, lancer `verify`, contrôler le plan puis faire valider le passage à `import`. Aucune opération de production effectuée ici. Les scripts MiniBasket, phase 2 et leurs modes existants restent inchangés.

## Compatibilité avec MiniBasket et protection des corrections

La vue existante entière, comprenant l’extension MiniBasket, est réutilisée comme branche historique. Seuls les UUID de l’origine U18M sont remplacés dans une nouvelle branche ; aucune jointure de remplacement par date/adversaire. Les vraies colonnes ID, équipe, compétition, starts_local, status, updated_at, date, heure et salle sont conservées. Les scores supplémentaires restent NULL pour les nouvelles lignes.

La vue garde colonnes/types/ordre/OID/droits/options. Une transaction avec verrous compare toutes les rencontres hors lot, tous les parents préexistants et toutes leurs publications avant/après. Les 57 UUID de référence doivent rester présents. Toute différence annule l’opération. Les overrides et corrections courantes sont inclus dans ces comparaisons complètes.

Le code public existant peut afficher les U18M via `team_code='U18M'`, dates et heures sans lien de fiche FFBB. Les cinq horaires sont connus ; aucune adaptation HTML/JS n’est nécessaire pour ces données. Le comportement public réel après import restera à vérifier lors de l’exécution autorisée.

La garantie concerne cette transaction et les relances de ce script. Aucune intervention sur `ffbb-sync`, son cron ou les autres imports. U18M inactif reste hors du chemin historique ; aucune automatisation n’est ajoutée.

## Rapprochement canonique et nouveaux exports

Lorsqu’une preuve officielle établira FBI numéro ↔ ID FFBB canonique : préparer un aperçu ciblé par **origine + saison + clé FBI**, conserver le même UUID, examiner toute collision sur `ffbb_match_id`/URL et toute rencontre existante. Après validation distincte seulement, enrichir la ligne et historiser la correspondance et sa preuve dans la provenance. Ne pas recréer une rencontre et ne pas changer sa clé FBI. Les corrections du club restent prioritaires.

Le script initial bloque volontairement les lignes enrichies ou modifiées : son retour arrière ne pourra pas effacer ce rapprochement. Un nouvel export nécessite une comparaison au `provider_baseline` et à la ligne courante, une approbation des champs modifiés et un contrôle sous verrou ; il ne s’applique pas en remplaçant le lot d’entrée silencieusement. Aucun SQL de rapprochement arbitraire n’est livré.

## Tests locaux effectués

Base PGlite uniquement, sans réseau/SDK Supabase :

1. Création de 33 rencontres de référence, puis exécution du véritable `IMPORT_MINIBASKET.sql` dans la base locale : 57 rencontres. Reconstitution des UUID de référence dans les fixtures et vérification MiniBasket réussie.
2. Correction club préexistante simulée hors U18M. Sauvegarde complète des 57 lignes, publications, équipes et métadonnées/définition de vue.
3. `verify` sans effet persistant ; `import` sans autorisation refusé.
4. **57 → 62** : les cinq clés FBI, dates, horaires, salles et le parent inactif sont conformes ; IDs FFBB et scores NULL. Les 57 lignes/publications et équipes préexistantes restent identiques, y compris la correction club et les horaires MiniBasket inconnus.
5. Relance : mêmes UUID, mêmes données, aucune sixième ligne. Insertion avec clé FBI dupliquée refusée par l’index.
6. Import et retour refusés après correction U18M ; retour refusé après ajout simulé d’un ID canonique. Import avec nouvelle salle et retour avec vue modifiée refusés.
7. **62 → 57** : restauration exacte des 57 lignes, des équipes préexistantes, de toutes leurs publications et de la vue (définition/OID/droits/options).
8. Parent U18M préexistant compatible : conservé à l’import puis au retour. Parent actif et rencontre U18M hors lot : refus sans écrasement.
9. Les cinq lignes SQL sont comparées au JSON extrait de l’export validé. `git diff --check` réussi.

Commande de reproduction depuis la racine du dépôt :

```sh
/Users/laurence/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node \
  correction-calendriers-phase2/u18m-fbi/test-u18m.cjs
```

Dépendances de test : mêmes versions épinglées et chargeur que `../tests/`. Résultats simulés localement, pas une exécution sur Supabase. Aucun fichier public ni script d’import précédemment validé modifié.
