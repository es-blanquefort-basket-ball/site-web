# SITE-M01 — Préparation d’intégration au projet existant

Cible unique : **fgswygeqstgagmipltpq**. Base revue : commit `cbbe273` sur
`codex/site-m01-raccordement-acces`. Aucun nouveau projet Supabase, catalogue de matchs
ou écran n’est prévu. Ce document décrit une préparation, pas une installation effectuée.

Actualisation Auth du 9 novembre 2026 : [avis corrigé](AVIS_INSTALLATION.md).
01a ne tente plus de déléguer USAGE sur auth : deux relais privés SQL préanalysés
SECURITY INVOKER conservent les fonctions Auth officielles et les ACL EXECUTE effectives.
Le lot a été régénéré ; sonde Auth bloquante avant COMMIT, aucun privilège supplémentaire.
Les anciennes demandes de relecture générale de 00 ci-dessous sont historiques : les
résultats du club sont acquis et l'installation reste soumise à accord explicite.

## Résultat du contrôle de sécurité

Le contrôle a relevé une limite de `cbbe273` : les fonctions privées SECURITY DEFINER
créées par postgres peuvent contourner RLS en tant que propriétaire/superutilisateur,
même si leurs contrôles applicatifs d’équipe étaient présents. **01 seul n’est donc pas
la séquence autorisable pour l’intégration réelle.**

Le durcissement obligatoire `01a-rls-executor.sql` corrige ce point sans modifier les scripts
01, 02, 04 et 03 déjà livrés. Il conserve les signatures des RPC et la V2.

| Contrôle | Préparation finale et preuve locale |
| --- | --- |
| Identité | auth.uid() et claim is_anonymous du JWT signé ; user_metadata ignoré |
| Rôle interne | site_m01_executor NOLOGIN, NOSUPERUSER, NOBYPASSRLS, NOINHERIT ; aucune délégation aux rôles clients ; maintenance réservée à l’opérateur SQL propriétaire |
| Propriété | Fonctions privées au rôle interne ; tables à l’opérateur d’installation, donc RLS appliquée |
| Façades publiques | SECURITY INVOKER, helpers privés sans EXECUTE client |
| Accès source | SELECT soumis à RLS : équipe autorisée, équipe publique, match publié sans conflit |
| UPDATE source | Seulement scheduled_local_override et venue_name_override, au rôle interne ; politique Gestion par équipe avec USING et WITH CHECK |
| Rôles clients | Aucun UPDATE, aucun SET ROLE vers le rôle interne, aucun accès direct aux tables privées |
| Administration | Table administrators hors écriture de l’exécuteur ; attribution des seuls droits Gestion/Live par équipe et origine manuelle |
| Historique | INSERT avec actor_id=auth.uid(), SELECT admin, aucun UPDATE/DELETE même au rôle interne |
| Live | Verrouillage/version de match_state, pas de verrou UPDATE organisationnel sur matches pour un référent Live |
| Verrous | Trois flags serveur et trois flags client fermés ; arrêt testé par 03-disable.sql |
| RLS réelle | Tests ajoutant une politique SELECT/UPDATE restrictive : RPC bloquée malgré une identité habilitée |

Le rôle interne ne reçoit aucun SELECT sur auth.users. Les UUID cibles doivent exister
via les FK natives ; leur suppression retire les habilitations en cascade. Une identité
anonyme est refusée même si elle avait été habilitée par erreur. Les révocations relisent
les droits en base, sans dépendre d’un rafraîchissement des claims de rôle.

Les politiques supplémentaires visent exclusivement TO site_m01_executor. Les politiques
publiques existantes et security_invoker=true restent inchangées. Aucune désactivation
RLS et aucun BYPASSRLS ne sont utilisés. Aucun GRANT UPDATE global à authenticated.
Un administrateur des habilitations ne devient pas implicitement gestionnaire ou référent.

Le seul opérateur SQL propriétaire du schéma conserve l'appartenance de maintenance au
rôle interne, pour pouvoir appliquer l'arrêt 03 et maintenir les ACL. Il doit être INHERIT.
La relation est à sens unique : le rôle interne n'hérite pas des droits de l'opérateur.
Les rôles clients n'en sont jamais membres. Les privilèges DDL de l'opérateur hébergé
restent à confirmer par 00 ; les tests locaux n'affirment pas cette disponibilité réelle.

## Scripts et ordre exact

Les fichiers 01, 02, 04 et 03 du commit de référence sont conservés octet pour octet.
Leur séquence finale est assemblée, pour éviter tout état intermédiaire visible :

1. **00-install-preconditions.sql** : lecture seule sur le projet existant, avant accord
   d’installation ; contrôle des droits opérateur et recherche de dérogation ciblée.
2. Après accord humain seulement, **INSTALLATION.sql** : une seule transaction contenant
   **01 → 01a → 02 → 04 → 05**, puis notification de rechargement du schéma PostgREST.
   Un garde en échec annule toute l’installation, y compris le rôle SQL et les fonctions.
3. **05-verify-installation.sql** : également disponible séparément en lecture seule pour
   relire le résultat après installation, avant attribution/activation.
4. **03-disable.sql** : arrêt séparé, jamais inclus dans le lot d’installation.

`build-installation.py` reconstruit le lot et inscrit l’empreinte de chaque composant.
Le lot est testé tel quel et sa reproductibilité est contrôlée. Ne pas concaténer les
BEGIN/COMMIT d’origine ou exécuter tous les fichiers SQL par joker.

Préconditions précises : opérateur SQL autorisé à créer un rôle non privilégié, créer
le schéma/fonctions et déléguer leurs propriétaires ; auth.uid()/auth.jwt() disponibles ;
RLS activée sur matches/teams ; absence d’UPDATE client existant ; schéma/role site_m01
encore absents pour cette installation initiale ; vue identique au snapshot avec
security_invoker=true. Toute différence arrête le lot, sans DROP ou GRANT large automatique.
Les triggers de matches sont listés par 00 pour ne pas ignorer un effet de bord existant
sur les overrides ; si présents, contrôler uniquement ceux déclenchés par cette correction.

## Raccordement Gestion et Live

Une seule source de rencontres : public.matches.id UUID, relation public.teams.id.
Les cinq correspondances finalisées sont conservées. La Gestion compose les corrections
partielles dans scheduled_local_override et ne modifie la salle que par venue_name_override.
Les données FFBB restent hors des colonnes UPDATE autorisées. Le client confirme seulement
après relecture privée et propagation à public_calendar.

Le patch 04 reste celui déjà testé : uniquement les trois projections de salle MiniBasket,
U18M et U13/U15. Les filtres, colonnes, exclusions, horaires inconnus et options de vue
sont conservés, avec garde de définition/options et sauvegarde privée.

Le Live reste dans match_state avec FK vers le match existant : sept étapes, score
facultatif indépendant, aucune écriture dans le résultat officiel. Les règles par UUID
réel d’équipe et libellé de compétition restent fermées par défaut : numeric pour U11 M1
avec DMU11-4-P2 validé ; aucun score pour U11 M2/DMU11-10-P2 et U9. Les réponses SQL
omettent les scores interdits avant transmission. Les utilisateurs Live ne peuvent
modifier ni les règles sportives ni les informations Gestion.

## Dérogations : résultat de la recherche ciblée

Aucune occurrence de dérogation/demande de report n’a été trouvée dans les fichiers du
dépôt, y compris app/, documentation et scripts. Le snapshot reçu ne décrit aucun
mécanisme de demande. Les overrides de matches sont des corrections effectives, **pas
un suivi de demandes administratives**.

La lecture de métadonnées hébergées a été refusée par le connecteur. Il est donc impossible
d’affirmer qu’aucun dispositif n’existe dans une autre structure du projet ou l’application.
`00-install-preconditions.sql` cherche uniquement les noms de relations/fonctions/colonnes
pertinents et les clés source_data correspondantes, jamais les textes ou identités.

**Seul manque identifié : aucun point d’entrée de suivi de dérogation vérifié n’est
actuellement raccordable.** Si la lecture révèle un dispositif existant, reprendre son
identifiant/point d’accès privé après vérification des droits. Si elle confirme l’absence,
l’adaptation minimale proposée est un suivi privé de demande, rattaché par FK à matches.id,
avec état et valeurs proposées ; l’accord ne doit pas être déduit d’un override existant.
Cette extension n’est ni créée ni ajoutée à l’interface sans validation du club. Aucun
contenu administratif ne sera exposé dans public_calendar. Ce manque ne bloque pas les
fonctions Gestion/Live déjà préparées.

## Vérifications hébergées réellement effectuées

- GET public `/auth/v1/settings` du projet existant : HTTP 200 ; fournisseur e-mail actif,
  mailer_autoconfirm=false, identités anonymes désactivées. Aucune configuration modifiée.
- disable_signup=false est un réglage global existant ; le client SITE-M01 conserve
  create_user:false. Une inscription Auth ne crée jamais une habilitation.
- Aucun code OTP envoyé, aucune session utilisateur testée et aucun compte créé.
- Lectures SQL ciblées refusées par le connecteur : schéma/permissions actuels et circuit
  de dérogation hébergé restent à confirmer, pas déclarés réussis.

Interventions humaines précises restant nécessaires :

1. Exécuter **00-install-preconditions.sql en lecture seule** dans le SQL Editor de
   fgswygeqstgagmipltpq et examiner son résultat. Cela couvre la disponibilité du rôle
   d’installation, les préconditions et le seul point de recherche de dérogation manquant.
2. Dans Auth du même projet, confirmer le modèle Magic Link contenant `{{ .Token }}` et
   le service d’envoi avant la recette OTP sur un compte existant choisi par le club.
3. L’installation et les essais d’écriture restent soumis à un accord distinct : rien
   de ce document ne l’exécute ni ne l’autorise implicitement.

## Décisions indispensables avant activation

- Accord sur le lot atomique contrôlé et opérateur autorisé sur **ce projet existant**.
- UUID Auth existants des acteurs, UUID d’équipes et règles de compétition à configurer
  manuellement ; aucune demande de nom/adresse à cette étape.
- Accord borné sur les matches existants et corrections à utiliser pour la recette réelle,
  avec valeurs avant/après conservées et procédure d’arrêt prête.

Le choix d’une extension de dérogation ne serait nécessaire que si l’absence du dispositif
est confirmée ; aucune création n’est incluse dans la présente préparation.
