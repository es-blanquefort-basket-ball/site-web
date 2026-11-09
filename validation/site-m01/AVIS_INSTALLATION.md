# SITE-M01 — Avis corrigé, 9 novembre 2026

**Verdict : installation techniquement possible avec le lot corrigé, sans déléguer
USAGE sur auth au rôle interne. L'ancien lot ne convenait pas aux ACL transmises.**
Aucune installation ni activation exécutée ; l'accord humain reste nécessaire.

## Pourquoi l'ancien lot échouait

01a tentait d'accorder USAGE ON SCHEMA auth à site_m01_executor. Le rôle n'existe
pas encore, PUBLIC n'a pas USAGE et postgres n'a pas l'option de délégation.
EXECUTE PUBLIC sur auth.uid()/auth.jwt() ne suffit pas à résoudre leurs noms depuis
un corps PL/pgSQL exécuté par le nouveau rôle. Ce diagnostic sur l'ancien lot reste exact.
L'obligation annoncée précédemment de faire intervenir le propriétaire Auth est en
revanche levée par le correctif ci-dessous.

## Correctif minimal préparé

Dans 01a seulement, deux relais privés site_m01.auth_uid()/auth_jwt() appellent les
fonctions Auth officielles avec un corps SQL standard `RETURN auth.uid()` / `RETURN
auth.jwt()`, analysé et lié aux fonctions à la création. Ils sont SECURITY INVOKER,
appartiennent au rôle interne et ne sont exécutables ni par anon ni par authenticated.
Le search_path reste vide et row_security=on. Aucun relais sous postgres, aucun
SECURITY DEFINER supplémentaire et aucune réimplémentation du décodage du JWT.

L'installateur doit avoir USAGE sur auth pour cette résolution initiale, **sans option
de délégation**. Le nouveau garde vérifie cette condition. La valeur
operator_usage_grantable=false ne signifie pas à elle seule que l'installateur n'a pas
USAGE. L'exécuteur reste sans droit USAGE auth ; ses appels passent par les références
préanalysées. Son droit EXECUTE sur les deux fonctions cibles reste contrôlé à
l'exécution, grâce au privilège PUBLIC déjà confirmé. Une révocation ultérieure ferme
les appels, elle n'est pas contournée.

Les appels Auth des fonctions SITE-M01 et de sa politique de lecture des habilitations
sont redirigés vers ces relais. Les signatures RPC, règles métier, droits par équipe,
propriétaires des tables et contrôles RLS restent identiques. Les fonctions de 01 sont
repris par CREATE OR REPLACE dans la transaction ; le fichier 01 reste inchangé.
05 vérifie également le caractère privé, préanalysé et invoker des deux relais.

Avant la fin de 01a, une sonde exécute les deux relais sous site_m01_executor, sans
retourner leur contenu. Si les fonctions Auth hébergées ont une dépendance interne
incompatible, le lot entier échoue avant COMMIT. Les corps Auth réels n'ont pas été
fournis : la sonde évite de supposer leur implémentation ou de prétendre à un test
hébergé déjà réussi. Aucun privilège supplémentaire n'est accordé en cas d'échec.

La distinction entre corps SQL préanalysé et corps texte ainsi que SECURITY INVOKER
est documentée par [PostgreSQL CREATE FUNCTION](https://www.postgresql.org/docs/current/sql-createfunction.html).
Ne pas remplacer les corps RETURN des relais par des chaînes AS $$...$$.

## Conditions déjà acquises

D'après les résultats SQL réels transmis : INHERIT postgres, création des objets,
REFERENCES auth.users.id, propriétaires postgres de matches/teams/public_calendar,
absence d'UPDATE client, RLS active, security_invoker=true, absence du schéma/rôle
SITE-M01 et absence de trigger utilisateur matches. auth.uid()/auth.jwt() existent et
ont EXECUTE PUBLIC. Aucun nouvel audit général n'est nécessaire.

Le contrôle exact de la définition/options de public_calendar reste bloquant dans le
lot, comme auparavant. Il protège le patch des trois seules expressions de salle.

## Preuves locales et limites

- Six contrôles Auth dédiés avec un installateur non-superutilisateur, sans BYPASSRLS,
  ayant USAGE auth sans option de délégation ; les relais sont créés et transférés
  avec les définitions exactes de 01a.
- Appel direct auth.uid() refusé au rôle interne ; les deux relais fonctionnent sans
  USAGE auth. Dépendances enregistrées, absence de SECURITY DEFINER et refus client vérifiés.
- Révocation EXECUTE sur une fonction Auth respectée malgré la liaison préalable.
- Lot atomique et RPC testés avec les rôles réels locaux ; RLS restrictive, équipes,
  Gestion/Live, identité anonyme, historique et arrêt toujours contrôlés.
- Une fonction Auth fictive avec dépendance interne incompatible fait annuler tout
  le lot, rôle et schéma compris. Aucun résultat hébergé n'est déclaré réussi.

## Installation contrôlée conservée

Après accord explicite et sauvegarde prévue dans ACTIVATION.md, utiliser uniquement
le **nouveau INSTALLATION.sql régénéré** : 01 → 01a corrigé → 02 → 04 → 05, une seule
transaction. Ne pas reprendre une ancienne copie du lot ni exécuter 01 seul.
Relire ensuite 05 en lecture seule, sans attribuer d'habilitation.

01, 02, 04 et 03-disable.sql restent inchangés. Aucun rôle Auth privilégié n'est délégué,
aucun GRANT Auth n'est ajouté, aucune table Auth n'est lue par l'exécuteur, aucun
UPDATE global et aucun contournement RLS. Les verrous serveur et client restent false,
aucun administrateur/utilisateur métier n'est ajouté. La V2 et les fichiers du calendrier
public sont inchangés. 03-disable.sql conserve sa fonction d'arrêt sans suppression.

L'installation fermée, la configuration des habilitations et la recette avec écritures
réelles restent des validations distinctes. Aucune migration de production, création
d'utilisateur, écriture de rencontre, fusion main ou publication Hostinger ici.
