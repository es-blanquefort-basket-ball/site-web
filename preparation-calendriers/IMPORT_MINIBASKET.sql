-- ES Blanquefort Basket — IMPORT MINIBASKET 2026-2027
-- Contraintes teams/matches et absence de triggers non internes confirmées par le club.
-- Compatibilité testée localement ; sécurité des lignes manuelles face à ffbb-sync encore à confirmer.
-- Ne pas activer import/rollback sans accord humain explicite et contrôle du périmètre de ffbb-sync.
-- Mode verify par défaut : aucune écriture persistante.
-- ffbb-sync : couverture des compétitions FBI MiniBasket NON CONFIRMÉE.
-- Avant import : vérifier qu’elle préserve source_data et scheduled_local_override,
-- ne supprime pas les lignes manuelles et ne traite pas NULL comme un ID FFBB.
-- Ne pas modifier ffbb-sync ni son cron dans ce script.
-- Repli prévu : ACTUALISER_MINIBASKET.sql, pour une future interface privée.
-- Modes import/rollback : transaction atomique, tables verrouillées, contrôle des 33 publications.
-- Les IDs FFBB restent NULL. Aucun score ajouté. Aucune modification RLS ou cron.
-- La vue est adaptée sans changer ses colonnes, son OID, ses droits ou ses options.
-- Son ancienne définition est conservée dans source_data pour le retour arrière.
-- Pour les 11 heures inconnues : deux timestamps NULL, date conservée en JSONB.
-- La vue lit cette date JSONB pour les imports MiniBasket ; local_time reste NULL si inconnu.
-- Un index unique partiel protège (saison, clé source) pour l'origine esbb_minibasket.
-- Rollback supprime seulement les 24 lignes inchangées et les équipes créées, inchangées et vides.
-- L'index reste en place pour protéger cette origine lors d'un futur import.
BEGIN;

CREATE TEMP TABLE mb_options(action text, schema_reviewed boolean, sync_reviewed boolean, view_reviewed boolean) ON COMMIT DROP;
-- schema_reviewed=TRUE : contraintes réelles fournies par le club, aucun trigger non interne.
-- view_reviewed=TRUE : migration préparée/testée, assertions sur la vue réelle dans la transaction.
-- sync_reviewed reste FALSE : vérifier uniquement la protection des lignes manuelles.
-- La capacité de ffbb-sync à lire FBI et à actualiser ces horaires n'est PAS requise pour l'import initial.
-- sync_reviewed ne signifie PAS que FBI est pris en charge : il valide l'absence
-- d'écrasement/suppression des lignes manuelles par ffbb-sync et son cron.
-- view_reviewed valide la migration locale de la vue et la conservation de ses droits.
INSERT INTO mb_options VALUES ('verify', TRUE, FALSE, TRUE);
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';

CREATE TEMP TABLE minibasket_lot ON COMMIT DROP AS
SELECT x.*, to_jsonb(x) AS original_row, '2026-2027'::text AS season_scope,
       'minibasket-2026-2027-2026-11-03'::text AS batch_key,
       NULL::text AS ffbb_match_id, NULL::text AS ffbb_team_id,
       NULLIF(x.local_time, '')::time AS proposed_local_time
FROM jsonb_to_recordset($minibasket$[
  {
    "team_code_proposed": "U9F",
    "competition_code": "DFU9-10-P2",
    "match_number": "6",
    "opponent_name": "CASTELNAU MEDOC BC - 2 (6)",
    "home_away": "home",
    "local_date": "2026-11-07",
    "local_time": "09:30",
    "venue_name": "SALLE PORT DU ROY",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "Indiqué dans export",
    "original_time": "09:30",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT (5)",
    "opponent_name_fbi": "CASTELNAU MEDOC BC - 2 (6)",
    "source_file": "rechercherRencontre (16).xlsx",
    "source_excel_row": "2",
    "source_match_key": "DFU9-10-P2|U9F|6",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U9M1",
    "competition_code": "DMU9-10-P2",
    "match_number": "6",
    "opponent_name": "LES FILS DE ROLAND DE BLAYE (6)",
    "home_away": "home",
    "local_date": "2026-11-07",
    "local_time": "11:00",
    "venue_name": "SALLE PORT DU ROY",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "Indiqué dans export",
    "original_time": "11:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 1 (5)",
    "opponent_name_fbi": "LES FILS DE ROLAND DE BLAYE (6)",
    "source_file": "rechercherRencontre (21).xlsx",
    "source_excel_row": "2",
    "source_match_key": "DMU9-10-P2|U9M1|6",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U9M2",
    "competition_code": "DMU9-10-P2",
    "match_number": "9",
    "opponent_name": "BASKET CLUB CANEJANAIS (6)",
    "home_away": "home",
    "local_date": "2026-11-07",
    "local_time": "12:30",
    "venue_name": "SALLE PORT DU ROY",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "Indiqué dans export",
    "original_time": "12:30",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 2 (5)",
    "opponent_name_fbi": "BASKET CLUB CANEJANAIS (6)",
    "source_file": "rechercherRencontre (21).xlsx",
    "source_excel_row": "7",
    "source_match_key": "DMU9-10-P2|U9M2|9",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U11 M",
    "competition_code": "DMU11-10-P2",
    "match_number": "6",
    "opponent_name": "BORDEAUX ETUDIANTS CLUB - 2 (6)",
    "home_away": "home",
    "local_date": "2026-11-07",
    "local_time": "14:00",
    "venue_name": "SALLE PORT DU ROY",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "Indiqué dans export",
    "original_time": "14:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 2 (5)",
    "opponent_name_fbi": "BORDEAUX ETUDIANTS CLUB - 2 (6)",
    "source_file": "rechercherRencontre (17).xlsx",
    "source_excel_row": "2",
    "source_match_key": "DMU11-10-P2|U11 M|6",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U11 Mixte",
    "competition_code": "DMU11-4-P2",
    "match_number": "9",
    "opponent_name": "BC ST AVIT ST NAZAIRE - 2 (6)",
    "home_away": "home",
    "local_date": "2026-11-07",
    "local_time": "15:30",
    "venue_name": "SALLE PORT DU ROY",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "Indiqué dans export",
    "original_time": "15:30",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 1 (5)",
    "opponent_name_fbi": "BC ST AVIT ST NAZAIRE - 2 (6)",
    "source_file": "rechercherRencontre (18).xlsx",
    "source_excel_row": "2",
    "source_match_key": "DMU11-4-P2|U11 Mixte|9",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U9F",
    "competition_code": "DFU9-10-P2",
    "match_number": "12",
    "opponent_name": "ENTENTE PESSAC BASKET CLUB (4)",
    "home_away": "away",
    "local_date": "2026-11-14",
    "local_time": "10:00",
    "venue_name": "Salle Roger VINCENT 1",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "Indiqué dans export",
    "original_time": "10:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT (5)",
    "opponent_name_fbi": "ENTENTE PESSAC BASKET CLUB (4)",
    "source_file": "rechercherRencontre (16).xlsx",
    "source_excel_row": "3",
    "source_match_key": "DFU9-10-P2|U9F|12",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U9M2",
    "competition_code": "DMU9-10-P2",
    "match_number": "33",
    "opponent_name": "CASTELNAU MEDOC BC - 1 (4)",
    "home_away": "away",
    "local_date": "2026-11-14",
    "local_time": "11:45",
    "venue_name": "GYMNASE CANTERANE",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "Indiqué dans export",
    "original_time": "11:45",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 2 (5)",
    "opponent_name_fbi": "CASTELNAU MEDOC BC - 1 (4)",
    "source_file": "rechercherRencontre (21).xlsx",
    "source_excel_row": "8",
    "source_match_key": "DMU9-10-P2|U9M2|33",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U9M1",
    "competition_code": "DMU9-10-P2",
    "match_number": "30",
    "opponent_name": "AS LE HAILLAN (4)",
    "home_away": "away",
    "local_date": "2026-11-14",
    "local_time": "",
    "venue_name": "Gymnase du Collège",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "À confirmer",
    "original_time": "00:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 1 (5)",
    "opponent_name_fbi": "AS LE HAILLAN (4)",
    "source_file": "rechercherRencontre (21).xlsx",
    "source_excel_row": "3",
    "source_match_key": "DMU9-10-P2|U9M1|30",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U11 Mixte",
    "competition_code": "DMU11-4-P2",
    "match_number": "21",
    "opponent_name": "AGJA CAUDERAN - 2 (4)",
    "home_away": "away",
    "local_date": "2026-11-14",
    "local_time": "",
    "venue_name": "GYMNASE JULES FERRY",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "À confirmer",
    "original_time": "00:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 1 (5)",
    "opponent_name_fbi": "AGJA CAUDERAN - 2 (4)",
    "source_file": "rechercherRencontre (18).xlsx",
    "source_excel_row": "3",
    "source_match_key": "DMU11-4-P2|U11 Mixte|21",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U11 M",
    "competition_code": "DMU11-10-P2",
    "match_number": "24",
    "opponent_name": "BORDEAUX BASTIDE BASKET - 2 (4)",
    "home_away": "away",
    "local_date": "2026-11-14",
    "local_time": "",
    "venue_name": "SALLE PROMIS",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "À confirmer",
    "original_time": "00:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 2 (5)",
    "opponent_name_fbi": "BORDEAUX BASTIDE BASKET - 2 (4)",
    "source_file": "rechercherRencontre (17).xlsx",
    "source_excel_row": "3",
    "source_match_key": "DMU11-10-P2|U11 M|24",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U9M2",
    "competition_code": "DMU9-10-P2",
    "match_number": "81",
    "opponent_name": "LES PETITS MOUSSES LANGOIRAN (1)",
    "home_away": "home",
    "local_date": "2026-11-21",
    "local_time": "",
    "venue_name": "SALLE PORT DU ROY",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "À confirmer",
    "original_time": "00:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 2 (5)",
    "opponent_name_fbi": "LES PETITS MOUSSES LANGOIRAN (1)",
    "source_file": "rechercherRencontre (21).xlsx",
    "source_excel_row": "10",
    "source_match_key": "DMU9-10-P2|U9M2|81",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U11 Mixte",
    "competition_code": "DMU11-4-P2",
    "match_number": "45",
    "opponent_name": "ETOILE SPORTIVE EYSINAISE - 2 (1)",
    "home_away": "home",
    "local_date": "2026-11-21",
    "local_time": "",
    "venue_name": "SALLE PORT DU ROY",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "À confirmer",
    "original_time": "00:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 1 (5)",
    "opponent_name_fbi": "ETOILE SPORTIVE EYSINAISE - 2 (1)",
    "source_file": "rechercherRencontre (18).xlsx",
    "source_excel_row": "5",
    "source_match_key": "DMU11-4-P2|U11 Mixte|45",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U11 M",
    "competition_code": "DMU11-10-P2",
    "match_number": "60",
    "opponent_name": "JSA BORDEAUX BASKET - 3 (1)",
    "home_away": "home",
    "local_date": "2026-11-21",
    "local_time": "",
    "venue_name": "SALLE PORT DU ROY",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "À confirmer",
    "original_time": "00:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 2 (5)",
    "opponent_name_fbi": "JSA BORDEAUX BASKET - 3 (1)",
    "source_file": "rechercherRencontre (17).xlsx",
    "source_excel_row": "5",
    "source_match_key": "DMU11-10-P2|U11 M|60",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U9M1",
    "competition_code": "DMU9-10-P2",
    "match_number": "54",
    "opponent_name": "CMO BASSENS - 1 (2)",
    "home_away": "away",
    "local_date": "2026-11-28",
    "local_time": "10:30",
    "venue_name": "GYMNASE DU BOUSQUET",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "Indiqué dans export",
    "original_time": "10:30",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 1 (5)",
    "opponent_name_fbi": "CMO BASSENS - 1 (2)",
    "source_file": "rechercherRencontre (21).xlsx",
    "source_excel_row": "4",
    "source_match_key": "DMU9-10-P2|U9M1|54",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U11 M",
    "competition_code": "DMU11-10-P2",
    "match_number": "42",
    "opponent_name": "US CENON RIVE DROITE - 1 (2)",
    "home_away": "away",
    "local_date": "2026-11-28",
    "local_time": "11:00",
    "venue_name": "SALLE DE LA MAREGUE",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "Indiqué dans export",
    "original_time": "11:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 2 (5)",
    "opponent_name_fbi": "US CENON RIVE DROITE - 1 (2)",
    "source_file": "rechercherRencontre (17).xlsx",
    "source_excel_row": "4",
    "source_match_key": "DMU11-10-P2|U11 M|42",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U9M2",
    "competition_code": "DMU9-10-P2",
    "match_number": "57",
    "opponent_name": "SA MERIGNACAIS (2)",
    "home_away": "away",
    "local_date": "2026-11-28",
    "local_time": "11:15",
    "venue_name": "SALLE ROBERT BRETTES",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "Indiqué dans export",
    "original_time": "11:15",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 2 (5)",
    "opponent_name_fbi": "SA MERIGNACAIS (2)",
    "source_file": "rechercherRencontre (21).xlsx",
    "source_excel_row": "9",
    "source_match_key": "DMU9-10-P2|U9M2|57",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U9F",
    "competition_code": "DFU9-10-P2",
    "match_number": "18",
    "opponent_name": "CA BEGLES (2)",
    "home_away": "home",
    "local_date": "2026-11-28",
    "local_time": "",
    "venue_name": "SALLE PORT DU ROY",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "À confirmer",
    "original_time": "00:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT (5)",
    "opponent_name_fbi": "CA BEGLES (2)",
    "source_file": "rechercherRencontre (16).xlsx",
    "source_excel_row": "4",
    "source_match_key": "DFU9-10-P2|U9F|18",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U9F",
    "competition_code": "DFU9-10-P2",
    "match_number": "24",
    "opponent_name": "CASTELNAU MEDOC BC - 1 (1)",
    "home_away": "home",
    "local_date": "2026-12-05",
    "local_time": "",
    "venue_name": "SALLE PORT DU ROY",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "À confirmer",
    "original_time": "00:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT (5)",
    "opponent_name_fbi": "CASTELNAU MEDOC BC - 1 (1)",
    "source_file": "rechercherRencontre (16).xlsx",
    "source_excel_row": "5",
    "source_match_key": "DFU9-10-P2|U9F|24",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U9M1",
    "competition_code": "DMU9-10-P2",
    "match_number": "78",
    "opponent_name": "BORDEAUX ETUDIANTS CLUB (1)",
    "home_away": "home",
    "local_date": "2026-12-05",
    "local_time": "",
    "venue_name": "SALLE PORT DU ROY",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "À confirmer",
    "original_time": "00:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 1 (5)",
    "opponent_name_fbi": "BORDEAUX ETUDIANTS CLUB (1)",
    "source_file": "rechercherRencontre (21).xlsx",
    "source_excel_row": "5",
    "source_match_key": "DMU9-10-P2|U9M1|78",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U9F",
    "competition_code": "DFU9-10-P2",
    "match_number": "30",
    "opponent_name": "AS PIAN MEDOC BASKET - 1 (3)",
    "home_away": "away",
    "local_date": "2026-12-12",
    "local_time": "10:00",
    "venue_name": "SALLE MUNICIPALE",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "Indiqué dans export",
    "original_time": "10:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT (5)",
    "opponent_name_fbi": "AS PIAN MEDOC BASKET - 1 (3)",
    "source_file": "rechercherRencontre (16).xlsx",
    "source_excel_row": "6",
    "source_match_key": "DFU9-10-P2|U9F|30",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U9M1",
    "competition_code": "DMU9-10-P2",
    "match_number": "102",
    "opponent_name": "BASKET CLUB ESTUAIRE GIRONDE (3)",
    "home_away": "away",
    "local_date": "2026-12-12",
    "local_time": "11:00",
    "venue_name": "GYMNASE HUET",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "Indiqué dans export",
    "original_time": "11:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 1 (5)",
    "opponent_name_fbi": "BASKET CLUB ESTUAIRE GIRONDE (3)",
    "source_file": "rechercherRencontre (21).xlsx",
    "source_excel_row": "6",
    "source_match_key": "DMU9-10-P2|U9M1|102",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U11 M",
    "competition_code": "DMU11-10-P2",
    "match_number": "78",
    "opponent_name": "BASKET BASSIN D'ARCACHON - 1 (3)",
    "home_away": "away",
    "local_date": "2026-12-12",
    "local_time": "15:30",
    "venue_name": "SALLE ET. TURPIN (ANC BONNEVAL)",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "Indiqué dans export",
    "original_time": "15:30",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 2 (5)",
    "opponent_name_fbi": "BASKET BASSIN D'ARCACHON - 1 (3)",
    "source_file": "rechercherRencontre (17).xlsx",
    "source_excel_row": "6",
    "source_match_key": "DMU11-10-P2|U11 M|78",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U9M2",
    "competition_code": "DMU9-10-P2",
    "match_number": "105",
    "opponent_name": "ESPERANCE POMPIGNAC (3)",
    "home_away": "away",
    "local_date": "2026-12-12",
    "local_time": "",
    "venue_name": "SALLE DE CADOUIN",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "À confirmer",
    "original_time": "00:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 2 (5)",
    "opponent_name_fbi": "ESPERANCE POMPIGNAC (3)",
    "source_file": "rechercherRencontre (21).xlsx",
    "source_excel_row": "11",
    "source_match_key": "DMU9-10-P2|U9M2|105",
    "import_status": "STAGING — mapping Supabase à valider"
  },
  {
    "team_code_proposed": "U11 Mixte",
    "competition_code": "DMU11-4-P2",
    "match_number": "57",
    "opponent_name": "LE TAILLAN BASKET - 3 (3)",
    "home_away": "away",
    "local_date": "2026-12-12",
    "local_time": "",
    "venue_name": "SALLE DES SPORTS",
    "venue_address": "",
    "round_label": "",
    "ffbb_match_url": "",
    "ffbb_team_url": "",
    "time_status": "À confirmer",
    "original_time": "00:00",
    "team_name_fbi": "ENTENTE SPORTIVE BLANQUEFORT - 1 (5)",
    "opponent_name_fbi": "LE TAILLAN BASKET - 3 (3)",
    "source_file": "rechercherRencontre (18).xlsx",
    "source_excel_row": "6",
    "source_match_key": "DMU11-4-P2|U11 Mixte|57",
    "import_status": "STAGING — mapping Supabase à valider"
  }
]$minibasket$::jsonb)
AS x("team_code_proposed" text,
     "competition_code" text,
     "match_number" text,
     "opponent_name" text,
     "home_away" text,
     "local_date" text,
     "local_time" text,
     "venue_name" text,
     "venue_address" text,
     "round_label" text,
     "ffbb_match_url" text,
     "ffbb_team_url" text,
     "time_status" text,
     "original_time" text,
     "team_name_fbi" text,
     "opponent_name_fbi" text,
     "source_file" text,
     "source_excel_row" text,
     "source_match_key" text,
     "import_status" text);

DO $check$
BEGIN
  IF (SELECT count(*) FROM minibasket_lot) <> 24 THEN
    RAISE EXCEPTION 'Le lot doit contenir exactement 24 rencontres';
  END IF;
  IF EXISTS (
    SELECT 1 FROM (VALUES ('U9F',5),('U9M1',5),('U9M2',5),('U11 Mixte',4),('U11 M',5)) e(code,n)
    FULL JOIN (SELECT team_code_proposed code,count(*) n FROM minibasket_lot GROUP BY 1) r USING (code)
    WHERE e.n IS DISTINCT FROM r.n
  ) THEN RAISE EXCEPTION 'Répartition des cinq équipes incorrecte'; END IF;
  IF (SELECT count(*) FROM minibasket_lot WHERE proposed_local_time IS NULL) <> 11
    OR EXISTS (SELECT 1 FROM minibasket_lot WHERE proposed_local_time = '00:00'::time
      OR (proposed_local_time IS NULL AND original_time <> '00:00')) THEN
    RAISE EXCEPTION 'Les 11 heures inconnues doivent rester NULL';
  END IF;
  IF EXISTS (SELECT 1 FROM minibasket_lot GROUP BY season_scope,source_match_key HAVING count(*) > 1)
    OR EXISTS (SELECT 1 FROM minibasket_lot WHERE NULLIF(source_match_key,'') IS NULL)
    OR EXISTS (SELECT 1 FROM minibasket_lot GROUP BY team_code_proposed,local_date,opponent_name HAVING count(*) > 1)
    THEN RAISE EXCEPTION 'Doublon ou clé de provenance absente'; END IF;
  IF EXISTS (SELECT 1 FROM minibasket_lot WHERE opponent_name ILIKE '%exempt%') THEN
    RAISE EXCEPTION 'Exemption interdite dans le lot';
  END IF;
  IF EXISTS (SELECT 1 FROM minibasket_lot WHERE ffbb_match_id IS NOT NULL OR ffbb_team_id IS NOT NULL) THEN
    RAISE EXCEPTION 'Identifiant FFBB non confirmé';
  END IF;
END
$check$;

ALTER TABLE minibasket_lot ADD COLUMN expected_scheduled timestamp without time zone;
UPDATE minibasket_lot SET expected_scheduled =
  CASE WHEN proposed_local_time IS NULL THEN NULL
       ELSE local_date::date + proposed_local_time END;

-- Enveloppe de provenance persistante, sans identifiant fédéral fabriqué.
ALTER TABLE minibasket_lot ADD COLUMN expected_source jsonb;
UPDATE minibasket_lot SET expected_source = jsonb_build_object(
  'import_source', 'esbb_minibasket', 'batch_id', batch_key,
  'season_scope', season_scope, 'source_match_key', source_match_key,
  'local_date', local_date, 'time_known', proposed_local_time IS NOT NULL,
  'club_validated_fields', '[]'::jsonb,
  'provider_baseline', jsonb_build_object(
    'opponent_name',opponent_name,'scheduled_local_ffbb',expected_scheduled,
    'venue_name_raw',NULLIF(venue_name,''),'venue_address_raw',NULLIF(venue_address,''),
    'home_away',home_away,'competition_name',competition_code,'round_label',NULLIF(round_label,''),
    'local_date',local_date,'time_known',proposed_local_time IS NOT NULL),
  'original_row', original_row);

-- Comparaison de toutes les valeurs métier explicitement importées.
CREATE TEMP VIEW mb_rows AS
SELECT m.id, m.team_id, s.source_match_key, m.source_data,
  (t.code = s.team_code_proposed
   AND m.opponent_name = s.opponent_name
   AND m.ffbb_match_id IS NULL
   AND m.venue_id IS NULL
   AND m.scheduled_local_ffbb IS NOT DISTINCT FROM s.expected_scheduled
   AND m.scheduled_local_override IS NULL
   AND m.venue_name_raw IS NOT DISTINCT FROM NULLIF(s.venue_name,'')
   AND m.venue_address_raw IS NOT DISTINCT FROM NULLIF(s.venue_address,'')
   AND m.home_away IS NOT DISTINCT FROM s.home_away
   AND m.competition_name IS NOT DISTINCT FROM s.competition_code
   AND m.round_label IS NOT DISTINCT FROM NULLIF(s.round_label,'')
   AND m.status = 'scheduled' AND m.published AND NOT m.has_conflict
   AND (m.source_data - 'created_team_id' - 'created_team_snapshot' - 'rollback_snapshot' - 'calendar_view_before' - 'calendar_view_installed') = s.expected_source
   AND (to_jsonb(m) - 'source_data' - 'updated_at') = m.source_data->'rollback_snapshot'
  ) IS TRUE AS intact
FROM public.matches m JOIN public.teams t ON t.id=m.team_id
JOIN minibasket_lot s ON m.source_data->>'source_match_key'=s.source_match_key
 AND m.source_data->>'season_scope'=s.season_scope
WHERE m.source_data->>'import_source'='esbb_minibasket'
  AND m.source_data->>'batch_id'='minibasket-2026-2027-2026-11-03';

DO $operation$
DECLARE
  opt mb_options%ROWTYPE;
  idx oid;
  old_view text;
  installed_view text;
  projection text;
  old_options text[];
  old_acl aclitem[];
  view_oid oid;
  column_spec record;
  expression text;
BEGIN
  SELECT * INTO STRICT opt FROM mb_options;
  IF opt.action NOT IN ('verify','import','rollback') THEN
    RAISE EXCEPTION 'Action inconnue';
  END IF;
  IF opt.action='verify' THEN
    IF EXISTS (SELECT 1 FROM mb_rows WHERE NOT intact)
      OR (SELECT count(*) FROM mb_rows) NOT IN (0,24) THEN
      RAISE EXCEPTION 'Vérification : lot incomplet ou modifié';
    END IF;
    IF (SELECT count(*) FROM mb_rows)=24 AND (
      (SELECT count(*) FROM public.public_calendar v
       WHERE v.team_code IN (SELECT team_code_proposed FROM minibasket_lot))<>24
      OR EXISTS (SELECT 1 FROM minibasket_lot s JOIN mb_rows r ON r.source_match_key=s.source_match_key WHERE
        (SELECT count(*) FROM public.public_calendar v
         WHERE v.id=r.id AND v.team_code=s.team_code_proposed AND v.opponent_name=s.opponent_name
           AND v.local_date::date=s.local_date::date
           AND NULLIF(v.local_time::text,'')::time IS NOT DISTINCT FROM s.proposed_local_time)<>1)
    ) THEN RAISE EXCEPTION 'Vérification : publications non conformes aux 24 rencontres / 11 heures NULL'; END IF;
    RETURN;
  END IF;
  IF NOT (opt.schema_reviewed AND opt.sync_reviewed AND opt.view_reviewed) THEN
    RAISE EXCEPTION 'Import bloqué : confirmer la préservation des lignes manuelles par ffbb-sync ; sa couverture FBI n’est pas requise';
  END IF;

  SET CONSTRAINTS ALL IMMEDIATE;

  -- Verrou partagé entre toutes les relances et verrou des tables contre les autres écrivains.
  PERFORM pg_advisory_xact_lock(202627,1103);
  LOCK TABLE public.teams, public.matches IN SHARE ROW EXCLUSIVE MODE;
  CREATE TEMP TABLE mb_preserve_matches ON COMMIT DROP AS
    SELECT id,to_jsonb(m) AS row_data FROM public.matches m
    WHERE NOT (COALESCE(m.source_data->>'import_source','')='esbb_minibasket'
      AND COALESCE(m.source_data->>'batch_id','')='minibasket-2026-2027-2026-11-03');
  CREATE TEMP TABLE mb_preserve_teams ON COMMIT DROP AS
    SELECT id,to_jsonb(t) AS row_data FROM public.teams t;
  CREATE TEMP TABLE mb_public_before ON COMMIT DROP AS
    SELECT to_jsonb(v) AS row_data FROM public.public_calendar v
    WHERE team_code NOT IN ('U9F','U9M1','U9M2','U11 Mixte','U11 M');
  IF (SELECT count(*) FROM mb_public_before) <> 33 THEN
    RAISE EXCEPTION 'Les 33 publications de référence ont changé : examiner avant import';
  END IF;

  CREATE TEMP TABLE mb_owned_teams(id uuid,row_data jsonb) ON COMMIT DROP;
  IF opt.action='import' THEN
    -- Une identité JSONB est unique même quand ffbb_match_id reste NULL.
    -- Comparaison de la définition avec un index temporaire de référence, pour une relance sûre.
    CREATE UNIQUE INDEX IF NOT EXISTS esbb_minibasket_season_source_uidx
      ON public.matches ((source_data->>'season_scope'), (source_data->>'source_match_key'))
      WHERE source_data->>'import_source'='esbb_minibasket';
    CREATE TEMP TABLE mb_index_reference(source_data jsonb) ON COMMIT DROP;
    CREATE UNIQUE INDEX mb_index_expected
      ON mb_index_reference ((source_data->>'season_scope'), (source_data->>'source_match_key'))
      WHERE source_data->>'import_source'='esbb_minibasket';
    idx := to_regclass('public.esbb_minibasket_season_source_uidx');
    IF NOT EXISTS (SELECT 1 FROM pg_index i WHERE i.indexrelid=idx
      AND i.indrelid='public.matches'::regclass AND i.indisunique AND i.indisvalid
      AND i.indnkeyatts=2 AND i.indnatts=2
      AND pg_get_expr(i.indpred,i.indrelid)=
        (SELECT pg_get_expr(j.indpred,j.indrelid) FROM pg_index j WHERE j.indexrelid='mb_index_expected'::regclass)
      AND pg_get_indexdef(idx,1,true)=pg_get_indexdef('mb_index_expected'::regclass,1,true)
      AND pg_get_indexdef(idx,2,true)=pg_get_indexdef('mb_index_expected'::regclass,2,true)
    ) THEN RAISE EXCEPTION 'Index de provenance existant incompatible'; END IF;

    -- Une correspondance approximative ne justifie jamais une fusion ou un doublon.
    IF EXISTS (
      SELECT 1 FROM public.matches m JOIN public.teams t ON t.id=m.team_id
      WHERE t.code IN (SELECT team_code_proposed FROM minibasket_lot)
        AND NOT EXISTS (SELECT 1 FROM mb_rows r WHERE r.id=m.id AND r.intact)
    ) THEN RAISE EXCEPTION 'Rencontre MiniBasket préexistante non reconnue ou modifiée : rapprochement manuel requis'; END IF;
    IF EXISTS (
      SELECT 1 FROM public.matches m JOIN minibasket_lot s
        ON m.source_data->>'season_scope'=s.season_scope
       AND m.source_data->>'source_match_key'=s.source_match_key
      WHERE m.source_data->>'import_source'='esbb_minibasket'
        AND NOT EXISTS (SELECT 1 FROM mb_rows r WHERE r.id=m.id AND r.intact)
    ) THEN RAISE EXCEPTION 'Clé de provenance déjà utilisée par un autre lot ou contenu'; END IF;
    IF (SELECT count(*) FROM mb_rows) NOT IN (0,24) THEN
      RAISE EXCEPTION 'Lot incomplet : aucune réparation automatique';
    END IF;
    IF EXISTS (SELECT 1 FROM public.teams t JOIN minibasket_lot s ON t.code=s.team_code_proposed
      WHERE t.name<>s.team_code_proposed OR t.competition_label IS DISTINCT FROM s.competition_code
        OR t.ffbb_team_id IS NOT NULL OR t.is_public IS DISTINCT FROM true OR t.is_competition_active IS DISTINCT FROM true)
    THEN RAISE EXCEPTION 'Équipe existante incompatible : aucune mise à jour automatique'; END IF;

    CREATE TEMP TABLE mb_created_teams ON COMMIT DROP AS
    WITH inserted AS (
      INSERT INTO public.teams(code,name,competition_label,ffbb_team_id,is_competition_active,is_public)
      SELECT DISTINCT s.team_code_proposed,s.team_code_proposed,s.competition_code,NULL,true,true
      FROM minibasket_lot s
      WHERE NOT EXISTS (SELECT 1 FROM public.teams t WHERE t.code=s.team_code_proposed)
      RETURNING *
    ) SELECT id,to_jsonb(inserted) AS row_data FROM inserted;

    -- Aucun ID de salle déduit : venue_id NULL, libellés FBI conservés dans les champs raw.
    INSERT INTO public.matches(team_id,opponent_name,ffbb_match_id,venue_id,
      scheduled_local_ffbb,scheduled_local_override,venue_name_raw,venue_address_raw,
      home_away,competition_name,round_label,status,published,has_conflict,source_data)
    SELECT t.id,s.opponent_name,NULL,NULL,s.expected_scheduled,NULL,
      NULLIF(s.venue_name,''),NULLIF(s.venue_address,''),s.home_away,s.competition_code,
      NULLIF(s.round_label,''),'scheduled',true,false,
      s.expected_source || jsonb_build_object('created_team_id',c.id,'created_team_snapshot',c.row_data)
    FROM minibasket_lot s JOIN public.teams t ON t.code=s.team_code_proposed
    LEFT JOIN mb_created_teams c ON c.id=t.id
    WHERE NOT EXISTS (SELECT 1 FROM mb_rows r WHERE r.source_match_key=s.source_match_key);

    -- Adaptation minimale : conserver intégralement la requête existante pour les autres rencontres.
    -- Pas de DROP/renommage : même vue, mêmes types, ordre de colonnes, options et droits.
    view_oid := 'public.public_calendar'::regclass;
    SELECT pg_get_viewdef(view_oid,true),reloptions,relacl INTO old_view,old_options,old_acl
      FROM pg_class WHERE oid=view_oid;
    IF EXISTS (SELECT 1 FROM public.matches m WHERE m.source_data->>'batch_id'='minibasket-2026-2027-2026-11-03'
      AND m.source_data->>'calendar_view_installed' IS NOT NULL) THEN
      IF EXISTS (SELECT 1 FROM mb_rows r WHERE r.source_data->>'calendar_view_installed' IS DISTINCT FROM old_view) THEN
        RAISE EXCEPTION 'La vue a changé depuis cet import : revue requise, aucune réécriture automatique';
      END IF;
      installed_view := old_view;
      SELECT source_data->>'calendar_view_before' INTO old_view FROM mb_rows LIMIT 1;
    ELSE
      IF NOT EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid=view_oid AND attname='id'
        AND attnum>0 AND NOT attisdropped) THEN
        RAISE EXCEPTION 'public_calendar doit exposer matches.id pour remplacer les seules rencontres du lot';
      END IF;
      -- L'identité UUID décide du remplacement, jamais les libellés ou la date.
      projection := '';
      FOR column_spec IN SELECT attname,format_type(atttypid,atttypmod) AS typ
        FROM pg_attribute WHERE attrelid=view_oid AND attnum>0 AND NOT attisdropped ORDER BY attnum
      LOOP
        expression := CASE column_spec.attname
          WHEN 'id' THEN 'm.id'
          WHEN 'team_name' THEN 't.name'
          WHEN 'competition_label' THEN 't.competition_label'
          WHEN 'starts_local' THEN 'COALESCE(m.scheduled_local_override,m.scheduled_local_ffbb)'
          WHEN 'status' THEN 'm.status'
          WHEN 'updated_at' THEN 'm.updated_at'
          WHEN 'team_code' THEN 't.code'
          WHEN 'opponent_name' THEN 'm.opponent_name'
          WHEN 'home_away' THEN 'm.home_away'
          WHEN 'local_date' THEN $expr$COALESCE(m.scheduled_local_override::date,
            NULLIF(m.source_data->>'local_date','')::date,m.scheduled_local_ffbb::date)$expr$
          WHEN 'local_time' THEN $expr$CASE WHEN m.scheduled_local_override IS NOT NULL
              THEN NULLIF(m.scheduled_local_override::time,'00:00'::time)
            WHEN m.source_data->>'time_known'='true'
              THEN NULLIF(m.scheduled_local_ffbb::time,'00:00'::time)
            ELSE NULL END$expr$
          WHEN 'venue_name' THEN 'm.venue_name_raw'
          WHEN 'venue_address' THEN 'm.venue_address_raw'
          WHEN 'round_label' THEN 'm.round_label'
          -- Aucun score, donnée privée, URL ou identifiant déduit pour la branche MiniBasket.
          ELSE 'NULL'
        END;
        projection := projection || CASE WHEN projection='' THEN '' ELSE ',' END
          || format('(%s)::%s AS %I',expression,column_spec.typ,column_spec.attname);
      END LOOP;
      EXECUTE format($view$
        CREATE OR REPLACE VIEW public.public_calendar %s AS
        SELECT legacy.* FROM (%s) legacy
        WHERE NOT EXISTS (
          SELECT 1 FROM public.matches m
          WHERE m.id=legacy.id
            AND m.source_data->>'import_source'='esbb_minibasket'
        )
        UNION ALL
        SELECT %s FROM public.matches m JOIN public.teams t ON t.id=m.team_id
        WHERE m.source_data->>'import_source'='esbb_minibasket'
          AND m.published=true AND m.has_conflict=false AND t.is_public=true
        $view$,
        CASE WHEN old_options IS NULL THEN '' ELSE 'WITH ('||array_to_string(old_options,',')||')' END,
        regexp_replace(old_view,';[[:space:]]*$',''),projection);
      installed_view := pg_get_viewdef(view_oid,true);
      IF 'public.public_calendar'::regclass::oid<>view_oid OR EXISTS (
        SELECT 1 FROM pg_class WHERE oid=view_oid
          AND (reloptions IS DISTINCT FROM old_options OR relacl IS DISTINCT FROM old_acl)
      ) THEN RAISE EXCEPTION 'Options ou droits de la vue modifiés : annulation'; END IF;
    END IF;

    -- Empreinte du contenu inséré : protège aussi les colonnes supplémentaires (scores éventuels).
    -- Seul updated_at est exclu, car les triggers d'horodatage peuvent le changer pendant cette opération.
    UPDATE public.matches m SET source_data=m.source_data || jsonb_build_object(
      'rollback_snapshot',to_jsonb(m)-'source_data'-'updated_at',
      'calendar_view_before',old_view,'calendar_view_installed',installed_view)
    WHERE m.source_data->>'import_source'='esbb_minibasket'
      AND m.source_data->>'batch_id'='minibasket-2026-2027-2026-11-03'
      AND NOT m.source_data ? 'rollback_snapshot';

    IF (SELECT count(*) FROM mb_rows WHERE intact)<>24 THEN
      RAISE EXCEPTION 'Le contenu final des 24 rencontres diffère du lot : transaction annulée';
    END IF;
    -- Cette assertion est indispensable : deux timestamps NULL ne portent pas la date.
    -- Sans support de la date JSONB par la vue, rien ne doit être publié.
    IF (SELECT count(*) FROM public.public_calendar v
        WHERE v.team_code IN (SELECT team_code_proposed FROM minibasket_lot))<>24
      OR EXISTS (
        SELECT 1 FROM minibasket_lot s JOIN mb_rows r ON r.source_match_key=s.source_match_key
        WHERE (SELECT count(*) FROM public.public_calendar v
          WHERE v.id=r.id AND v.team_code=s.team_code_proposed AND v.opponent_name=s.opponent_name
            AND v.local_date::date=s.local_date::date
            AND NULLIF(v.local_time::text,'')::time IS NOT DISTINCT FROM s.proposed_local_time)<>1
      ) THEN RAISE EXCEPTION 'Vue incompatible : attendu 24 rencontres et 11 local_time NULL ; aucune écriture conservée'; END IF;

  ELSE -- rollback : aucun DELETE approximatif par nom d'équipe ou par date.
    IF (SELECT count(*) FROM mb_rows)<>24 OR EXISTS (SELECT 1 FROM mb_rows WHERE NOT intact) THEN
      RAISE EXCEPTION 'Retour arrière bloqué : lot absent, incomplet ou modifié';
    END IF;
    IF (SELECT count(*) FROM public.matches m
      WHERE m.source_data->>'import_source'='esbb_minibasket'
        AND m.source_data->>'batch_id'='minibasket-2026-2027-2026-11-03')<>24 THEN
      RAISE EXCEPTION 'Nombre de lignes du lot inattendu';
    END IF;
    INSERT INTO mb_owned_teams
      SELECT DISTINCT (source_data->>'created_team_id')::uuid AS id,
        source_data->'created_team_snapshot' AS row_data
      FROM mb_rows WHERE source_data->>'created_team_id' IS NOT NULL;
    SELECT source_data->>'calendar_view_before',source_data->>'calendar_view_installed'
      INTO old_view,installed_view FROM mb_rows LIMIT 1;
    IF old_view IS NULL OR EXISTS (SELECT 1 FROM mb_rows r
      WHERE r.source_data->>'calendar_view_before' IS DISTINCT FROM old_view
        OR r.source_data->>'calendar_view_installed' IS DISTINCT FROM installed_view)
      OR pg_get_viewdef('public.public_calendar'::regclass,true) IS DISTINCT FROM installed_view THEN
      RAISE EXCEPTION 'Définition de vue modifiée ou sauvegarde incohérente : retour arrière arrêté';
    END IF;
    DELETE FROM public.matches m USING mb_rows r WHERE m.id=r.id AND r.intact;
    DELETE FROM public.teams t USING mb_owned_teams o
      WHERE t.id=o.id AND to_jsonb(t)=o.row_data
        AND NOT EXISTS (SELECT 1 FROM public.matches m WHERE m.team_id=t.id);
    -- Restaurer la définition initiale seulement si aucun autre lot manuel ne dépend de l'extension.
    IF NOT EXISTS (SELECT 1 FROM public.matches m WHERE m.source_data->>'import_source'='esbb_minibasket') THEN
      SELECT reloptions INTO old_options FROM pg_class WHERE oid='public.public_calendar'::regclass;
      EXECUTE format('CREATE OR REPLACE VIEW public.public_calendar %s AS %s',
        CASE WHEN old_options IS NULL THEN '' ELSE 'WITH ('||array_to_string(old_options,',')||')' END,old_view);
    END IF;
    IF EXISTS (SELECT 1 FROM public.matches m WHERE m.source_data->>'import_source'='esbb_minibasket'
      AND m.source_data->>'batch_id'='minibasket-2026-2027-2026-11-03') THEN
      RAISE EXCEPTION 'Retour arrière incomplet';
    END IF;
  END IF;

  IF (SELECT count(*) FROM public.matches) <>
      (SELECT count(*) FROM mb_preserve_matches) + (CASE WHEN opt.action='import' THEN 24 ELSE 0 END) THEN
    RAISE EXCEPTION 'Nombre de rencontres inattendu : effet secondaire hors lot';
  END IF;
  IF EXISTS (SELECT 1 FROM public.teams t
    WHERE NOT EXISTS (SELECT 1 FROM mb_preserve_teams b WHERE b.id=t.id)
      AND t.code NOT IN (SELECT team_code_proposed FROM minibasket_lot)) THEN
    RAISE EXCEPTION 'Création inattendue d’une équipe hors lot';
  END IF;
  -- Aucun changement des autres rencontres, même si un trigger a un effet indirect.
  IF EXISTS (SELECT 1 FROM mb_preserve_matches b FULL JOIN public.matches m ON m.id=b.id
    WHERE b.id IS NOT NULL AND (m.id IS NULL OR to_jsonb(m) IS DISTINCT FROM b.row_data)) THEN
    RAISE EXCEPTION 'Une rencontre hors lot a changé : transaction annulée';
  END IF;
  IF EXISTS (SELECT 1 FROM mb_preserve_teams b LEFT JOIN public.teams t ON t.id=b.id
    WHERE (t.id IS NULL OR to_jsonb(t) IS DISTINCT FROM b.row_data)
      AND NOT (opt.action='rollback' AND t.id IS NULL AND EXISTS(SELECT 1 FROM mb_owned_teams o WHERE o.id=b.id))) THEN
    RAISE EXCEPTION 'Une équipe préexistante a changé : transaction annulée';
  END IF;
  IF EXISTS (
    (SELECT row_data FROM mb_public_before EXCEPT ALL
     SELECT to_jsonb(v) FROM public.public_calendar v WHERE team_code NOT IN ('U9F','U9M1','U9M2','U11 Mixte','U11 M'))
    UNION ALL
    (SELECT to_jsonb(v) FROM public.public_calendar v WHERE team_code NOT IN ('U9F','U9M1','U9M2','U11 Mixte','U11 M')
     EXCEPT ALL SELECT row_data FROM mb_public_before)
  ) THEN RAISE EXCEPTION 'Les 33 publications existantes ont changé : transaction annulée'; END IF;
END
$operation$;

-- Vérification indépendante réutilisable en laissant action='verify'.
SELECT o.action, count(r.id) AS rencontres_du_lot,
  count(r.id) FILTER (WHERE r.intact) AS rencontres_identiques_au_staging,
  (SELECT count(*) FROM public.public_calendar) AS total_publications
FROM mb_options o LEFT JOIN mb_rows r ON true GROUP BY o.action;
SELECT s.team_code_proposed,count(*) AS attendues,
  count(*) FILTER (WHERE s.proposed_local_time IS NULL) AS heures_inconnues_attendues,
  (SELECT count(*) FROM public.public_calendar v WHERE v.team_code=s.team_code_proposed
    AND v.local_time IS NULL) AS heures_inconnues_publiees,
  (SELECT count(*) FROM public.public_calendar v WHERE v.team_code=s.team_code_proposed) AS publiees
FROM minibasket_lot s GROUP BY s.team_code_proposed ORDER BY s.team_code_proposed;

COMMIT;
