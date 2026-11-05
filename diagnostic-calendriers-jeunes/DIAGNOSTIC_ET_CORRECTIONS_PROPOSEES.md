# Calendriers U13 / U15 / U18 — diagnostic et corrections proposées

État au 3 novembre 2026. Projet Supabase : `fgswygeqstgagmipltpq`.
**Diagnostic uniquement : aucune écriture Supabase, aucun appel POST à ffbb-sync, aucun changement du cron ou de fichier public. Les scripts MiniBasket sont conservés sans modification.**

## Conclusion

Le raccordement amont utilise encore la première phase pour U13F, U13M et U15M. U18M n'est pas configuré. Les pages locales du dépôt possèdent déjà les quatre liens de calendrier de phase 2 : changer ces liens ne raccordera pas la grille.

Corriger les correspondances seules ne suffit pas : l'export local de `ffbb-sync` crée des rencontres non publiées, ne renseigne pas l'heure locale attendue et utilise une clé par journée qui confond plusieurs fiches officielles. Il faut une récupération ciblée de phase 2, un contrôle de chaque identité et une publication explicite des nouvelles rencontres validées.

## Vérifications réelles et limites

- GET réel de `teams`, HTTP 200 : trois lignes U13F/U13M/U15M, actives et publiques, toutes configurées sur leur ancien engagement. U18M absent. Résultat exact : `teams-lecture-reelle.json`.
- GET réel de `public_calendar`, HTTP 200, Content-Range `0-56/57` : 57 UUID distincts, dont les 24 MiniBasket et les 33 autres rencontres. Instantané public sans score ni données privées : `public-calendar-lecture-seule.json`. Novembre : SG1 4, SG2 4, MiniBasket 17 ; aucun U13/U15/U18. L'absence correspondante dans `matches` est le résultat SQL fourni par le club, pas une lecture privée effectuée ici.
- Les sept URL d'équipes historiques/phase 2 ont été ouvertes dans le navigateur. Les anciennes pages U13/U15 présentent septembre–octobre ; les nouvelles pages présentent novembre–décembre. Les quatre en-têtes de compétition confirment phase et poule ci-dessous.
- Export local trouvé dans `/Users/laurence/Downloads/ffbb-sync.zip`, fichier `index.ts`. Copie exacte pour revue : `source/ffbb-sync-export.ts`. SHA-256 : `a04540f685e3d35459a5277f851f7ee227d1bea8906043df8c801775613562b5`. Son identité avec la version actuellement déployée reste à confirmer avant tout déploiement. Aucun code de la fonction n'a été modifié.
- GET de `sync_runs` : HTTP 401 avec la clé publique. Les dix derniers résultats ne sont donc **pas examinés**. Seul complément administrateur demandé : le SELECT ciblé de `LIRE_SYNC_RUNS.sql`. Aucun besoin de relancer les anciens diagnostics de schéma.
- Aucun accès à une clé privée, aucune règle RLS changée.

## Correspondances constatées et proposées

| Code public stable | Configuration réelle de teams | Engagement phase 2 vérifié | Phase / poule vérifiées |
| --- | --- | --- | --- |
| U13F | DFU13-3, `200000005370982`, phase `200000002899469`, poule `200000003059588` | [DFU13-3, 200000005408294](https://competitions.ffbb.com/ligues/naq/comites/0033/clubs/naq0033034/equipes/200000005408294) | `200000002902208` / `200000003064585` |
| U13M | DMU13-5, `200000005371520`, phase `200000002899490`, poule `200000003059648` | [DMU13-4, 200000005416665](https://competitions.ffbb.com/ligues/naq/comites/0033/clubs/naq0033034/equipes/200000005416665) | `200000002902520` / `200000003065651` |
| U15M | DMU15-3, `200000005371206`, phase `200000002899480`, poule `200000003059626` | [DMU15-3, 200000005414841](https://competitions.ffbb.com/ligues/naq/comites/0033/clubs/naq0033034/equipes/200000005414841) | `200000002902453` / `200000003065402` |
| U18M | Équipe absente | [DMU18-4, 200000005419968](https://competitions.ffbb.com/ligues/naq/comites/0033/clubs/naq0033034/equipes/200000005419968) | `200000002902228` / `200000003064624` |

URLs exactes observées, sans fabrication : `correspondances-proposees.json`. Les trois UUID internes existants doivent rester identiques ; les engagements FFBB sont des identités de phase, distinctes du code public du club.

Les liens historiques équipe/classement/poule présents dans les pages locales restent utiles pour consulter la première phase. Les liens « Calendrier phase 2 » sont déjà corrects. Le lien « Poule / journée » U18M d'`equipes.html` combine actuellement `phase=200000002899476` avec la poule de phase 2 ; l'en-tête officiel actuel donne `phase=200000002902228`. Cette incohérence de paramètres est signalée pour validation, sans affirmer que le site FFBB renvoie une erreur et sans changer le lien.

## Défauts du code exporté

Références ci-dessous : `source/ffbb-sync-export.ts`.

1. **Sélection d'équipe, lignes 277–283.** Seules les équipes `is_competition_active=true` avec `ffbb_team_url` non NULL sont lues. U18M absent ne peut pas être importé ; les trois URL anciennes ramènent leurs anciennes rencontres. Le filtre n'exclut pas les matchs extérieurs.
2. **Date locale absente, lignes 327–332 et 408–409.** Le code transforme le créneau local en UTC puis écrit `scheduled_at` et `scheduled_at_ffbb`, sans écrire `scheduled_local_ffbb`. Une publication seule ne suffit pas à rendre la rencontre visible si la vue manque de date locale. Ne pas recopier l'UTC dans un TIMESTAMP WITHOUT TIME ZONE local : conserver la date et l'heure Europe/Paris directement issues de la source, avec NULL si l'heure est inconnue.
3. **Nouvelles lignes non publiées, lignes 467–475.** L'insertion fixe `published=false`. Les mises à jour n'affectent pas cette propriété. Garder ce comportement prudent ; prévoir une publication séparée des seuls UUID nouvellement validés, avec `has_conflict=false` et une date locale restituée par la vue. Aucun UPDATE global par catégorie ou par mois.
4. **Clé artificielle insuffisante, lignes 334–339.** `ffbb_match_id` contient une concaténation équipe/phase/poule/journée, pas le véritable ID du match. Plusieurs fiches distinctes d'une même journée réutilisent la même clé et la dernière peut écraser les données de la précédente. Les URL de match sont associées par index global (`matchUrls[matchIndex]`), autre point à fiabiliser en lisant le lien de chaque bloc de rencontre.
5. **Horaires suspects incomplets, ligne 341.** Seul `02h00` est signalé ; les `00h00` visibles sur les nouvelles pages sont acceptés comme des heures normales. Ne pas convertir ces absences en rendez-vous à minuit ; conserver leur date et indiquer « Horaire à confirmer ». Toute heure ambiguë doit être contrôlée dans la fiche officielle avant publication, pas corrigée par un décalage arbitraire.
6. **Corrections locales, lignes 343–359.** La détection d'une correction ne regarde que `scheduled_at_override`, pas `scheduled_local_override`. La correction doit respecter les deux mécanismes existants sans les écraser ; les champs raw de salle ne doivent pas remplacer une correction du club sans contrôle.
7. **Journal trompeur possible, lignes 301–306 et 499–500.** Une équipe en erreur HTTP est ajoutée au rapport puis ignorée, mais le statut final dépend seulement du nombre de conflits. Un run `success` peut contenir des erreurs d'équipe ou zéro rencontre extraite. Un échec global remplace les détails par l'erreur globale : il ne permet pas à lui seul de reconstituer tout le travail intermédiaire. Il faut lire le rapport par équipe, les compteurs et l'erreur, pas seulement le statut.

## Ambiguïtés FFBB constatées

| Équipe | Lignes visibles phase 2 | URL officielles distinctes | Clés par journée obtenues par le code actuel | Collisions |
| --- | ---: | ---: | ---: | ---: |
| U13F | 9 | 9 | 5 | 4 |
| U13M | 5 | 5 | 5 | 0 |
| U15M | 5 | 5 | 5 | 0 |
| U18M | 13 | 13 | 5 | 8 |

Ce tableau ne signifie **pas** qu'il faut importer 32 rencontres ni qu'il y en a exactement 20 à publier. Les entrées semblables ne peuvent pas être fusionnées automatiquement. Les données visibles et liens sont conservés dans `observations-ffbb-phase2.json`, sans en faire un staging validé.

Exemple vérifié dans deux fiches officielles U13F : [200000014904195](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dfu13-3/match/200000014904195) et [200000014909695](https://competitions.ffbb.com/ligues/naq/comites/0033/competitions/dfu13-3/match/200000014909695) concernent toutes deux phase 2 / poule A / journée 3, le 28 novembre à Gradignan, mais affichent respectivement 00h00 et 17h30. Ces deux identités distinctes seraient confondues par la clé actuelle. La seconde heure est renseignée, mais cela ne prouve pas à elle seule que la première fiche doit être supprimée. Faire arbitrer les versions actives avant publication.

## Correction minimale proposée, à valider avant écriture

1. **Terminer la lecture des runs et confirmer l'export déployé.** Examiner les résultats du SELECT fourni et la version actuellement déployée de `ffbb-sync`. Vérifier pour chaque code : présence dans le rapport, erreurs HTTP, nombres trouvés/créés/mis à jour et conflits. Aucun appel POST de test à la fonction globale : il mettrait à jour les rencontres existantes.
2. **Préparer un mode de récupération ciblé sur les quatre engagements de phase 2**, sans changer le cron. Conserver la branche Seniors et les engagements historiques. Prévoir d'abord un aperçu sans écriture : vrais IDs/URL de match, phase/poule, date locale, heure ou statut inconnu, adversaire, domicile/extérieur, salle et rapprochement avec toutes les lignes déjà stockées, publiées ou non. U13F/U18M ambigus restent à valider ; ne pas faire tourner le parseur actuel avec seulement de nouvelles URL.
3. **Valider ensemble l'identité et la configuration.** Pour U13F/U13M/U15M, conserver `teams.id` et les anciens IDs stockés sur les matchs. Préparer le passage de `ffbb_team_id`, `ffbb_team_url`, `ffbb_pool_url` vers les nouvelles valeurs. Créer U18M avec le code public `U18M`, son engagement vérifié et ses liens observés. Ne pas créer une deuxième équipe interne U13 par phase avec un nouveau code improvisé.
4. **Préserver l'affichage historique lors du changement de configuration.** En particulier, changer `teams.competition_label` de DMU13-5 à DMU13-4 peut changer le libellé des anciens U13M si la vue le lit sur `teams`. Les liens d'équipe d'anciennes rencontres peuvent aussi dépendre de `teams.ffbb_team_url`. Comparer les 57 lignes publiques à l'instantané et conserver leurs valeurs historiques depuis les champs par rencontre lorsqu'elles existent, avant tout changement de parent. Pas de réécriture globale des 33 anciens matchs ni des 24 MiniBasket.
5. **Préparer les nouveaux matchs avec les vrais IDs officiels.** Vérifier également `ffbb_match_url` et les anciennes clés synthétiques pour détecter d'éventuelles lignes déjà présentes ; signaler un conflit plutôt que dupliquer. Ne pas renommer les clés des 57 rencontres. Le mode ciblé doit reconnaître le même nouvel ID lors d'un second passage. Ne pas mélanger un import par vrai ID avec le cron non corrigé qui recréerait les mêmes rencontres sous ses anciennes clés synthétiques : le code ciblé et le changement de correspondances doivent être validés ensemble.
6. **Renseigner les champs locaux et préserver les corrections.** Pour une heure confirmée, renseigner `scheduled_local_ffbb` à partir de la valeur locale FFBB, en cohérence avec l'UTC si ces champs sont conservés. Pour une heure inconnue, conserver une date indépendante et `local_time=NULL`, comme le principe MiniBasket ; vérifier/adopter le repli de date de la vue pour ces nouvelles origines FFBB également. La branche MiniBasket existante de la vue ne suffit pas automatiquement pour d'autres origines. Ne pas fabriquer de timestamp ni appliquer le traitement MiniBasket aux 57 lignes existantes. Garder les overrides du club prioritaires.
7. **Publication contrôlée après revue.** Conserver `published=false` à l'import ; publier uniquement une liste explicite de nouveaux UUID validés, sans conflit et avec une date visible, y compris à l'extérieur et sans heure si nécessaire. Vérifier les quatre filtres et l'affichage général, la salle connue et « Horaire à confirmer ». Préserver les scores MiniBasket non publiés. Attendu au second passage : zéro création supplémentaire, zéro changement sur les 57 lignes initiales.

Aucun de ces changements n'est appliqué par les fichiers de diagnostic. Pas de proposition de « publier tout » ni de lancer le cron pour voir le résultat.

## Tests et livraison de ce diagnostic

`node diagnostic-calendriers-jeunes/verifier-parseur.cjs` : fonctions pures extraites du TypeScript exporté, évaluées hors réseau et sans client Supabase. HTML **reconstitué** à partir des textes et liens publics observés, distinct du HTML brut reçu par l'Edge Function. Les collisions 9→5 / 13→5 et l'absence de champ local sont reproduites ; ce test ne prouve pas le nombre exact de lignes que le dernier run serveur a lues. Résultats : `resultats-parseur.json`.

`git diff --check` réussi. Aucun besoin de tests responsive supplémentaires : aucune page ou présentation n'a été modifiée pendant ce diagnostic. Les 57 publications sont conservées en lecture seule ; aucune publication Hostinger ni modification du cron n'est réalisée.

**Point restant pour compléter le diagnostic demandé : les derniers résultats de sync_runs, inaccessibles avec la clé publique. La configuration ancienne et les défauts du code exporté sont déjà constatés, ils ne sont pas déduits de ces logs manquants.**
