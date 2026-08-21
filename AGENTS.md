# AGENTS.md --- ES Blanquefort Basket

> **Instructions obligatoires pour tout agent IA intervenant sur le
> site**
>
> Ce fichier s'applique à Claude, OpenAI et à tout autre agent
> automatisé travaillant dans le dépôt du site ES Blanquefort Basket.
>
> Avant toute modification, lire :
>
> 1.  `AGENTS.md`
> 2.  `ARBORESCENCE_SITE.md`
> 3.  `README_SITE.md` lorsqu'il existe
>
> **Principe fondamental : modifier uniquement ce qui est demandé.**
>
> Une demande locale ne doit jamais devenir une refonte générale du
> site.

------------------------------------------------------------------------

# 1. Contexte du projet

Le site de l'ES Blanquefort Basket est un site associatif public en
HTML, CSS et JavaScript, hébergé sur Hostinger.

Le projet comprend :

-   un site public ;
-   un espace `app/` distinct ;
-   une feuille de styles principale ;
-   un JavaScript commun volontairement léger ;
-   des ressources graphiques ;
-   des liens ou services externes selon les besoins.

Le site doit rester :

-   simple à maintenir ;
-   rapide ;
-   lisible ;
-   responsive ;
-   accessible au public sans application ;
-   cohérent avec le Design System ES Blanquefort Basket.

------------------------------------------------------------------------

# 2. Source de vérité

L'arborescence fonctionnelle et le rôle des pages sont définis dans :

``` text
ARBORESCENCE_SITE.md
```

Ce document fait autorité pour toute décision concernant :

-   les pages existantes ;
-   leur rôle ;
-   la navigation ;
-   la séparation entre site public et application.

En cas de contradiction entre une suggestion technique et
`ARBORESCENCE_SITE.md`, ne pas modifier l'architecture sans validation
humaine explicite.

------------------------------------------------------------------------

# 3. Règle de périmètre

Avant de modifier un fichier, déterminer le type de demande.

## A. Contenu

Exemples :

-   changer un horaire ;
-   corriger un texte ;
-   remplacer un lien ;
-   mettre à jour une équipe ;
-   ajouter un partenaire.

Dans ce cas :

**modifier le contenu demandé uniquement.**

Ne pas profiter de l'intervention pour :

-   refaire la page ;
-   modifier le menu ;
-   changer les composants ;
-   nettoyer massivement le CSS ;
-   déplacer d'autres contenus.

------------------------------------------------------------------------

## B. Design

Exemples :

-   modifier une carte ;
-   faire évoluer un bouton ;
-   adapter le menu visuellement ;
-   appliquer un composant du Design System.

Dans ce cas :

**modifier la présentation demandée sans réécrire le contenu métier ni
l'arborescence.**

------------------------------------------------------------------------

## C. Fonctionnalité

Exemples :

-   ajouter un accordéon FAQ ;
-   ajouter un formulaire ;
-   intégrer un widget ;
-   ajouter un comportement JavaScript.

Dans ce cas :

-   limiter le JavaScript au besoin réel ;
-   préserver les fonctions existantes ;
-   prévoir le fonctionnement mobile ;
-   éviter toute dépendance externe inutile.

------------------------------------------------------------------------

## D. Structure

Exemples :

-   ajouter une page ;
-   modifier la navigation ;
-   déplacer une rubrique ;
-   fusionner des pages.

Ces changements nécessitent une demande ou une validation explicite du
club.

------------------------------------------------------------------------

# 4. Interdictions absolues

Sans demande explicite, ne jamais :

-   refaire entièrement le site ;
-   modifier son architecture générale ;
-   supprimer une page ;
-   fusionner deux pages ;
-   renommer une URL existante ;
-   transformer le projet en React, Vue, Angular ou autre framework ;
-   installer un CMS ;
-   remplacer le fonctionnement HTML/CSS/JS existant ;
-   créer une nouvelle identité graphique ;
-   remplacer le Design System validé ;
-   déplacer une information publique essentielle exclusivement dans
    l'application ;
-   publier directement en production ;
-   modifier les mentions légales sur la base d'une supposition ;
-   inventer une donnée manquante.

------------------------------------------------------------------------

# 5. Données : ne jamais inventer

Ne jamais inventer notamment :

-   nom d'une personne ;
-   adresse e-mail ;
-   numéro de téléphone ;
-   équipe ;
-   catégorie ;
-   année de naissance ;
-   horaire ;
-   salle ;
-   date ;
-   résultat ;
-   tarif ;
-   partenaire ;
-   sponsor ;
-   lien HelloAsso ;
-   règle FFBB ;
-   procédure administrative ;
-   décision du club.

Si une information nécessaire manque :

``` text
[À COMPLÉTER]
```

ou signaler clairement le point à faire valider.

------------------------------------------------------------------------

# 6. Protection des données

Le site concerne notamment des licenciés mineurs.

Ne jamais publier ou exposer sans validation explicite :

-   date de naissance complète d'un mineur ;
-   coordonnées personnelles ;
-   adresse personnelle ;
-   données médicales ;
-   documents de licence ;
-   informations familiales ;
-   listes internes de licenciés ;
-   informations issues de l'espace bureau ;
-   identifiants ou secrets techniques.

Ne jamais copier une donnée privée de l'application vers le site public
simplement parce qu'elle est techniquement accessible.

------------------------------------------------------------------------

# 7. Architecture de référence

Le site public utilise notamment :

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
style.css
script.js
```

L'espace application est distinct :

``` text
app/
├── licencies.html
├── coachs.html
├── bureau.html
├── essais.html
└── mentions_legales_ESBB.html
```

Consulter `ARBORESCENCE_SITE.md` pour le rôle détaillé de chaque
élément.

------------------------------------------------------------------------

# 8. HTML

Lors d'une modification HTML :

-   conserver une structure sémantique ;
-   conserver les éléments d'accessibilité existants ;
-   utiliser les composants déjà disponibles ;
-   éviter les styles inline ;
-   éviter le JavaScript inline ;
-   conserver des liens relatifs cohérents ;
-   vérifier les chemins des images ;
-   ne pas dupliquer inutilement du contenu commun.

Les titres doivent conserver une hiérarchie logique :

``` text
h1
  h2
    h3
```

Ne pas utiliser un niveau de titre uniquement pour obtenir une taille
visuelle.

------------------------------------------------------------------------

# 9. CSS

La feuille principale est :

``` text
style.css
```

Avant d'ajouter une règle :

1.  rechercher le composant ou la classe existante ;
2.  vérifier si le Design System prévoit déjà la solution ;
3.  réutiliser les variables ou styles communs ;
4.  mesurer l'impact sur les autres pages.

Éviter :

-   les duplications ;
-   les correctifs globaux ajoutés en fin de fichier sans analyse ;
-   les `!important` sauf nécessité réellement justifiée ;
-   les valeurs arbitraires répétées ;
-   les styles propres à une seule page lorsqu'un composant commun
    convient.

Ne pas effectuer un « grand nettoyage CSS » pendant une demande sans
rapport.

------------------------------------------------------------------------

# 10. JavaScript

Le site doit conserver un JavaScript léger.

Avant d'ajouter du code :

-   vérifier si la fonction existe déjà dans `script.js` ;
-   privilégier JavaScript natif ;
-   ne pas ajouter de framework pour une interaction simple ;
-   ne pas casser le menu mobile ;
-   ne pas casser les animations existantes ;
-   prévoir l'absence de JavaScript lorsque cela est raisonnablement
    possible.

Ne jamais ajouter une bibliothèque externe uniquement pour obtenir un
effet visuel mineur.

------------------------------------------------------------------------

# 11. Design System

Le Design System ES Blanquefort Basket est la référence visuelle du
projet.

Lorsqu'un composant a été validé, le réutiliser.

Exemples :

-   boutons ;
-   cartes ;
-   titres ;
-   formulaires ;
-   tableaux ;
-   encadrés ;
-   navigation ;
-   partenaires ;
-   composants Match ;
-   composants Équipe.

Ne pas créer une variante supplémentaire uniquement parce qu'elle paraît
« plus moderne ».

Si le Design System ne couvre pas un besoin :

1.  signaler le besoin ;
2.  proposer une extension ;
3.  attendre validation lorsqu'elle modifie l'identité globale ;
4.  seulement ensuite créer le nouveau composant.

------------------------------------------------------------------------

# 12. Règles éditoriales

Le ton du site doit être :

-   direct ;
-   professionnel ;
-   humain ;
-   associatif ;
-   accessible aux familles et licenciés.

Privilégier les verbes d'action.

Exemples :

``` text
Essayer
Se préinscrire
Renouveler
Régler
Préparer ses documents
Utiliser une aide
Consulter le planning
Découvrir les équipes
```

Éviter les formulations inutilement longues du type :

``` text
Je souhaite...
Je voudrais...
Cliquez ici pour...
```

Ne pas utiliser d'emojis dans l'interface sauf demande explicite.

------------------------------------------------------------------------

# 13. Site public et application

Le site public et l'application sont complémentaires.

## Site public

Il sert notamment à :

-   informer ;
-   présenter le club ;
-   afficher les équipes ;
-   afficher les horaires ;
-   présenter les matchs ;
-   présenter les partenaires ;
-   expliquer les inscriptions ;
-   permettre la prise de contact.

## Application

Elle sert aux usages personnalisés ou internes :

-   licenciés / familles ;
-   coachs ;
-   bureau.

Une information publique essentielle ne doit pas disparaître du site au
motif qu'elle existe dans l'application.

------------------------------------------------------------------------

# 14. Pages Inscriptions et Essais

Ces deux pages ont des fonctions différentes.

## `inscriptions.html`

Explique et oriente le parcours :

-   Essayer
-   Se préinscrire
-   Renouveler
-   Régler
-   Documents
-   Aides
-   Assurances
-   Guide licencié
-   Guide application
-   FAQ

## `essais.html`

Permet d'effectuer les actions liées aux essais et d'accéder aux
créneaux correspondants.

Ne pas fusionner automatiquement ces pages.

------------------------------------------------------------------------

# 15. Liens et services externes

Avant de modifier un lien externe :

-   vérifier la destination ;
-   ne jamais fabriquer une URL ;
-   conserver l'ancien lien si le nouveau n'est pas confirmé ;
-   signaler les liens devenus invalides.

Cela concerne notamment :

-   HelloAsso ;
-   GitHub Pages ;
-   formulaires ;
-   outils partenaires ;
-   services externes du club.

------------------------------------------------------------------------

# 16. Responsive

Toute modification visuelle doit être vérifiée au minimum sur :

-   écran ordinateur ;
-   tablette ou largeur intermédiaire ;
-   téléphone.

Points à contrôler :

-   menu ;
-   largeur des contenus ;
-   boutons ;
-   tableaux ;
-   formulaires ;
-   images ;
-   cartes ;
-   textes longs ;
-   absence de défilement horizontal involontaire.

Une modification n'est pas considérée comme terminée si elle fonctionne
uniquement sur ordinateur.

------------------------------------------------------------------------

# 17. Accessibilité

Préserver ou améliorer :

-   contrastes ;
-   textes alternatifs des images utiles ;
-   labels de formulaires ;
-   navigation clavier ;
-   visibilité du focus ;
-   structure des titres ;
-   textes compréhensibles hors contexte ;
-   boutons et liens suffisamment explicites.

Ne pas remplacer un texte utile par une icône seule si son sens devient
ambigu.

------------------------------------------------------------------------

# 18. Contrôle avant livraison

Avant de considérer une modification terminée, vérifier au minimum :

### Fonctionnement

-   la page s'ouvre ;
-   les liens modifiés fonctionnent ;
-   les images s'affichent ;
-   le menu fonctionne ;
-   les interactions concernées fonctionnent.

### Présentation

-   ordinateur ;
-   mobile ;
-   cohérence avec le Design System ;
-   absence de débordement horizontal ;
-   absence de régression évidente.

### Contenu

-   aucune donnée inventée ;
-   aucune information existante supprimée involontairement ;
-   orthographe **ES Blanquefort Basket** respectée ;
-   informations sensibles non exposées.

### Périmètre

Comparer les fichiers modifiés à la demande initiale.

Si des fichiers sans rapport ont été modifiés, expliquer pourquoi ou
revenir en arrière.

------------------------------------------------------------------------

# 19. Compte rendu obligatoire de l'agent

Après une intervention, fournir un compte rendu court sous cette forme :

``` text
MODIFICATIONS EFFECTUÉES
- ...

FICHIERS MODIFIÉS
- ...

VÉRIFICATIONS EFFECTUÉES
- ...

POINTS À VALIDER
- Aucun
```

ou, lorsqu'une validation humaine est nécessaire :

``` text
POINTS À VALIDER
- [description précise]
```

Ne jamais masquer une incertitude.

------------------------------------------------------------------------

# 20. Mise en production

Par défaut, l'agent prépare les fichiers mais ne publie pas directement
sur Hostinger.

Avant une mise en production :

1.  conserver une copie de la version actuellement en ligne ;
2.  tester la version modifiée ;
3.  obtenir la validation humaine lorsque nécessaire ;
4.  seulement ensuite remplacer les fichiers concernés.

Une modification importante doit pouvoir être annulée.

------------------------------------------------------------------------

# 21. Règle de décision

En cas de doute entre :

-   une petite modification conforme à la demande ;
-   une amélioration plus ambitieuse non demandée ;

choisir **la petite modification conforme à la demande**.

Une amélioration supplémentaire peut être proposée séparément, mais elle
ne doit pas être appliquée automatiquement.

------------------------------------------------------------------------

# 22. Principe final

> **Comprendre avant de modifier.**
>
> **Réutiliser avant de créer.**
>
> **Modifier le minimum nécessaire.**
>
> **Tester avant de livrer.**
>
> **Ne jamais publier une décision à la place du club.**
