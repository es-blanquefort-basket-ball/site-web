# CARNET DE CONCEPTION --- SITE ES BLANQUEFORT BASKET

**Version : V1 --- 21/08/2026**\
**Statut : document maître de pilotage du chantier Site**\
**Projet : Site internet ES Blanquefort Basket**

> Ce carnet conserve l'état du chantier, les décisions acquises, les
> arbitrages, les priorités, les dépendances et les prochaines actions.
>
> Il ne remplace pas la documentation technique du repository.
>
> Documents complémentaires :
>
> -   `AGENTS.md`
> -   `README_SITE.md`
> -   `ARBORESCENCE_SITE.md`
> -   `COMPOSANTS_SITE.md`
> -   `CONVENTIONS_SITE.md`
>
> **Principe directeur : le site existe déjà. On consolide et actualise
> l'existant avant toute évolution de fond. Une demande locale ne
> devient jamais automatiquement une refonte générale.**

------------------------------------------------------------------------

# 00 --- ÉTAT GLOBAL

## 00.1 Situation générale

**État : EXISTANT / À CONSERVER**

Le site ES Blanquefort Basket est déjà largement construit.

Il est actuellement constitué principalement de pages HTML, d'une
feuille CSS commune, d'un JavaScript léger et de ressources graphiques.

L'architecture générale a été cartographiée et validée.

Le chantier actuel n'est pas une création de site et n'est pas une
nouvelle refonte complète.

## 00.2 Objectif actuel

L'objectif immédiat est double :

1.  **mettre rapidement le site existant à jour pour la rentrée
    2026-2027** ;
2.  poursuivre ensuite, sans urgence artificielle, les chantiers de fond
    : partenaires, Design System, inscriptions, guides et modernisation
    progressive.

## 00.3 Principe de continuité

Le site doit rester exploitable pendant toute la durée du chantier.

Les améliorations futures doivent pouvoir être réalisées :

-   page par page ;
-   composant par composant ;
-   chantier par chantier ;

sans imposer une reconstruction générale.

------------------------------------------------------------------------

# 01 --- ARCHITECTURE ACQUISE

## 01.1 Statut

**VALIDÉ**

L'architecture générale du site ne doit pas être remise en cause sans
demande explicite.

## 01.2 Navigation principale de référence

``` text
Accueil
Le club
Équipes
Planning
Matchs
Partenaires
S’inscrire
```

## 01.3 Pages publiques identifiées

``` text
index.html
le-club.html
equipes.html
planning.html
matchs.html
partenaires.html
sponsors.html
inscriptions.html
essais.html
contact.html
mentions_legales_ESBB.html
404.html
```

## 01.4 Espace application

Le dossier `app/` constitue une couche distincte du site public.

Il comprend notamment des interfaces destinées :

-   aux licenciés / familles ;
-   aux coachs ;
-   au bureau / dirigeants.

## 01.5 Décision structurante

**VALIDÉ**

Le site public reste une vitrine accessible sans application.

Les informations publiques essentielles, notamment les informations
permettant de découvrir le club et les horaires, doivent rester
accessibles sur le site.

Référence détaillée : `ARBORESCENCE_SITE.md`.

------------------------------------------------------------------------

# 02 --- INFRASTRUCTURE GITHUB / HOSTINGER

## 02.1 Repository

**VALIDÉ**

Repository GitHub de référence :

``` text
es-blanquefort-basket-ball/site-web
```

## 02.2 Branche principale

``` text
main
```

`main` représente la version de référence validée du repository.

## 02.3 Copies locales

**VALIDÉ**

Laurence et Samuel disposent chacun d'une copie locale du même
repository via GitHub Desktop.

Ils peuvent donc travailler sur le même projet depuis deux ordinateurs
différents.

## 02.4 Synchronisation

Avant une nouvelle intervention technique :

``` text
Fetch origin
↓
Pull origin si nécessaire
↓
Créer / rejoindre la branche de travail
```

Après validation et fusion, l'autre poste récupère les modifications
depuis le repository.

## 02.5 Branches

**VALIDÉ**

Les modifications techniques doivent normalement être réalisées sur une
branche dédiée et non directement sur `main`.

Exemples :

``` text
update/rentree-2026
update/planning
design/partenaires
feature/guide-licencies
```

## 02.6 Hostinger

**VALIDÉ**

Hostinger reste l'environnement de publication du site.

GitHub et Hostinger ont des rôles différents :

``` text
GitHub
= code, historique, collaboration, versions

Hostinger
= site publié en production
```

Une modification présente sur GitHub ne vaut pas automatiquement
validation pour la production.

## 02.7 Mise en production

Avant une publication importante :

1.  contrôler la version ;
2.  sauvegarder la version en ligne lorsque nécessaire ;
3.  publier les fichiers validés ;
4.  contrôler le résultat en production ;
5.  conserver une possibilité de retour arrière.

------------------------------------------------------------------------

# 03 --- ORGANISATION LAURENCE / SAMUEL / CODEX

## 03.1 Intervenants

**VALIDÉ**

Le projet peut être utilisé par Laurence et Samuel.

Ils peuvent intervenir successivement dans une même conversation
ChatGPT.

L'IA doit donc gérer un **intervenant courant** et être prête à changer
d'intervenant au cours d'un même fil.

Si l'intervenant n'est pas connu, demander :

> « C'est Laurence ou Samuel ? »

Ne pas reposer cette question lorsque l'intervenant courant est connu.

## 03.2 Décisions

Les décisions validées sont enregistrées comme décisions du **projet
Site**.

L'identité de l'auteur n'est conservée que lorsqu'elle est réellement
utile à la traçabilité.

## 03.3 Travail à quatre mains

Laurence et Samuel peuvent travailler en parallèle.

Règle :

**éviter de modifier simultanément les mêmes fichiers sans
coordination.**

## 03.4 Codex

**VALIDÉ**

Codex est l'outil privilégié pour les modifications techniques du
repository lorsque cela est pertinent.

Avant toute intervention, Codex doit lire au minimum :

``` text
AGENTS.md
```

et les documents de référence nécessaires au chantier.

Les missions Codex doivent être cadrées.

Elles doivent préciser notamment :

-   objectif ;
-   périmètre ;
-   fichiers concernés si connus ;
-   données validées ;
-   éléments interdits de modification ;
-   tests attendus.

Le diff doit être contrôlé avant fusion.

------------------------------------------------------------------------

# 04 --- DOCUMENTATION DU PROJET

## 04.1 Socle documentaire créé

**TERMINÉ**

Les documents suivants ont été créés :

``` text
AGENTS.md
README_SITE.md
ARBORESCENCE_SITE.md
COMPOSANTS_SITE.md
CONVENTIONS_SITE.md
```

Ils ont été ajoutés au repository.

## 04.2 Rôle

### `AGENTS.md`

Règles obligatoires pour Claude, OpenAI, Codex ou autre agent
intervenant sur le projet.

### `README_SITE.md`

Guide technique : structure, méthode de travail, tests, sauvegardes et
déploiement.

### `ARBORESCENCE_SITE.md`

Architecture officielle et rôle fonctionnel des pages.

### `COMPOSANTS_SITE.md`

Inventaire des composants existants et règles de réutilisation.

### `CONVENTIONS_SITE.md`

Conventions de fichiers, dossiers, images, CSS, JavaScript et
documentation.

### `CARNET_DE_CONCEPTION_SITE.md`

Présent document.

Il devient la mémoire fonctionnelle et décisionnelle du chantier.

------------------------------------------------------------------------

# 05 --- DESIGN SYSTEM

## 05.1 Statut

**EN COURS**

Le Design System ES Blanquefort Basket constitue le socle visuel commun
des supports numériques et de communication du club.

## 05.2 Périmètre

Il doit progressivement couvrir notamment :

-   site internet ;
-   application ;
-   guide de l'application ;
-   publications ;
-   affiches ;
-   résultats ;
-   partenaires ;
-   convocations ;
-   sponsoring ;
-   documents.

## 05.3 Principes acquis

**VALIDÉ**

-   utilisation stricte de l'univers chromatique du logo ;
-   vert et blanc comme identité principale ;
-   pas d'ajout arbitraire de couleurs ;
-   pas d'emojis comme éléments graphiques sauf demande explicite ;
-   identité sportive, moderne, claire et associative ;
-   composants cohérents ;
-   responsive ;
-   cohérence entre supports.

## 05.4 TRANSVERSAL SITE ↔ APP

**TRANSVERSAL SITE ↔ APP**

Le site et l'application doivent appartenir au même univers visuel.

Ils ne doivent cependant pas avoir exactement la même interface.

Le site est une vitrine publique.

L'application est un outil opérationnel.

## 05.5 Mockup application

**VALIDÉ COMME RÉFÉRENCE D'UNIVERS**

Le mockup validé de l'accueil de l'application constitue une référence
importante pour la future évolution graphique du site.

Il ne doit pas être reproduit à l'identique sur le site.

## 05.6 Priorité actuelle

Le Design System ne doit pas bloquer la mise à jour urgente de rentrée.

**SITE-R01 utilise le design existant.**

La modernisation graphique viendra progressivement ensuite.

------------------------------------------------------------------------

# 06 --- SITE-R01 --- RENTRÉE 2026-2027

## 06.1 Statut

**ACTIF --- PRIORITÉ IMMÉDIATE**

## 06.2 Objectif

Mettre rapidement à jour les pages HTML existantes pour que le site soit
utile et publiable pour la rentrée 2026-2027.

**Pas de refonte dans ce chantier.**

## 06.3 Contenus prioritaires

### R01-A --- Créneaux d'entraînement

**À ACTUALISER**

Mettre à jour les créneaux 2026-2027 :

-   catégories ;
-   jours ;
-   horaires ;
-   salles.

Page principale :

``` text
planning.html
```

Les données détaillées doivent être fournies ou vérifiées avant
intégration.

Ne rien inventer.

### R01-B --- Tarifs 2026-2027

**À ACTUALISER**

Mettre les tarifs de la saison à jour sur les pages concernées.

Les tarifs doivent être vérifiés à partir des données validées du club
avant modification technique.

### R01-C --- Dates de reprise

**À ACTUALISER**

Afficher les dates de reprise utiles aux familles et licenciés.

Ne pas confondre :

-   créneaux ponctuels de reprise ;
-   entraînements réguliers ;
-   demandes de réservation ;
-   créneaux réellement confirmés.

### R01-D --- Actualité rentrée

**À CRÉER / ACTUALISER**

Préparer une actualité de rentrée 2026-2027 permettant notamment
d'orienter vers :

-   reprise ;
-   planning ;
-   inscriptions ;
-   essais ;
-   informations pratiques.

### R01-E --- Rentrée des associations

**À COMPLÉTER / À PUBLIER**

Prévoir une information sur la présence du club à la rentrée des
associations.

Données nécessaires :

-   date : `[À COMPLÉTER]`
-   horaires : `[À COMPLÉTER]`
-   lieu / emplacement : `[À COMPLÉTER]`
-   modalités utiles : `[À COMPLÉTER]`

### R01-F --- Demander des renseignements

**À METTRE EN PLACE**

Créer un accès simple permettant à un visiteur de demander des
renseignements.

Principe acquis :

-   dispositif simple ;
-   visible ;
-   pas de formulaire inutilement long ;
-   orienté équipe / essai / inscription selon le besoin.

Le contenu exact et la destination doivent être vérifiés avant
publication.

### R01-G --- Essais / inscriptions

**À VÉRIFIER**

Contrôler que les informations utiles à la rentrée sont cohérentes sur
les pages existantes.

Ne pas lancer à cette occasion la refonte complète du parcours
Inscriptions.

## 06.4 Pages potentiellement concernées

Prioritairement :

``` text
planning.html
inscriptions.html
index.html
essais.html
contact.html
```

La liste finale dépendra des contenus réellement présents.

## 06.5 Méthode SITE-R01

``` text
DONNÉES VALIDÉES
↓
BRANCHE DE TRAVAIL
↓
MODIFICATIONS MINIMALES
↓
TESTS
↓
CONTRÔLE DU DIFF
↓
VALIDATION
↓
FUSION
↓
PUBLICATION HOSTINGER
```

------------------------------------------------------------------------

# 07 --- SITE-P01 --- PARTENAIRES

## 07.1 Statut

**PRIORITAIRE APRÈS / EN PARALLÈLE DE LA RENTRÉE**

Le démarchage partenaires continue. Le site doit pouvoir servir de
support commercial.

## 07.2 Objectifs

Vérifier et améliorer :

-   partenaires actuels ;
-   présentation des partenaires ;
-   fiches / pages ;
-   offres partenaires ;
-   possibilités de sponsoring ;
-   dispositifs de visibilité ;
-   parcours « devenir partenaire » ;
-   dossier de partenariat ;
-   qualité commerciale de la présentation.

## 07.3 Pages existantes

``` text
partenaires.html
sponsors.html
```

## 07.4 Décision acquise

**VALIDÉ**

Les deux pages n'ont pas le même rôle :

``` text
partenaires.html
= offre / démarche / devenir partenaire

sponsors.html
= partenaires existants / Mur des verts et blancs
```

Ne pas les fusionner automatiquement.

## 07.5 TRANSVERSAL SITE ↔ APP

**TRANSVERSAL SITE ↔ APP**

La visibilité partenaire doit être pensée de manière cohérente entre :

-   site public ;
-   application ;
-   supports de communication ;
-   éventuelles offres ou avantages partenaires.

------------------------------------------------------------------------

# 08 --- SITE-R02 --- INSCRIPTIONS / LICENCES

## 08.1 Statut

**PRÉVU --- ARBITRAGES DÉJÀ NOMBREUX**

Le parcours a déjà fait l'objet d'un travail important.

Ne pas repartir de zéro.

## 08.2 Parcours fonctionnel cible

``` text
Essayer
↓
Se préinscrire
↓
Renouveler
↓
Régler
↓
Documents
↓
Aides
↓
Assurances
↓
FAQ / Guide
```

Les parcours varient selon qu'il s'agit d'un nouveau licencié ou d'un
renouvellement.

## 08.3 Pré-inscription nouveaux licenciés

**VALIDÉ**

La demande de pré-inscription :

-   n'engage pas le futur licencié tant que le règlement n'est pas
    effectué ;
-   permet notamment d'être identifié pour les essais ;
-   nécessite les informations nécessaires à la génération du lien
    fédéral ;
-   est générée par le club dans le processus fédéral ;
-   reste en attente jusqu'aux essais ou au règlement selon le cas.

## 08.4 Principes déjà acquis

**VALIDÉ**

-   mineurs : certificat médical non obligatoire selon le cadre déjà
    retenu ;
-   assurance FFBB : règlement en ligne ;
-   majeurs : ne pas demander d'attestation extrascolaire ;
-   Carte Clé : uniquement si étudiant ;
-   Pass'Sport : ne pas le présenter comme dispositif applicable aux
    majeurs ;
-   ordre de déduction déjà arbitré : Pass'Sport puis chèque sport ;
-   montant minimal déjà arbitré : 10 €.

Les règles réglementaires susceptibles d'évoluer doivent être vérifiées
au moment de leur publication.

## 08.5 Guide licenciés

Le guide doit rester court, pratique et adapté au web.

Il doit pouvoir être intégré au site en HTML et évoluer ensuite.

------------------------------------------------------------------------

# 09 --- SITE-C01 --- CONTENUS SAISON

## 09.1 Statut

**À PLANIFIER**

Audit saisonnier général à réaliser après la mise à jour urgente ou au
fil des besoins.

## 09.2 Points à contrôler

-   équipes réellement engagées ;
-   catégories ;
-   saison affichée ;
-   horaires ;
-   salles ;
-   coordonnées ;
-   liens ;
-   partenaires ;
-   informations d'essais ;
-   inscriptions ;
-   matchs ;
-   contenus devenus obsolètes ;
-   mentions nécessitant une mise à jour.

## 09.3 Règle

Une donnée d'une saison précédente ne doit jamais être reconduite
automatiquement.

------------------------------------------------------------------------

# 10 --- MATCHS

## 10.1 Chantier

`SITE-M01`

## 10.2 Statut

**À ALIMENTER LORSQUE LES DONNÉES VALIDÉES SONT DISPONIBLES**

Page existante :

``` text
matchs.html
```

Elle doit pouvoir accueillir le calendrier / les rencontres / les
résultats selon le fonctionnement retenu.

Ne pas inventer de rencontres ni de résultats.

------------------------------------------------------------------------

# 11 --- GUIDES

## 11.1 SITE-G01 --- Guide des licenciés

**PRÉVU**

Objectifs :

-   guide court ;
-   utilisable sur mobile ;
-   cohérent avec le Design System ;
-   intégrable en HTML ;
-   facilement actualisable ;
-   complémentaire de la page Inscriptions.

## 11.2 SITE-G02 --- Guide de l'application

**PRÉVU PLUS TARD**

À intégrer lorsque l'application sera suffisamment stabilisée.

Le guide doit pouvoir évoluer sans nécessiter de reconstruire le site.

------------------------------------------------------------------------

# 12 --- TRANSVERSAL SITE ↔ APP

## 12.1 Principe

**VALIDÉ**

Le Site et l'Application ont deux carnets séparés.

Ils avancent parallèlement.

Seuls les sujets réellement communs sont synchronisés.

## 12.2 Sujets transversaux identifiés

### Design System

Même identité générale, interfaces adaptées aux usages.

### Équipes et catégories

Les données métier doivent rester cohérentes entre les deux projets.

### Partenaires

Présentation publique, visibilité dans l'application et supports
commerciaux doivent être cohérents.

### Inscriptions / licences

Le site explique et oriente.

L'application prend le relais pour les usages liés au compte et au
parcours du licencié lorsqu'ils existent.

### Informations club / actualités

À terme, éviter autant que possible les doubles saisies inutiles.

### Calendrier

Les mêmes données pourront avoir des présentations différentes selon le
support.

### Sources de données

À terme, certaines données pourront avoir une source commune.

Aucune architecture de synchronisation ne doit être inventée sans
chantier dédié.

------------------------------------------------------------------------

# 13 --- REGISTRE DES DÉCISIONS

## D-SITE-001 --- Conservation de l'existant

**VALIDÉ**

Le site existant est la base de travail. Pas de nouvelle refonte
complète par défaut.

## D-SITE-002 --- Architecture

**VALIDÉ**

L'arborescence générale est considérée comme acquise.

## D-SITE-003 --- Mise à jour urgente

**VALIDÉ**

Avant les chantiers de fond, mettre à jour les pages HTML existantes
pour la rentrée 2026-2027.

## D-SITE-004 --- Site public / application

**VALIDÉ**

Deux projets distincts, deux carnets distincts, avec sujets transversaux
explicitement identifiés.

## D-SITE-005 --- GitHub

**VALIDÉ**

Repository commun : `es-blanquefort-basket-ball/site-web`.

## D-SITE-006 --- Travail à deux

**VALIDÉ**

Laurence et Samuel travaillent sur le même repository depuis deux
postes.

## D-SITE-007 --- Intervenant ChatGPT

**VALIDÉ**

Un même fil peut être utilisé successivement par Laurence et Samuel.
L'IA doit gérer l'intervenant courant.

## D-SITE-008 --- Codex

**VALIDÉ**

Codex peut être utilisé pour les modifications techniques, sous contrôle
des documents de gouvernance et du diff.

## D-SITE-009 --- Documentation

**VALIDÉ**

Le repository contient un socle documentaire destiné à permettre une
reprise fiable du projet.

## D-SITE-010 --- Design System

**VALIDÉ**

Le Design System est transversal Site ↔ App, sans obligation
d'interfaces identiques.

## D-SITE-011 --- Priorité partenaires

**VALIDÉ**

Le chantier partenaires est prioritaire autour de la rentrée en raison
du démarchage en cours.

## D-SITE-012 --- Modernisation progressive

**VALIDÉ**

Les évolutions graphiques doivent pouvoir être réalisées progressivement
sans bloquer les mises à jour de contenu.

------------------------------------------------------------------------

# 14 --- POINTS OUVERTS

## O-SITE-001 --- Créneaux 2026-2027

**À FOURNIR / VÉRIFIER**

Tableau détaillé à utiliser pour `planning.html`.

## O-SITE-002 --- Tarifs 2026-2027

**À VÉRIFIER AVANT MODIFICATION**

Utiliser uniquement la grille validée pour la saison.

## O-SITE-003 --- Dates de reprise

**À CENTRALISER / VALIDER**

Distinguer les reprises par équipe des créneaux ponctuels ou
réservations.

## O-SITE-004 --- Rentrée des associations

**\[À COMPLÉTER\]**

-   date ;
-   horaires ;
-   lieu / emplacement ;
-   contenu à publier.

## O-SITE-005 --- Renseignements

**À VALIDER**

Déterminer la destination exacte du bouton / parcours de contact.

## O-SITE-006 --- Branche SITE-R01

**À CRÉER**

Nom à utiliser selon convention du repository.

## O-SITE-007 --- Publication Hostinger

**À ORGANISER AU MOMENT DE LA LIVRAISON**

Déterminer précisément le mode de publication de SITE-R01 après
validation.

------------------------------------------------------------------------

# 15 --- ROADMAP

## PHASE 1 --- Maintenant

### SITE-R01 --- Rentrée 2026-2027

**PRIORITÉ 1**

Mettre à jour l'existant sans refonte.

### SITE-P01 --- Partenaires

**PRIORITÉ 2 / PARALLÉLISABLE**

Peut commencer pendant SITE-R01 si Laurence et Samuel travaillent sur
des fichiers différents.

## PHASE 2

### SITE-C01 --- Audit contenus saison

Contrôle complet 2026-2027.

### SITE-R02 --- Inscriptions / licences

Consolidation du parcours déjà conçu.

## PHASE 3

### SITE-DS01 --- Design System

Application progressive au site.

### SITE-G01 --- Guide licenciés

Intégration web.

## PHASE 4

### SITE-M01 --- Matchs

Selon disponibilité des données sportives.

### SITE-G02 --- Guide application

Selon maturité de l'application.

------------------------------------------------------------------------

# 16 --- PARALLÉLISATION

## Possible

Laurence et Samuel peuvent travailler en parallèle lorsque les
périmètres ne se chevauchent pas.

Exemple :

``` text
Laurence
SITE-R01 / contenus rentrée

Samuel
SITE-P01 / audit partenaires
```

ou inversement.

## À éviter

Deux personnes / deux agents modifiant simultanément :

``` text
index.html
style.css
```

sans coordination.

`style.css` est particulièrement transversal et peut créer des conflits
ou régressions.

## Règle

Avant d'ouvrir un chantier parallèle, identifier les fichiers
susceptibles d'être touchés.

------------------------------------------------------------------------

# 17 --- HISTORIQUE UTILE

## 21/08/2026

-   repository Site confirmé et utilisé comme base commune ;
-   Laurence et Samuel synchronisés via GitHub Desktop ;
-   socle documentaire ajouté au repository ;
-   règles de travail à quatre mains définies ;
-   Codex retenu comme outil possible pour les modifications techniques
    ;
-   décision de créer un projet ChatGPT Site distinct ;
-   instructions complètes et version courte du projet créées ;
-   décision de créer le présent Carnet de conception Site ;
-   priorité immédiate confirmée : mise à jour minimale de rentrée avant
    les travaux de fond.

------------------------------------------------------------------------

# 18 --- PROCHAINE ACTION

## Action immédiate

**Ouvrir SITE-R01 --- Mise à jour Rentrée 2026-2027.**

Avant de lancer Codex :

1.  récupérer / confirmer le tableau des créneaux d'entraînement
    2026-2027 ;
2.  confirmer la grille tarifaire 2026-2027 à publier ;
3.  centraliser les dates de reprise ;
4.  récupérer les informations de la rentrée des associations ;
5.  confirmer le moyen de contact à utiliser pour « Demander des
    renseignements ».

Ensuite :

``` text
Fetch / Pull
↓
Créer branche SITE-R01
↓
Rédiger mission Codex
↓
Modifier uniquement les pages existantes nécessaires
↓
Tester
↓
Contrôler le diff
↓
Valider
↓
Fusionner
↓
Publier sur Hostinger
```

------------------------------------------------------------------------

# 19 --- RÈGLE DE REPRISE D'UN NOUVEAU FIL

Lorsqu'un nouveau fil du projet Site est ouvert :

1.  lire le présent carnet ;
2.  identifier le chantier concerné ;
3.  vérifier les décisions acquises ;
4.  vérifier les points ouverts ;
5.  ne pas rouvrir les arbitrages déjà validés sans raison ;
6.  demander qui travaille --- Laurence ou Samuel --- si l'intervenant
    courant n'est pas identifiable ;
7.  reprendre à la **prochaine action** du chantier concerné.

> **Le carnet doit permettre de reprendre le travail sans reconstruire
> l'histoire du projet à chaque nouvelle conversation.**
