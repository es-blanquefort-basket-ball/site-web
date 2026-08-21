# ARBORESCENCE DU SITE --- ES BLANQUEFORT BASKET

> **Statut : architecture de référence du site**
>
> L'arborescence générale du site ES Blanquefort Basket est validée.\
> **Ne pas restructurer, supprimer, fusionner ou renommer des pages sans
> demande explicite du club.**
>
> Ce document décrit l'organisation fonctionnelle et technique du site.
> Il doit être consulté avant toute intervention humaine ou réalisée par
> un agent IA (Claude, OpenAI ou autre).

------------------------------------------------------------------------

## 1. Principes généraux

Le projet est composé de deux espaces distincts :

1.  **Le site public**, qui informe, présente le club, permet de
    découvrir les équipes, horaires, matchs, partenaires et démarches
    d'inscription.
2.  **L'espace application**, destiné aux licenciés, entraîneurs et
    dirigeants pour les usages internes ou personnalisés.

Le site public doit rester accessible et utile indépendamment de
l'application. Les informations publiques essentielles, notamment les
horaires, ne doivent pas être réservées aux utilisateurs de
l'application.

------------------------------------------------------------------------

## 2. Arborescence technique actuelle

``` text
public_html/
│
├── index.html
├── le-club.html
├── equipes.html
├── planning.html
├── matchs.html
├── partenaires.html
├── sponsors.html
├── inscriptions.html
├── essais.html
├── contact.html
├── mentions_legales_ESBB.html
├── 404.html
│
├── style.css
├── script.js
│
├── images/
│   ├── logo.png
│   ├── favicon.png
│   ├── equipe-club.jpg
│   ├── hero-basket-bg.png
│   └── sponsors/
│       ├── cartomedoc.png
│       ├── did-admin.png
│       ├── gm-toiture.png
│       ├── isy-project-electricite.png
│       ├── le-chai-nous.png
│       └── lrenov-ia-studio.png
│
├── assets/
│   ├── logo.png
│   ├── header-basket-bg.png
│   ├── hero-basket-bg.png
│   ├── icon-192.png
│   └── icon-512.png
│
└── app/
    ├── licencies.html
    ├── coachs.html
    ├── bureau.html
    ├── essais.html
    └── mentions_legales_ESBB.html
```

Cette structure correspond à l'état du site transmis lors de
l'établissement de cette cartographie.

------------------------------------------------------------------------

## 3. Navigation principale

La navigation publique de référence est :

``` text
Accueil
Le club
Équipes
Planning
Matchs
Partenaires
S’inscrire
```

### Règle

Cette navigation est considérée comme validée.

Un agent ne doit pas :

-   réorganiser le menu de sa propre initiative ;
-   supprimer une entrée ;
-   fusionner des rubriques ;
-   créer une nouvelle architecture globale ;
-   transformer le site en application monopage ;
-   renommer les rubriques sans demande explicite.

Une maquette ou une amélioration du **design du menu** peut être
proposée séparément sans modifier son architecture fonctionnelle.

------------------------------------------------------------------------

## 4. Cartographie fonctionnelle

``` text
ACCUEIL
│
├── LE CLUB
│   └── Présentation / valeurs / fonctionnement
│
├── ÉQUIPES
│   └── Catégories et équipes
│
├── PLANNING
│   └── Horaires / salles / entraînements
│
├── MATCHS
│   └── Calendrier / résultats
│
├── PARTENAIRES
│   ├── Offre de partenariat
│   └── Mur des verts et blancs
│
├── INSCRIPTIONS
│   ├── Essayer
│   ├── Se préinscrire
│   ├── Renouveler
│   ├── Régler
│   ├── Documents
│   ├── Aides
│   ├── Assurances
│   ├── Guide licencié
│   └── Guide application
│
├── ESSAIS
│   └── Formulaire / créneaux
│
└── CONTACT
```

Les éléments placés sous **Inscriptions** sont des fonctions ou contenus
à intégrer. Ils ne constituent pas automatiquement des pages HTML
distinctes. Ils peuvent être présentés sous forme de sections, onglets,
accordéons ou composants dans `inscriptions.html`.

------------------------------------------------------------------------

# 5. Rôle des pages publiques

## `index.html` --- Accueil

### Rôle

Porte d'entrée générale du site.

### Fonction

Présenter rapidement le club et orienter le visiteur vers les
principales rubriques.

### Contenus actuellement identifiés

-   présentation générale ;
-   identité du club ;
-   chiffres clés ;
-   essais et réinscriptions ;
-   informations / communications du club ;
-   partenaires.

### Règle

L'accueil reste une page de synthèse. Il ne doit pas absorber le contenu
détaillé des autres rubriques.

------------------------------------------------------------------------

## `le-club.html` --- Le club

### Rôle

Présenter l'identité, les valeurs et le projet associatif de l'ES
Blanquefort Basket.

### Axes actuellement présents

-   passion ;
-   formation ;
-   collectif ;
-   former ;
-   rassembler ;
-   structurer.

Cette page constitue la présentation institutionnelle du club.

------------------------------------------------------------------------

## `equipes.html` --- Équipes

### Rôle

Présenter les catégories et équipes du club.

### Catégories actuellement identifiées

-   U5 ;
-   U7 ;
-   U9F ;
-   U9M ;
-   U11F ;
-   U11M ;
-   U13F ;
-   U13M ;
-   U15F ;
-   U15M ;
-   U18M ;
-   Seniors M ;
-   Loisirs.

La liste évolue selon les équipes réellement engagées chaque saison. Ne
pas inventer ou supprimer une catégorie sans information validée par le
club.

------------------------------------------------------------------------

## `planning.html` --- Planning

### Rôle

Présenter publiquement :

-   les horaires d'entraînement ;
-   les salles ;
-   les catégories concernées.

### Principe important

Le planning doit rester disponible sur le site public, y compris
lorsqu'une application du club existe.

L'application complète le site mais ne remplace pas l'accès public aux
informations essentielles.

------------------------------------------------------------------------

## `matchs.html` --- Matchs

### Rôle

Présenter :

-   le calendrier ;
-   les rencontres ;
-   les résultats lorsque ces informations sont disponibles.

Cette page peut évoluer au cours de la saison sans modifier
l'arborescence générale du site.

------------------------------------------------------------------------

## `partenaires.html` --- Partenaires

### Rôle

Présenter l'offre de partenariat de l'ES Blanquefort Basket.

### Contenus possibles

-   devenir partenaire ;
-   présentation des formules ;
-   partenaire club ;
-   sponsor du match ;
-   partenaire projet ;
-   accès au dossier de partenariat.

------------------------------------------------------------------------

## `sponsors.html` --- Mur des verts et blancs

### Rôle

Présenter les partenaires et sponsors effectivement associés au club.

### Distinction obligatoire

``` text
partenaires.html
       ↓
présente l’offre et la démarche de partenariat

sponsors.html
       ↓
présente les partenaires existants
```

Ces deux pages ont donc des fonctions différentes et ne doivent pas être
fusionnées automatiquement.

------------------------------------------------------------------------

## `inscriptions.html` --- Inscriptions / Licences

### Rôle

Devenir le point central du parcours d'inscription et d'information des
licenciés.

### Parcours prévus

-   Essayer
-   Se préinscrire
-   Renouveler
-   Régler
-   Préparer ses documents
-   Utiliser une aide
-   Comprendre les assurances
-   Consulter le guide du licencié
-   Accéder au guide de l'application
-   Consulter les questions fréquentes

### Principe éditorial

Privilégier des intitulés directs reposant sur des verbes d'action.

Exemples :

-   **Essayer**
-   **Se préinscrire**
-   **Renouveler**
-   **Régler**
-   **Préparer ses documents**
-   **Utiliser une aide**

Éviter les formulations longues ou infantilisantes du type « Je
souhaite... ».

### Règle structurelle

L'enrichissement de `inscriptions.html` constitue un **ajout fonctionnel
au site existant**, pas le point de départ d'une refonte générale de son
architecture.

------------------------------------------------------------------------

## `essais.html` --- Essais

### Rôle

Permettre la consultation et la gestion publique du parcours d'essai.

### Fonctions identifiées

-   consulter les créneaux ;
-   choisir la catégorie adaptée ;
-   s'inscrire à un essai ;
-   recevoir ou afficher une confirmation selon le fonctionnement
    retenu.

### Distinction avec `inscriptions.html`

`inscriptions.html` **explique et oriente**.

`essais.html` permet d'**effectuer l'action liée aux essais**.

Les deux fonctions ne doivent pas être fusionnées automatiquement.

------------------------------------------------------------------------

## `contact.html` --- Contact

### Rôle

Centraliser les coordonnées publiques et les moyens de contacter le
club.

Les coordonnées doivent être considérées comme des données modifiables
et doivent être vérifiées avant toute publication.

------------------------------------------------------------------------

## `mentions_legales_ESBB.html` --- Mentions légales

### Rôle

Regrouper les informations réglementaires du site, notamment selon le
contenu réellement publié :

-   éditeur ;
-   responsable de publication ;
-   hébergement ;
-   données personnelles ;
-   cookies ;
-   responsabilité ;
-   informations relatives aux interfaces ou services numériques.

### Règle

Ne pas modifier les mentions légales à partir de suppositions. Toute
modification substantielle doit être fondée sur des informations
validées.

------------------------------------------------------------------------

## `404.html` --- Page d'erreur

### Rôle

Afficher une page personnalisée lorsqu'une ressource n'est pas trouvée.

La page actuelle utilise l'univers du basket et le message « La page est
hors jeu ».

Elle fait partie de l'identité du site et doit rester cohérente avec le
Design System.

------------------------------------------------------------------------

# 6. Espace application

Le dossier :

``` text
/app/
```

constitue une couche distincte du site public.

## `app/licencies.html`

### Public

Licenciés et familles.

### Fonctions identifiées

-   accueil personnalisé ;
-   informations concernant le licencié ;
-   entraînements ;
-   tournois ;
-   informations club ;
-   réinscriptions ;
-   essais.

------------------------------------------------------------------------

## `app/coachs.html`

### Public

Entraîneurs / coachs.

### Fonctions identifiées

-   calendrier de l'équipe ;
-   entraînements ;
-   liste d'équipe ;
-   tournois ;
-   préparation ou diffusion de messages ;
-   informations du club.

------------------------------------------------------------------------

## `app/bureau.html`

### Public

Bureau / dirigeants autorisés.

### Fonctions identifiées

-   tableau de bord ;
-   suivi des licenciés ;
-   suivi des essais ;
-   créneaux ;
-   diffusion ;
-   publication d'informations ;
-   questionnaires ou opérations internes.

------------------------------------------------------------------------

## Séparation fonctionnelle de référence

``` text
SITE PUBLIC
   │
   ├── Informer
   ├── Présenter
   ├── Recruter
   └── Orienter
          │
          ↓
APPLICATION
   │
   ├── Licenciés / familles
   ├── Coachs
   └── Bureau
```

Un agent ne doit pas transférer arbitrairement une information publique
essentielle vers l'application uniquement.

------------------------------------------------------------------------

# 7. Architecture technique commune

## `style.css`

`style.css` est la feuille de styles principale du site public.

Elle regroupe notamment :

-   palette ;
-   typographies ;
-   navigation ;
-   boutons ;
-   cartes ;
-   hero ;
-   tableaux ;
-   formulaires ;
-   pied de page ;
-   responsive ;
-   composants partenaires ;
-   animations ;
-   correctifs ajoutés au fil des versions.

### Règle pour les agents

Avant de créer un nouveau style :

1.  rechercher si un composant équivalent existe déjà ;
2.  réutiliser le Design System existant lorsque possible ;
3.  éviter de dupliquer les mêmes règles dans plusieurs pages ;
4.  éviter de créer une nouvelle feuille CSS dédiée à une seule page
    sans justification ;
5.  ne pas ajouter une nouvelle couche de correctifs globaux pour
    résoudre un problème local sans analyser l'impact sur les autres
    pages.

------------------------------------------------------------------------

## `script.js`

Le JavaScript commun du site reste volontairement léger.

Fonctions actuellement identifiées :

-   menu mobile / burger ;
-   animations d'apparition ;
-   compteurs animés.

### Principe

Ne pas introduire de framework ou de dépendance JavaScript importante
sans besoin explicite et validation préalable.

------------------------------------------------------------------------

# 8. Ressources graphiques

Les ressources sont principalement réparties entre :

``` text
/images/
/assets/
```

Les logos des partenaires sont rangés dans :

``` text
/images/sponsors/
```

### Règle future

Lors de l'évolution du site, privilégier une organisation stable et
documentée des ressources plutôt que de multiplier les copies d'un même
fichier.

Toute réorganisation importante des ressources devra préserver les
chemins utilisés par les pages existantes ou être accompagnée de la mise
à jour complète des références.

------------------------------------------------------------------------

# 9. Services et liens externes

Le site peut utiliser ou pointer vers des services externes, notamment
pour :

-   les inscriptions ;
-   les essais ;
-   les règlements ;
-   les partenariats ;
-   certains formulaires ou outils.

### Règle

La présence actuelle d'un lien externe ne signifie pas qu'il doit être
conservé définitivement ni qu'il doit être remplacé.

Toute décision de :

-   conserver un service externe ;
-   intégrer son contenu dans Hostinger ;
-   utiliser un widget ;
-   modifier une URL ;
-   supprimer un intermédiaire GitHub ;

doit être prise explicitement dans le cadre du chantier concerné.

------------------------------------------------------------------------

# 10. Règles impératives pour toute intervention

Avant toute modification du site, un agent doit déterminer la nature
exacte de la demande.

## Modification de contenu

Exemples :

-   changer un horaire ;
-   corriger un texte ;
-   ajouter une équipe ;
-   modifier un lien.

**Ne pas modifier le design ou l'architecture si cela n'est pas
demandé.**

## Modification graphique

Exemples :

-   moderniser une carte ;
-   modifier un bouton ;
-   faire évoluer le menu visuellement.

**Ne pas réécrire les contenus ni restructurer l'arborescence si cela
n'est pas demandé.**

## Modification structurelle

Exemples :

-   ajouter une page ;
-   modifier la navigation ;
-   fusionner deux rubriques.

Une modification structurelle doit être explicitement demandée ou
validée par le club.

------------------------------------------------------------------------

# 11. Ce qu'un agent IA ne doit jamais décider seul

Un agent Claude, OpenAI ou autre ne doit pas, de sa propre initiative :

-   refaire entièrement le site ;
-   modifier l'arborescence validée ;
-   supprimer une page ;
-   fusionner des pages ;
-   changer les URL existantes ;
-   modifier l'identité graphique globale ;
-   inventer des équipes ;
-   inventer des horaires ;
-   inventer des tarifs ;
-   inventer des coordonnées ;
-   inventer des règles FFBB ;
-   publier directement une modification en production ;
-   remplacer une technologie existante par un framework ;
-   déplacer une information publique essentielle exclusivement dans
    l'application.

En cas d'information manquante, utiliser **\[À COMPLÉTER\]** ou demander
validation.

------------------------------------------------------------------------

# 12. Évolutions déjà identifiées

Les chantiers connus comprennent notamment :

-   enrichissement de la page Inscriptions ;
-   création / intégration du guide des licenciés ;
-   intégration future du guide de l'application ;
-   amélioration progressive de certains composants visuels ;
-   application du Design System ES Blanquefort Basket ;
-   évolution des contenus de saison ;
-   alimentation de la page Matchs ;
-   maintien des horaires publics ;
-   amélioration progressive sans nouvelle refonte globale non demandée.

Ces évolutions ne remettent pas en cause l'arborescence générale décrite
dans ce document.

------------------------------------------------------------------------

# 13. Documents de gouvernance du projet

À terme, le dépôt du site devra comporter au minimum :

``` text
README_SITE.md
ARBORESCENCE_SITE.md
AGENTS.md
```

### `README_SITE.md`

Explique le fonctionnement général du projet, son installation, ses
fichiers principaux, les tests et le déploiement.

### `ARBORESCENCE_SITE.md`

**Le présent document.**

Définit l'organisation validée du site et le rôle des pages.

### `AGENTS.md`

Donnera les instructions opérationnelles obligatoires aux agents IA qui
interviennent sur le projet.

------------------------------------------------------------------------

# 14. Principe de gouvernance

> **Le site doit évoluer sans être constamment reconstruit.**

Les interventions doivent être ciblées, réversibles et cohérentes avec
le Design System du club.

Lorsqu'une demande concerne une seule page ou un seul composant, l'agent
doit privilégier une modification limitée au périmètre demandé.

Toute décision engageant l'architecture, l'identité du club, les
contenus officiels ou la mise en production reste soumise à validation
humaine de l'ES Blanquefort Basket.
