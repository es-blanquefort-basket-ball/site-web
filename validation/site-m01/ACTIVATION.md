# SITE-M01 — Séquence d’intégration contrôlée actuelle

**Procédure actuelle, remplaçant les séquences préparatoires antérieures.**
Cible unique : projet existant `fgswygeqstgagmipltpq`. Aucun nouveau projet Supabase.
Aucune migration ou écriture en production n’est autorisée par cette livraison.

Le [contrôle de sécurité et le point dérogations](INTEGRATION_REELLE.md) détaille le
rôle interne sans BYPASSRLS et le durcissement obligatoire de la base cbbe273.

## 1. Avant l’accord d’installation

Mise à jour du 9 novembre 2026 : les contrôles transmis sont pris en compte dans
[l'avis corrigé](AVIS_INSTALLATION.md). Le nouveau 01a utilise deux relais Auth privés
SECURITY INVOKER à corps préanalysé, sans GRANT sur auth. Le lot régénéré est
techniquement préparé pour ces ACL ; il vérifie USAGE de l'installateur (sans délégation)
et sonde les helpers sous l'exécuteur avant COMMIT. Ne pas relancer un audit général.
Après accord explicite seulement, utiliser cette nouvelle copie d'INSTALLATION.sql.

- Relire le lot, ses empreintes et le contrôle de sécurité.
- Faire exécuter `sql/00-install-preconditions.sql` en lecture seule dans le SQL Editor du
  projet existant. Le connecteur n’a pas permis de faire cette lecture. Aucun audit FFBB.
- Vérifier que schéma site_m01 et rôle site_m01_executor n’existent pas déjà ; ne jamais
  les supprimer pour forcer une installation. Examiner un éventuel écart avant d’agir.
- Conserver une sauvegarde du schéma, des ACL/options et de la vue actuelle.
- L’opérateur doit pouvoir créer le rôle SQL limité et déléguer les fonctions. Si ces
  droits manquent, faire intervenir l’opérateur habilité, sans donner UPDATE aux clients.

## 2. Installation, seulement après accord explicite

Exécuter **uniquement `sql/INSTALLATION.sql`** pour l’installation initiale.
Il contient une seule transaction, dans cet ordre :

1. `01-access-live.sql` — tables privées et signatures RPC existantes.
2. `01a-rls-executor.sql` — propriétaire limité, politiques RLS et privilèges minimaux.
3. `02-configure.sql` — cinq correspondances finalisées, identifiants UUID vérifiés.
4. `05-verify-installation.sql` — contrôle des quatre branches de la vue et de
   security_invoker=true, puis des autres garanties ; tous les verrous restent fermés.
5. Notification de rechargement PostgREST, puis COMMIT unique.

Ne pas exécuter 01 isolément : son propriétaire privilégié initial ne doit jamais être
mis en service. L’assemblage atomique évite tout état intermédiaire exposé. Une précondition
en échec annule le lot ; ne pas retirer le garde de vue ou affaiblir les permissions.

Le schéma site_m01 reste hors des schémas exposés Data API. Les façades publiques sont
SECURITY INVOKER ; les fonctions privées privilégiées s’exécutent sous un rôle NOLOGIN,
NOSUPERUSER et NOBYPASSRLS, qui ne possède aucune table et n’est pas délégué aux clients.
Aucun UPDATE global de matches pour authenticated ou anon.

Après installation, relire 05 séparément en lecture seule avant attribution de droits.
Cette étape ne prouve pas encore le parcours OTP/HTTP : celui-ci reste une recette réelle.

## 3. Configurer les acteurs au moment de la validation

Aucune création ni habilitation d’utilisateur réel dans la présente livraison.
Le club choisira les UUID Auth **déjà existants**, les UUID réels d’équipes et les rencontres
de recette. Aucun nom, e-mail ou UUID réel n’est demandé maintenant.

- L’opérateur habilité inscrit le seul administrateur choisi dans administrators.
- Après accord portant sur cette écriture de configuration, ouvrir uniquement access_enabled
  côté base et accessWritesApproved dans une copie locale de l’interface dirigée vers le
  projet existant. Mettre backendReady=true pour joindre les RPC installées.
- L’administrateur connecté utilise setAccess / site_m01_set_access : utilisateur Auth,
  équipe réelle, booléens Gestion, Live et enabled explicites. Relire par access_list.
- Attribuer les profils de recette du document RECETTE_REELLE.md ; refermer ensuite le
  verrou de configuration. Un administrateur n’a pas Gestion/Live implicitement.
- Révocation = enabled:false, sans effacer la ligne manuelle. Une future origine club_app
  ne doit pas rétablir un droit révoqué ; aucune synchronisation n’est développée ici.

## 4. Configurer les règles sportives réelles

Par UUID d’équipe, jamais par nom approchant, renseigner team_rules :
U11 M1/DMU11-4-P2/numeric ; U11 M2/DMU11-10-P2/minibasket-no-score ; U9/u9-no-score.
source_competition reprend le libellé effectif de public_calendar.competition_label.
competition_name est un libellé, pas un code DMU11 supposé. Une règle absente ou non
concordante interdit le score. Les référents Live ne peuvent modifier ces règles.
Les recettes commentées de 02 précisent la structure, sans insérer de valeur réelle.

## 5. Recette sur le projet existant, après accord borné

Suivre RECETTE_REELLE.md. Commencer par Auth et les accès en lecture, sans ouvrir Gestion/Live.
Pour l’OTP, vérifier le modèle `{{ .Token }}` et l’envoi, puis employer l’adresse du compte
existant désigné. Le client conserve create_user:false ; aucun compte n’est créé par lui.

N’ouvrir management_enabled / live_enabled et leurs homologues clients qu’après accord
explicite sur les matches existants et valeurs concernés. Les quatre booléens versionnés
restent false jusqu’à cette décision. Ne pas modifier les sources FFBB ni résultats officiels.

Les essais ne sont pas anonymes ou implicitement autorisés par une adresse saisie : il
faut une session Auth et les droits par équipe. Les identités des correcteurs restent privées.

## 6. Arrêt immédiat et retour arrière

`sql/03-disable.sql`, séparé du lot, ferme les trois flags serveur et révoque EXECUTE des
mutations publiques/privées. Remettre les flags client à false. Les politiques RLS ferment
également UPDATE des overrides quand management_enabled=false : testé même en contexte
interne avec une identité auparavant habilitée. L’historique et les données sont conservés.

Ne pas supprimer les états Live, droits ou historique pour arrêter le service. Si un retour
de vue est nécessaire, reprendre la sauvegarde privée après contrôle d’une éventuelle
évolution ultérieure ; ne jamais écraser celle-ci automatiquement. Les corrections de
rencontres ne sont pas annulées en masse. Toute réouverture nécessite un accord nouveau.

Aucune fusion main ou publication Hostinger n’est incluse.
