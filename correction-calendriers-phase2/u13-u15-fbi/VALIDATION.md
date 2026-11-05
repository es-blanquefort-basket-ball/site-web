# Lot FBI U13F / U13M / U15M — contrôle et validation locale

Préparé le 4 novembre 2026. **Aucune écriture Supabase ni publication Hostinger.** Les seuls appels distants sont des GET de lecture des données sportives. Aucun appel à ffbb-sync, aucun cron modifié.

## Livrable et source

`IMPORT_U13_U15_FBI.sql` contient un lot unique de 15 rencontres : 5 U13F, 5 U13M, 5 U15M. Les numéros U13F sont 1, 5, 9, 10 et 14 ; les quatre références ambiguës sont donc importées exclusivement sous leurs numéros FBI, sans choix de fiche web.

Source effectivement fournie et lue : `RAPPROCHEMENT_FBI_U13_U15_PHASE2.csv`, validé par le club. SHA-256 calculé : `6d55aea920032c3182b65c4fbaedc9ea395122408d5a6f088b12616dd007d753`.

Les trois XLSX cités ne sont pas présents dans Downloads : aucune relecture directe de leurs cellules ni revérification de leurs empreintes n’est revendiquée. Les noms de fichiers, lignes et SHA-256 d’origine déclarés dans le CSV sont conservés dans la provenance, avec l’empreinte propre du CSV vérifiée. Le contrôle local compare chaque champ importé au CSV disponible.

Les champs de score et d’e-Marque sont entièrement exclus de la sélection d’entrée et de la provenance. Aucun score n’est ajouté. Les colonnes supplémentaires de la branche publique reçoivent NULL si elles ne sont pas explicitement sportives et nécessaires.

## Données attendues

| Équipe | Compétition | Rencontres | Horaires connus | Horaires inconnus | Salles renseignées |
| --- | --- | --- | --- | --- | --- |
| U13F | DFU13-3-P2 | 5 | 2 | 3 | 5 |
| U13M | DMU13-4-P2 | 5 | 1 | 4 | 5 |
| U15M | DMU15-3-P2 | 5 | 3 | 2 | 5 |
| Total | | 15 | 6 | 9 | 15 |

Le script convertit chaîne vide ou `00:00` en heure NULL. Pour les neuf horaires inconnus : `scheduled_local_ffbb`, `scheduled_at_ffbb` et `scheduled_at` restent NULL ; la date officielle est conservée dans `source_data.local_date` et exposée par la vue. Le calendrier existant affiche « Horaire à confirmer ». Les six horaires connus sont convertis avec Europe/Paris, sans décalage de date. Les quinze noms de salles sont repris exactement ; aucune adresse ou UUID de salle n’est inventé.

Tous les IDs et liens de fiche canonique FFBB restent NULL : le CSV ne fournit aucune correspondance canonique prouvée. La clé est `(season_scope, source_match_key)`, par exemple `2026-2027` + `DFU13-3-P2|U13F|5`. La date, l’heure et la salle ne sont pas des composants de l’identité.

## Contrôle réel des doublons avant livraison

- GET `public_calendar` : HTTP 200, **62 publications**, dont les cinq U18M. Les UUID actuels ont été conservés dans `publications-62-lecture-seule.json` et inscrits comme protégés dans le SQL.
- Les 15 lignes du CSV ne présentent aucune collision équipe/date avec ces publications ; les rencontres U13/U15 existantes visibles sont celles de septembre/octobre.
- GET `matches` limité aux UUID des trois équipes, sans scores ni donnée personnelle : HTTP 200, 13 lignes visibles, toutes déjà publiées, sans collision avec les dates du lot. Ces lectures avec les droits publics ne certifient pas l’absence de ligne masquée par RLS. Aucun droit n’a été élargi.
- Le mode `verify`, à lancer dans une session d’administration autorisée avant import, examine **toutes les lignes de matches accessibles à cette session**, publiées ou non. Toute collision de provenance/FBI/équipe-date ou rencontre de même adversaire/sens en phase 2 à une autre date arrête l’opération. Il ne fusionne jamais sur une ressemblance. Aucun nouvel identifiant n’est attribué pour contourner un conflit.

## Équipes et 62 publications protégées

Les trois équipes sont obligatoires et résolues par code **et UUID existant confirmé**. Aucun INSERT/UPDATE/DELETE de teams. Leurs noms, anciennes compétitions, IDs FFBB historiques, URLs et activation restent inchangés. Une équipe absente, privée ou avec un autre UUID fait refuser le script.

La nouvelle branche de `public_calendar` utilise `matches.competition_name` pour afficher la phase 2, sans modifier les parents ni leurs anciennes publications. Toute l’ancienne requête, y compris les extensions MiniBasket et U18M, est conservée dans la branche historique. Les substitutions sont limitées par `matches.id` et la nouvelle origine `esbb_u13_u15_fbi`.

Sous verrou, les anciennes rencontres, toutes les publications hors lot et tous les parents sont instantanés et comparés intégralement après opération. Les 62 UUID protégés doivent toujours être présents. Toute correction du club, override, score existant ou provenance antérieure est conservé. OID/colonnes/types/ordre/droits/options de la vue sont préservés. Les adaptations sont transactionnelles : toute assertion échouée annule l’opération.

Cette garantie porte sur la transaction du script. Elle ne modifie pas et ne certifie pas les effets futurs de l’ancien cron : ne pas lancer ffbb-sync manuellement pour tester ce lot.

## Procédure minimale

Le fichier est livré avec :

```sql
INSERT INTO p15_options VALUES ('verify',false);
```

1. Conserver une sauvegarde des tables concernées et de la définition/droits/options actuels de la vue. Faire valider l’exécution de vérification dans le projet calendrier prévu.
2. Lancer le script inchangé en mode `verify` : plan des 15 clés, collisions et présence des 62 UUID protégés. Objets temporaires uniquement, aucun index ni donnée persistante créé. Un conflit doit être examiné, jamais corrigé par suppression automatique.
3. Après revue du plan et **accord humain explicite pour l’import**, sélectionner `('import',true)`. Résultat attendu si l’état reste compatible : **62 → 77**, 9 dates avec heure NULL, 15 salles. Conserver les sorties UUID/clés/empreintes.
4. Vérifier les trois filtres, les quinze salles et les neuf « Horaire à confirmer » après l’application autorisée. Une relance strictement identique conserve les mêmes UUID et n’ajoute rien.
5. Pour annuler, faire approuver puis sélectionner `('rollback',true)` dans ce même fichier. Le retour supprime uniquement les 15 lignes de ce lot intégralement inchangées et restaure la définition précédente de la vue. Aucun parent supprimé, aucune publication U18M ou MiniBasket retirée. Toute correction, enrichissement canonique, lot incomplet ou modification de vue fait refuser le retour automatique. L’index unique dédié reste installé.

Le script livré n’a pas été exécuté en production, même en mode verify. Les lectures GET décrites ci-dessus sont les seules vérifications distantes.

## Prévention des doublons et corrections ultérieures

Un index unique partiel sur origine + saison/clé empêche deux lignes avec la même provenance, y compris lorsque l’ID FFBB est NULL. Le même lot doit contenir les 15 lignes ; un lot partiel ou déjà modifié est refusé. Aucun UPSERT ne réécrit une ligne existante.

Un nouvel export doit être comparé au `provider_baseline` et aux valeurs courantes, puis ses changements approuvés séparément. `scheduled_local_override` et les corrections directes du club restent prioritaires. Le script initial refuse toute mise à jour silencieuse.

Un futur rapprochement canonique doit enrichir le même UUID identifié par la clé FBI, après preuve officielle et contrôle des collisions sur ID/URL. Ne pas recréer de rencontre et ne pas changer la clé de provenance. Après cet enrichissement, l’import initial et son rollback sont volontairement bloqués pour protéger la nouvelle information.

## Tests locaux exécutés

`test-u13-u15.cjs`, PostgreSQL PGlite uniquement, sans réseau ni SDK Supabase :

- Base constituée de 33 rencontres puis des véritables scripts MiniBasket et U18M exécutés dans la simulation : **62 lignes**. UUID de référence rétablis dans les fixtures locales uniquement.
- Correction club préexistante simulée ; parent U13/U15 avec UUID, activation et ID FFBB historique conservés.
- `verify` sans effet persistant et import sans autorisation refusé.
- **62 → 77 → 62**, restauration exacte des anciennes rencontres/publications/équipes et de la définition/droits/options/OID de vue.
- Quinze salles et six horaires connus exacts ; neuf dates exposées avec heure et timestamps NULL. Aucun score ni ID FFBB ajouté.
- Relance identique sans doublon ; insertion d’une clé de provenance dupliquée refusée par l’index.
- Collision sur équipe/date et collision potentielle sur phase2/adversaire avec date déplacée, même non publiée : refus.
- Correction club, ajout d’un ID canonique, nouvel export différent et vue modifiée : relance/retour refusés selon le contrôle concerné.
- Chaîne vide et `00:00` testées comme deux représentations de l’heure inconnue ; aucune n’est publiée comme minuit.
- Contrôle indépendant des 15 lignes SQL contre les champs autorisés du CSV et `git diff --check`.

Reproduction depuis la racine :

```sh
/Users/laurence/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node \
  correction-calendriers-phase2/u13-u15-fbi/test-u13-u15.cjs
```

Dépendances : chargeur et versions déjà épinglés dans `../tests/`. Les résultats ne constituent ni une exécution ni une validation d’écriture en production. Les scripts d’import précédemment validés n’ont pas été modifiés.
