# SITE-M01 — préparation du raccordement au planning de Magali

État : conception et tests hors ligne. Aucune écriture Supabase ou dans le classeur
original. La copie de test est `1RDaMSDMJL5UNArmKaUnsBfEAv70RZHE1eeuosZ5mvyE` ;
l'original est `1oEJYJ-4z3dwoKeu7W6zBdbLcg467rAf81h6Xuvs1wZw`.

## Constat sur les trois onglets

| Onglet | Rôle constaté | Raccordement prévu |
| --- | --- | --- |
| `rencontre du 07-11 au 13-12` | Une ligne par rencontre, A:L : division, numéro de match, équipes, date E, heure F, salle G, e-Marque H, scores et forfaits I:L. 67 lignes renseignées dans A1:M250 ; certaines dates/heures/salles sont absentes. | Seul onglet pouvant échanger E:G avec SITE-M01 Gestion. H:L intouchables. |
| `brassage` | Blocs par date et domicile/extérieur ; affectations et bénévoles F:M, notes et dérogations en O et autour. Plusieurs heures D sont des formules. | Lecture pour signaler les affectations à revoir. Aucun écrasement ni déplacement automatique de bloc. |
| `Indiv` | Blocs par date et rencontres, avec des heures D parfois calculées par formule. | Lecture de contrôle uniquement ; aucune écriture de planning dans cette préparation. |

Le numéro de match n'est pas unique : `6` et `9` apparaissent chacun dans trois
divisions distinctes. Les libellés et les dates peuvent changer. Ils ne sont donc pas
des identifiants de synchronisation.

## Identité et rapprochement initial

- Identifiant canonique : UUID `public.matches.id`, identique à `public_calendar.id`.
- Registre privé de liaisons : `(match_id, spreadsheet_id, sheet_id, row_index,
  last_shared_date, last_shared_time, last_shared_venue, management_revision,
  sheet_fingerprint, sync_status)`. Unicité de `match_id` et de la cellule de liaison
  dans l'onglet principal. Le numéro FBI reste une information de rapprochement.
- Construire une liste de candidats à partir de division, équipes, domicile/extérieur,
  date et numéro FBI. Accepter une liaison uniquement après vérification du match UUID
  correspondant dans Supabase. Signaler les ambiguïtés, les lignes sans horaire et les
  rencontres absentes. Ne jamais inventer d'UUID.
- Une fois les liaisons validées, tester sur la copie une colonne dédiée à l'UUID dans
  l'onglet principal (M est vide dans l'échantillon examiné), sans modifier A:L. Vérifier
  toute la colonne avant insertion dans l'original : l'échantillon ne prouve pas qu'elle
  est vide sur les 1 000 lignes. Le registre privé reste nécessaire si les lignes bougent.

## Échange des horaires et salles

1. Lire la ligne Sheets et SITE-M01 avec leur dernier état partagé. Convertir date et
   heure françaises en valeurs locales `Europe/Paris` ; ne pas traiter `00:00` comme un
   horaire confirmé sans indication explicite.
2. Comparer séparément date, heure et salle. Une modification d'un seul côté devient
   une proposition vers l'autre côté. Deux modifications incompatibles du même champ
   deviennent un conflit à arbitrer. Les champs hors E:G sont exclus du patch.
3. Sheets → Supabase : utiliser la façade Gestion `site_m01_save_management` avec
   `p_revision=management_revision` relue juste avant l'écriture. Ne modifier que les
   overrides `scheduled_local_override` et `venue_name_override` via cette façade ;
   vérifier ensuite la relecture privée et `public_calendar`.
4. Supabase → Sheets : relire E:G et leur empreinte juste avant écriture. N'écrire que
   les cellules modifiées sur la copie, puis relire les cellules et les formules voisines.
   Une écriture réelle exige un médiateur unique et un verrouillage des champs E:G :
   l'API Sheets ne fournit pas ici de compare-and-swap atomique contre une saisie humaine
   simultanée. Sans ce contrôle, bloquer la synchronisation automatique et présenter
   une proposition à confirmer.
5. Enregistrer le nouvel état partagé seulement après confirmation des deux côtés.
   Une panne intermédiaire reste « en attente » ; une reprise compare de nouveau les
   versions. Ne pas appliquer en boucle une valeur ancienne.

Les changements SITE-M01 Gestion restent prioritaires pour la référence Supabase,
mais une saisie Sheets concurrente n'est jamais écrasée silencieusement. SITE-M01 Live
reste exclusivement dans Supabase. Le calendrier public continue de lire Supabase.

## Week-ends, dérogations et réimports

- Si la date traverse le vendredi de référence d'un week-end, marquer les affectations
  `à revoir` pour l'ancien et le nouveau week-end. Conserver les personnes, notes et
  formules telles quelles jusqu'à décision humaine ; ne pas déplacer automatiquement
  des lignes des onglets `brassage` ou `Indiv`.
- Les textes de la zone « DEROGATIONS » sont des demandes ou des notes libres, même
  lorsqu'ils mentionnent une acceptation. Une modification de calendrier est officielle
  seulement après confirmation par la source de référence Supabase et, si nécessaire,
  par le circuit administratif du club. Aucun texte libre ne devient un override.
- Un réimport FBI peut modifier les colonnes sources. Il ne doit pas effacer les
  overrides SITE-M01. Si la source change pendant qu'un override ou une liaison Sheets
  existe, bloquer la propagation automatique, relire `public.matches.id`, comparer
  source/override et demander une revue. Le numéro FBI seul ne peut jamais réattribuer
  une liaison.

## Essais sur la copie

- La copie native a été créée et relue : les trois onglets et leurs `sheetId` sont
  conservés ; les formules observées dans `brassage` et `Indiv` sont présentes.
- Le module `sheets-sync-core.mjs` calcule un plan sans réseau ni écriture. Son test
  couvre UUID obligatoire, collisions de liaison, aller/retour des trois champs,
  conflit, changement de week-end et changement de source FBI.
- Avant toute écriture sur la copie : obtenir les UUID réels par lecture autorisée de
  Supabase, valider les correspondances ligne par ligne, inventorier M1:M1000 et les
  cellules E:G concernées, puis tester les conflits et les reprises sur des lignes
  fictives isolées. L'original et la production restent hors du banc d'essai.
