# Rapprochement phase 2 — collecte du 3 novembre, complément FBI U18M du 4 novembre 2026

Source : resultat-preview-local.json, collectée à 2026-11-03T22:19:51.158Z. SHA-256 : `3552ee9476695a82d707dcea6bb8ca2dbb7428b678b226af24f695a3a6e3fdc4`.
Vérification documentaire locale : 32 vrais IDs numériques distincts présents dans les URL officielles ; engagements, phases/poules et conversions horaires cohérents. Les quatre pages et 32 fiches étaient HTTP 200 dans cette collecte, sans erreur de détail. Aucun nouvel accès réseau : ces résultats ne certifient pas une actualisation ultérieure.

## 11 candidats techniquement admissibles, à approuver par le club

| Équipe | J | ID FFBB | Date | Heure | Adversaire | D/E | Salle |
| --- | --- | --- | --- | --- | --- | --- | --- |
| U13F | J1 | [200000014909687](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dfu13-3/match/200000014909687) | 2026-11-07 | Horaire à confirmer | AS LE HAILLAN | away | Gymnase du Collège |
| U13M | J2 | [200000014890302](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu13-4/match/200000014890302) | 2026-11-14 | Horaire à confirmer | US LE BOUSCAT - 2 | home | Non renseignée |
| U13M | J1 | [200000014890292](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu13-4/match/200000014890292) | 2026-11-21 | Horaire à confirmer | CASTELNAU MEDOC BC | away | GYMNASE CANTERANE |
| U13M | J3 | [200000014890312](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu13-4/match/200000014890312) | 2026-11-28 | Horaire à confirmer | JSA BORDEAUX BASKET - 3 | away | Non renseignée |
| U13M | J4 | [200000014890319](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu13-4/match/200000014890319) | 2026-12-05 | 12:00 | SAM LESPARRE BASKET | away | COSEC |
| U13M | J5 | [200000014890329](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu13-4/match/200000014890329) | 2026-12-12 | Horaire à confirmer | SAINT MEDARD BASKET - 4 | home | Non renseignée |
| U15M | J1 | [200000014884692](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu15-3/match/200000014884692) | 2026-11-07 | 17:00 | UNION SPORTIVE GAURIAC | away | GYMNASE LOUIS REGNIER |
| U15M | J2 | [200000014884702](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu15-3/match/200000014884702) | 2026-11-14 | Horaire à confirmer | BASKET BASSIN D ' ARCACHON - 1 | home | Non renseignée |
| U15M | J3 | [200000014884712](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu15-3/match/200000014884712) | 2026-11-28 | 13:00 | CLUB LEO LAGRANGE LORMONT - 1 | away | Non renseignée |
| U15M | J4 | [200000014884719](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu15-3/match/200000014884719) | 2026-12-06 | 11:15 | B.IZON | away | GYMNASE LES COSTAUDS |
| U15M | J5 | [200000014884729](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu15-3/match/200000014884729) | 2026-12-12 | Horaire à confirmer | US LE BOUSCAT - 2 | home | Non renseignée |

7 horaires inconnus : date conservée, heure et timestamps NULL. 6 salles non renseignées : ne pas en déduire une salle habituelle ; publication possible avec salle à confirmer après accord du club. Les adresses disponibles sont conservées dans les JSON/CSV. Aucun U18M dans ce lot.

## Complément officiel U18M

Export validé par le club : rechercherRencontre.xlsx, feuille rechercherRencontre, A1:G6. SHA-256 : `987ba1f290a4a40817bdba0a7c85a300959ed184fe2c156d828b75f03029f64b`.
Les cinq rencontres DMU18-4-P2, numéros FBI, domicile/extérieur, dates, heures et salles sont confirmés par les cellules A2:G6. L’export ne comporte aucun identifiant long FFBB, hyperlien de fiche ou formule établissant une correspondance. Les colonnes H à L, notamment les scores I et K, sont exclues du rapprochement et des fichiers dérivés.

Le 4 novembre, les 13 fiches concurrentes U18M ont été consultées dans Chrome. Dans chaque groupe elles présentent exactement les mêmes données visibles et les mêmes liens d’engagement des deux équipes ; aucune n’affiche de numéro FBI. Leurs salles sont maintenant visibles et correspondent à l’export. La seule égalité date/équipe/heure/salle ne résout donc aucun ID. Les numéros FBI 15/16/20/23/26 ne sont ni les journées 1/2/3/4/5 ni les IDs web.

Une requête HTTP locale sur la première fiche renvoie 403 ; les pages restent lisibles dans le navigateur. Aucun test Supabase relancé, aucun statut HTTP 200 déduit des observations navigateur. Les lectures du moteur web étaient indisponibles et une recherche publique ciblée n’a fourni aucune correspondance numérotée exploitable.

Les 5 rencontres FBI sont confirmées ; les 13 IDs concurrents restent non départagés. Aucun U18M ajouté aux 11 candidats ni au SQL. Détail vérifiable : u18m-fbi-valide.json (cellules source) et u18m-preuves-fiches.json (observations publiques sans scores ni téléphones).

## 21 entrées ambiguës — 9 groupes, aucun arbitrage automatique

Une ressemblance équipe/date/adversaire sert uniquement au rapprochement. Elle ne démontre pas qu’il s’agit d’un doublon. Ne choisir ni le plus grand ID, ni la fiche avec un horaire. Une confirmation peut aussi établir que plusieurs rencontres distinctes sont valides.

### G01 — U13F J2, 2026-11-14, BORDEAUX ETUDIANTS CLUB (home)

| ID officiel | Heure | Salle | URL |
| --- | --- | --- | --- |
| 200000014904182 | Horaire à confirmer | Non renseignée | [Fiche officielle](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dfu13-3/match/200000014904182) |
| 200000014909691 | Horaire à confirmer | Non renseignée | [Fiche officielle](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dfu13-3/match/200000014909691) |

À fournir : référence(s) réellement active(s) dans FBI/FFBB pour cet engagement, avec statut de chaque variante (maintenue, annulée, remplacée ou rencontre distincte). Décision du club : [À COMPLÉTER].

### G02 — U13F J3, 2026-11-28, AMICALE BASKETTEURS GRADIGNAN (away)

| ID officiel | Heure | Salle | URL |
| --- | --- | --- | --- |
| 200000014904195 | Horaire à confirmer | Non renseignée | [Fiche officielle](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dfu13-3/match/200000014904195) |
| 200000014909695 | 17:30 | Non renseignée | [Fiche officielle](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dfu13-3/match/200000014909695) |

À fournir : référence(s) réellement active(s) dans FBI/FFBB pour cet engagement, avec statut de chaque variante (maintenue, annulée, remplacée ou rencontre distincte). Décision du club : [À COMPLÉTER].

### G03 — U13F J4, 2026-12-05, AGJA CAUDERAN (away)

| ID officiel | Heure | Salle | URL |
| --- | --- | --- | --- |
| 200000014904205 | Horaire à confirmer | GYMNASE JULES FERRY | [Fiche officielle](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dfu13-3/match/200000014904205) |
| 200000014909696 | 15:00 | GYMNASE JULES FERRY | [Fiche officielle](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dfu13-3/match/200000014909696) |

À fournir : référence(s) réellement active(s) dans FBI/FFBB pour cet engagement, avec statut de chaque variante (maintenue, annulée, remplacée ou rencontre distincte). Décision du club : [À COMPLÉTER].

### G04 — U13F J5, 2026-12-12, BOULIAC BASKET CLUB (home)

| ID officiel | Heure | Salle | URL |
| --- | --- | --- | --- |
| 200000014904218 | Horaire à confirmer | Non renseignée | [Fiche officielle](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dfu13-3/match/200000014904218) |
| 200000014909700 | Horaire à confirmer | Non renseignée | [Fiche officielle](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dfu13-3/match/200000014909700) |

À fournir : référence(s) réellement active(s) dans FBI/FFBB pour cet engagement, avec statut de chaque variante (maintenue, annulée, remplacée ou rencontre distincte). Décision du club : [À COMPLÉTER].

### G05 — U18M J1, 2026-11-08, STE EULALIE BASKET BALL (away)

**FBI n°15 confirmé** — 2026-11-08, 11:00, extérieur, Salle Valériane Ayayi. Source : rechercherRencontre!A2:G2.

| ID FFBB concurrent | Heure FFBB | Salle FFBB observée le 4 novembre | Correspondance au n° FBI |
| --- | --- | --- | --- |
| [200000014955052](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu18-4/match/200000014955052) | 11:00 | Salle Valériane Ayayi | Non démontrée |
| [200000014955437](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu18-4/match/200000014955437) | 11:00 | Salle Valériane Ayayi | Non démontrée |

**Conclusion : aucun identifiant sélectionné.** Les variantes ont les mêmes données visibles et les mêmes engagements d’équipes. La salle officielle complète le groupe mais ne constitue pas une clé discriminante.

**Seule preuve manquante pour ce groupe :** un document ou lien officiel établissant le numéro FBI 15 ↔ identifiant long FFBB canonique, ou les statuts officiels des variantes permettant de les exclure explicitement. Aucune nouvelle confirmation de date, d’heure, d’adversaire ou de salle n’est nécessaire.

### G06 — U18M J2, 2026-11-15, IE - CTC BASKET HAUTE GIRONDE - BASKET CLUB ESTUAIRE GIRONDE - 1 (home)

**FBI n°16 confirmé** — 2026-11-15, 11:00, domicile, SALLE PORT DU ROY. Source : rechercherRencontre!A3:G3.

| ID FFBB concurrent | Heure FFBB | Salle FFBB observée le 4 novembre | Correspondance au n° FBI |
| --- | --- | --- | --- |
| [200000014955053](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu18-4/match/200000014955053) | 11:00 | SALLE PORT DU ROY | Non démontrée |
| [200000014955438](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu18-4/match/200000014955438) | 11:00 | SALLE PORT DU ROY | Non démontrée |

**Conclusion : aucun identifiant sélectionné.** Les variantes ont les mêmes données visibles et les mêmes engagements d’équipes. La salle officielle complète le groupe mais ne constitue pas une clé discriminante.

**Seule preuve manquante pour ce groupe :** un document ou lien officiel établissant le numéro FBI 16 ↔ identifiant long FFBB canonique, ou les statuts officiels des variantes permettant de les exclure explicitement. Aucune nouvelle confirmation de date, d’heure, d’adversaire ou de salle n’est nécessaire.

### G07 — U18M J3, 2026-11-29, UNION SPORTIVE BAZAS - 2 (home)

**FBI n°20 confirmé** — 2026-11-29, 11:00, domicile, SALLE PORT DU ROY. Source : rechercherRencontre!A4:G4.

| ID FFBB concurrent | Heure FFBB | Salle FFBB observée le 4 novembre | Correspondance au n° FBI |
| --- | --- | --- | --- |
| [200000014924498](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu18-4/match/200000014924498) | 11:00 | SALLE PORT DU ROY | Non démontrée |
| [200000014955057](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu18-4/match/200000014955057) | 11:00 | SALLE PORT DU ROY | Non démontrée |
| [200000014955442](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu18-4/match/200000014955442) | 11:00 | SALLE PORT DU ROY | Non démontrée |

**Conclusion : aucun identifiant sélectionné.** Les variantes ont les mêmes données visibles et les mêmes engagements d’équipes. La salle officielle complète le groupe mais ne constitue pas une clé discriminante.

**Seule preuve manquante pour ce groupe :** un document ou lien officiel établissant le numéro FBI 20 ↔ identifiant long FFBB canonique, ou les statuts officiels des variantes permettant de les exclure explicitement. Aucune nouvelle confirmation de date, d’heure, d’adversaire ou de salle n’est nécessaire.

### G08 — U18M J4, 2026-12-06, COUTRAS GUITRES BASKET - 2 (away)

**FBI n°23 confirmé** — 2026-12-06, 11:00, extérieur, SALLE DOURSAT. Source : rechercherRencontre!A5:G5.

| ID FFBB concurrent | Heure FFBB | Salle FFBB observée le 4 novembre | Correspondance au n° FBI |
| --- | --- | --- | --- |
| [200000014924516](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu18-4/match/200000014924516) | 11:00 | SALLE DOURSAT | Non démontrée |
| [200000014955060](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu18-4/match/200000014955060) | 11:00 | SALLE DOURSAT | Non démontrée |
| [200000014955445](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu18-4/match/200000014955445) | 11:00 | SALLE DOURSAT | Non démontrée |

**Conclusion : aucun identifiant sélectionné.** Les variantes ont les mêmes données visibles et les mêmes engagements d’équipes. La salle officielle complète le groupe mais ne constitue pas une clé discriminante.

**Seule preuve manquante pour ce groupe :** un document ou lien officiel établissant le numéro FBI 23 ↔ identifiant long FFBB canonique, ou les statuts officiels des variantes permettant de les exclure explicitement. Aucune nouvelle confirmation de date, d’heure, d’adversaire ou de salle n’est nécessaire.

### G09 — U18M J5, 2026-12-13, LES PETITS MOUSSES LANGOIRAN - 2 (away)

**FBI n°26 confirmé** — 2026-12-13, 11:00, extérieur, SALLE RENE BAILLET. Source : rechercherRencontre!A6:G6.

| ID FFBB concurrent | Heure FFBB | Salle FFBB observée le 4 novembre | Correspondance au n° FBI |
| --- | --- | --- | --- |
| [200000014924535](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu18-4/match/200000014924535) | 11:00 | SALLE RENE BAILLET | Non démontrée |
| [200000014955063](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu18-4/match/200000014955063) | 11:00 | SALLE RENE BAILLET | Non démontrée |
| [200000014955448](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dmu18-4/match/200000014955448) | 11:00 | SALLE RENE BAILLET | Non démontrée |

**Conclusion : aucun identifiant sélectionné.** Les variantes ont les mêmes données visibles et les mêmes engagements d’équipes. La salle officielle complète le groupe mais ne constitue pas une clé discriminante.

**Seule preuve manquante pour ce groupe :** un document ou lien officiel établissant le numéro FBI 26 ↔ identifiant long FFBB canonique, ou les statuts officiels des variantes permettant de les exclure explicitement. Aucune nouvelle confirmation de date, d’heure, d’adversaire ou de salle n’est nécessaire.

## Seules données officielles manquantes

- G01 à G04 (U13F) : situation inchangée, identification des références actives et statut des 8 variantes.
- G05 à G09 (U18M) : les cinq rencontres FBI et leurs données sportives sont confirmées. Il manque uniquement la correspondance explicite entre chaque numéro FBI (15, 16, 20, 23, 26) et un ID web canonique, ou les statuts officiels discriminant les 13 variantes. Ne pas redemander leurs dates, horaires ou salles déjà fournis.
- Pour compléter les 11 candidats : 7 horaires et 6 salles (listés ci-dessous). Leur absence ne bloque pas un import explicitement approuvé avec ces champs inconnus.

- U13F J1 — 200000014909687 : horaire.
- U13M J2 — 200000014890302 : horaire, salle.
- U13M J1 — 200000014890292 : horaire.
- U13M J3 — 200000014890312 : horaire, salle.
- U13M J5 — 200000014890329 : horaire, salle.
- U15M J2 — 200000014884702 : horaire, salle.
- U15M J3 — 200000014884712 : salle.
- U15M J5 — 200000014884729 : horaire, salle.

Aucun nom, contact, licence, score ou autre donnée privée nécessaire. Aucune nouvelle demande de diagnostic sync_runs. Les corrections validées du club restent prioritaires ; toute divergence d’un nouvel export sera présentée pour arbitrage.
