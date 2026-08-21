# COMPOSANTS_SITE.md --- ES Blanquefort Basket

> **Inventaire des composants réellement présents dans le site
> transmis**
>
> Ce document sert de référence avant toute création ou modification
> d'interface.
>
> Règle : **réutiliser avant de créer**.
>
> Cet inventaire décrit l'existant. Il ne signifie pas que tous les
> composants actuels sont définitivement validés dans le futur Design
> System.

------------------------------------------------------------------------

# 1. Composants structurels communs

## Header / navigation principale

### HTML observé

Composants et classes principales :

``` text
#hdr
.wrap
.nav
.brand
.brand-text
.brand-name
.brand-sub
.burger
.navlinks
.active
.btn
.btn-primary
```

### Présence

Le header est répété sur les principales pages publiques.

### Fonction

-   logo et identité du club ;
-   navigation principale ;
-   bouton `S’inscrire` ;
-   menu burger mobile.

### Règle

Avant toute modification du header, vérifier toutes les pages publiques
concernées. Ne pas créer un second header parallèle.

------------------------------------------------------------------------

## Bandeau partenaires

### Classe principale

``` text
.sponsor-strip
```

### Fonction

Bandeau placé sous la navigation sur plusieurs pages pour promouvoir les
partenaires et le dossier partenariat.

### Règle

Traiter son texte et son URL comme des données modifiables. Ne pas
changer son rôle sans validation.

------------------------------------------------------------------------

## Conteneurs de mise en page

Classes récurrentes :

``` text
.wrap
.container
.grid
.grid-2
.grid-3
```

### Fonction

Structurer les largeurs et grilles du site.

### Règle

Réutiliser ces conteneurs avant de créer une nouvelle grille.

------------------------------------------------------------------------

# 2. Titres et hiérarchie éditoriale

## Eyebrow / surtitre

``` text
.eyebrow
```

Utilisé pour introduire une section ou une catégorie de contenu.

## Titre de section

``` text
.section-title
```

Souvent combiné avec un `span` pour mettre une partie du titre en
valeur.

## Texte introductif

``` text
.lead
```

Utilisé pour les paragraphes d'introduction.

## En-tête de page

``` text
.page-head
```

Variantes observées :

``` text
.sponsors-head
.page-head-partners
.page-head-grid
```

### Règle

Conserver une hiérarchie HTML sémantique (`h1`, `h2`, `h3`)
indépendamment du rendu visuel.

------------------------------------------------------------------------

# 3. Hero et introductions

Classes observées :

``` text
.hero
.hero-actions
.hero-logo
.home-hero
.main-hero
.inner-hero
.page-hero
.sub-hero
.hero-small
```

Le hero de l'accueil associe :

-   un surtitre ;
-   un grand titre ;
-   un texte ;
-   des actions ;
-   le logo du club.

### Règle

Ne pas créer un nouveau type de hero sans vérifier si une variante
existante peut être adaptée.

------------------------------------------------------------------------

# 4. Boutons

## Base

``` text
.btn
```

## Variantes observées

``` text
.btn-primary
.btn-ghost
.btn-orange
```

### Usages

-   action principale ;
-   action secondaire ;
-   appel éditorial spécifique.

### Règle

Une nouvelle action doit utiliser une variante existante lorsqu'elle
correspond au besoin.

Ne pas créer une nouvelle couleur ou forme de bouton uniquement pour
différencier une page.

------------------------------------------------------------------------

# 5. Cartes

La classe générique la plus utilisée est :

``` text
.card
```

Elle apparaît très largement dans le site.

Variantes ou composants associés observés :

``` text
.card-xl
.news-card
.sponsor-card
.signup-card
.signup-intro
.signup-note
.banner-card
.partner-showcase-card
```

### Règle

Le site actuel repose fortement sur les cartes. Le futur Design System
pourra faire évoluer leur langage graphique, mais un agent ne doit pas
remplacer ou multiplier les variantes de sa propre initiative.

------------------------------------------------------------------------

# 6. Cartes équipes

Classes principales :

``` text
.team-card
.team-top
.team-years
.team-actions
```

### Fonction

Présenter les catégories et informations liées aux équipes.

### Règle

Toute nouvelle équipe doit réutiliser la structure existante tant qu'une
évolution du composant n'a pas été validée.

Ne jamais inventer une équipe ou une catégorie.

------------------------------------------------------------------------

# 7. Partenaires et sponsors

## Mur des partenaires

Classes observées :

``` text
.sponsor-wall-grid
.sponsor-logo-card
.logo-box
.sponsor-wall-hero
.sponsor-wall-promo
```

Chaque partenaire du mur utilise notamment :

``` text
.sponsor-logo-card
.logo-box
```

Les logos sont rangés dans :

``` text
images/sponsors/
```

## Autres composants partenaires

Classes observées :

``` text
.sponsor-card
.sponsor-grid
.sponsor-intro
.sponsor-offer
.sponsor-top-grid
.partner-showcase-card
.partner-showcase-text
.partner-note
.wall-highlight
```

### Règle

Distinguer :

-   l'offre de partenariat ;
-   le Mur des verts et blancs ;
-   les mises en avant ponctuelles.

Ne pas fusionner ces usages automatiquement.

------------------------------------------------------------------------

# 8. Inscriptions

Classes actuellement observées :

``` text
.signup-section
.signup-intro
.signup-cards
.signup-card
.signup-icon
.signup-note
```

### État

Le composant existe mais la page Inscriptions est identifiée comme un
chantier d'évolution.

### Attention

La présence actuelle d'icônes de type emoji dans cette page ne constitue
pas une règle du Design System. Les consignes du projet prévoient de ne
pas utiliser d'emojis dans l'interface sauf demande explicite.

------------------------------------------------------------------------

# 9. Formulaires

Classes observées :

``` text
.formbox
.formgrid
.field
.full
```

Éléments utilisés :

``` text
label
input
select
textarea
```

### Règle

Pour tout nouveau formulaire :

-   réutiliser les styles existants ;
-   associer correctement les labels aux champs lors des évolutions ;
-   vérifier clavier, focus et mobile ;
-   ne jamais demander ou exposer inutilement des données personnelles.

------------------------------------------------------------------------

# 10. Tableaux

Classes observées :

``` text
.table-wrap
.schedule-table
```

### Usage

Notamment adapté aux plannings et données structurées.

### Règle

Toujours vérifier le comportement mobile d'un tableau avant livraison.

------------------------------------------------------------------------

# 11. Encadrés et messages

Classes observées :

``` text
.notice
.notice-green
.notice-duplicate
.help
.status
.badge
.pill
.pill-list
```

### Fonction

Informations, statuts, aides à la lecture et petits éléments de
catégorisation.

### Règle

Ne pas multiplier les couleurs de statut sans logique définie.

------------------------------------------------------------------------

# 12. Actualités / listes éditoriales

Classes observées :

``` text
.news-card
.news-list
```

Utilisées notamment sur l'accueil pour les essais, réinscriptions et
informations du club.

------------------------------------------------------------------------

# 13. Footer

Classes principales :

``` text
.site-footer
.container
.footer-grid
.footer-brand-block
.footer-logo
.footer-bottom
.legal-link
```

### Fonction

-   identité du club ;
-   navigation secondaire ;
-   contact ;
-   partenaires ;
-   mentions légales et informations institutionnelles.

### Règle

Le footer étant répété dans plusieurs pages, une modification doit être
appliquée de manière cohérente à toutes les pages publiques concernées.

------------------------------------------------------------------------

# 14. Page 404

Composants spécifiques observés :

``` text
.notfound
.notfound-card
.ball-404
.court-404
```

La page utilise l'univers basket et le message « La page est hors jeu ».

Ce composant peut rester spécifique à la page 404.

------------------------------------------------------------------------

# 15. Composants de l'espace `app/`

L'espace application possède de nombreux composants spécifiques,
notamment :

``` text
.shell
.page
.panel
.welcome-card
.role-menu
.tools
.summary-row
.player-list
.comm-list
.comm-dot
.notif-dot
.device-mockup
.device-screen
.device-topbar
```

### Règle

Les composants `app/` ne doivent pas être mélangés automatiquement avec
ceux du site public.

Le Design System pourra définir des éléments communs, mais les deux
espaces répondent à des usages différents.

------------------------------------------------------------------------

# 16. Composants graphiques décoratifs

Le CSS contient plusieurs éléments liés à l'univers basket ou à des
décorations :

``` text
.basketball-bg
.bg-ball
.decor-ball
.fake-ball
.floating-ball
.header-ball
.hero-ball
.hero-orbit
.page-ball
```

### Règle

Ne pas ajouter de nouveaux éléments décoratifs avant d'avoir vérifié
ceux qui existent déjà.

------------------------------------------------------------------------

# 17. Inventaire synthétique

``` text
STRUCTURE
├── Header
├── Navigation
├── Bandeau partenaires
├── Conteneurs / grilles
└── Footer

ÉDITORIAL
├── Eyebrow
├── Titres
├── Lead
├── Hero
└── Actualités

ACTIONS
├── Bouton principal
├── Bouton secondaire
└── Bouton orange

CONTENU
├── Carte générique
├── Carte équipe
├── Carte partenaire
├── Carte inscription
├── Encadré
├── Badge / pill
├── Tableau
└── Formulaire

SPÉCIFIQUE
├── Page 404
└── Interfaces app/
```

------------------------------------------------------------------------

# 18. Règle pour Claude / OpenAI

Avant de créer un composant :

1.  rechercher son équivalent dans ce document ;
2.  rechercher les classes existantes dans `style.css` ;
3.  rechercher leurs usages dans les fichiers HTML ;
4.  déterminer si la demande nécessite réellement un nouveau composant ;
5.  si oui, proposer son ajout au Design System lorsqu'il est destiné à
    être réutilisé.

> **Un composant existant peut être amélioré. Il ne doit pas être
> dupliqué uniquement pour éviter de comprendre son fonctionnement.**
