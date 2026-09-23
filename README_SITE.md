# README_SITE.md --- ES Blanquefort Basket

> **Guide technique et pratique du site**
>
> Ce document explique comment est organisé, modifié, testé et livré le
> site de l'ES Blanquefort Basket.
>
> Il complète :
>
> -   `AGENTS.md` : règles obligatoires pour toute intervention ;
> -   `ARBORESCENCE_SITE.md` : architecture fonctionnelle validée et
>     rôle des pages.
>
> Avant toute modification, lire ces trois documents.

------------------------------------------------------------------------

# 1. Présentation du projet

Le site de l'ES Blanquefort Basket est un site statique construit
principalement avec :

-   HTML ;
-   CSS ;
-   JavaScript natif.

Il est destiné à être hébergé sur Hostinger.

Le projet comporte deux espaces :

1.  **le site public**, accessible à tous ;
2.  **le dossier `app/`**, qui regroupe des interfaces distinctes
    destinées aux licenciés, coachs et dirigeants.

Le choix technique actuel est volontairement simple. Il facilite :

-   la maintenance ;
-   les sauvegardes ;
-   les modifications ciblées ;
-   l'intervention d'un agent IA ;
-   l'hébergement sans CMS ;
-   la maîtrise des fichiers par le club.

Ne pas remplacer cette architecture par un framework ou un CMS sans
décision explicite du club.

------------------------------------------------------------------------

# 2. Documents à lire avant toute intervention

À la racine du projet doivent se trouver :

``` text
README_SITE.md
ARBORESCENCE_SITE.md
AGENTS.md
```

## Ordre de lecture recommandé

### `AGENTS.md`

Définit les règles d'intervention.

Il précise notamment :

-   ce qu'un agent peut modifier ;
-   ce qu'il ne doit jamais décider seul ;
-   les règles relatives aux données ;
-   les contrôles à effectuer ;
-   les conditions de mise en production.

### `ARBORESCENCE_SITE.md`

Définit :

-   les pages validées ;
-   leur rôle ;
-   la navigation ;
-   la séparation entre le site public et l'application.

### `README_SITE.md`

Le présent document.

Il explique :

-   où se trouvent les fichiers ;
-   comment travailler ;
-   comment tester ;
-   comment préparer une livraison ;
-   comment déployer sur Hostinger ;
-   comment revenir à une version précédente.

------------------------------------------------------------------------

# 3. Structure actuelle du projet

``` text
public_html/
│
├── index.html
├── le-club.html
├── equipes.html
├── planning.html
├── calendrier.html
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
├── calendrier.js
│
├── images/
│   ├── logo.png
│   ├── favicon.png
│   ├── hero-basket-bg.png
│   ├── equipe-club.jpg
│   ├── icon-192.png
│   ├── icon-512.png
│   └── sponsors/
│       └── logos des partenaires
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

Un fichier historique de consignes de déploiement peut également être
présent :

``` text
README_DEPLOIEMENT_ESBB.txt
```

Il peut servir de référence historique, mais les règles actuelles du
projet doivent être centralisées dans les trois fichiers Markdown de
gouvernance.

------------------------------------------------------------------------

# 4. Pages du site public

  Fichier                        Fonction principale
  ------------------------------ ----------------------------------------
  `index.html`                   Accueil et orientation générale
  `le-club.html`                 Présentation du club et de ses valeurs
  `equipes.html`                 Présentation des équipes et catégories
  `planning.html`                Horaires, salles et entraînements
  `calendrier.html`              Calendrier dynamique du club
  `matchs.html`                  Redirection vers `calendrier.html`
  `partenaires.html`             Offre et démarche de partenariat
  `sponsors.html`                Présentation des partenaires existants
  `inscriptions.html`            Parcours inscriptions / licences
  `essais.html`                  Parcours et actions liés aux essais
  `contact.html`                 Coordonnées et contact
  `mentions_legales_ESBB.html`   Informations réglementaires
  `404.html`                     Page d'erreur personnalisée

Pour le détail fonctionnel et les règles d'arborescence, consulter
`ARBORESCENCE_SITE.md`.

------------------------------------------------------------------------

# 5. Navigation principale

La navigation de référence est :

``` text
Accueil
Le club
Équipes
Planning
Calendrier
Partenaires
S’inscrire
```

Ne pas modifier cette architecture sans demande explicite.

Une évolution graphique du menu peut être étudiée sans changer les
rubriques.

------------------------------------------------------------------------

# 6. Fichiers communs

## `style.css`

Feuille de styles principale du site public.

Elle contient notamment les règles relatives :

-   aux couleurs ;
-   aux typographies ;
-   au header ;
-   à la navigation ;
-   aux boutons ;
-   aux cartes ;
-   aux sections hero ;
-   aux formulaires ;
-   aux tableaux ;
-   aux partenaires ;
-   au footer ;
-   au responsive ;
-   aux animations et ajustements accumulés au cours du développement.

### Avant toute modification

Rechercher d'abord si une classe ou un composant existe déjà.

Ne pas ajouter automatiquement :

-   une nouvelle feuille CSS ;
-   des styles inline ;
-   une nouvelle variante de composant ;
-   une série de correctifs globaux en fin de fichier.

Toute évolution graphique importante devra progressivement suivre le
Design System ES Blanquefort Basket.

------------------------------------------------------------------------

## `script.js`

JavaScript commun du site public.

Le site utilise volontairement peu de JavaScript.

Les fonctions communes identifiées comprennent notamment :

-   le menu mobile ;
-   les animations d'apparition ;
-   les compteurs animés.

Avant d'ajouter un script, vérifier si le comportement peut être ajouté
proprement à `script.js`.

Ne pas introduire de framework pour une fonction simple.

## `calendrier.js`

Script dédié au calendrier public. Il charge les rencontres depuis la
vue Supabase `public.public_calendar` avec la clé publishable et assure la
navigation mensuelle, le rendu responsive et l'affichage des détails.

------------------------------------------------------------------------

# 7. Ressources graphiques

Deux dossiers existent actuellement :

``` text
images/
assets/
```

## `images/`

Contient notamment les ressources utilisées par le site public :

-   logo ;
-   favicon ;
-   visuels ;
-   logos partenaires.

Les logos partenaires sont regroupés dans :

``` text
images/sponsors/
```

## `assets/`

Contient notamment des ressources utilisées par certaines interfaces du
dossier `app/`.

### Attention

Des ressources similaires ou dupliquées peuvent actuellement exister
dans `images/` et `assets/`.

Ne pas les supprimer ou les fusionner automatiquement.

Avant toute réorganisation :

1.  rechercher toutes leurs références dans les fichiers HTML/CSS/JS ;
2.  vérifier leur utilisation réelle ;
3.  modifier tous les chemins concernés ;
4.  tester le site public et le dossier `app/`.

------------------------------------------------------------------------

# 8. Polices

Le site actuel charge des polices Google Fonts, notamment :

-   Bebas Neue ;
-   Barlow ;
-   Barlow Condensed.

Ne pas remplacer les typographies du site sans décision prise dans le
cadre du Design System.

Lors d'une évolution du Design System, documenter les polices retenues
et leurs usages avant de les déployer sur toutes les pages.

------------------------------------------------------------------------

# 9. Liens externes

Le site contient actuellement des liens vers différents services ou
sites externes.

Ils peuvent notamment concerner :

-   essais ;
-   réinscriptions ;
-   partenariat ;
-   sites de partenaires ;
-   réseaux ou profils professionnels ;
-   adresses e-mail.

Certains parcours utilisent actuellement GitHub Pages.

### Règle

Ne jamais inventer ou déduire une nouvelle URL.

Avant de remplacer un lien :

1.  disposer de la destination validée ;
2.  vérifier que le nouveau lien fonctionne ;
3.  identifier les pages utilisant l'ancien lien ;
4.  modifier uniquement les références concernées.

Les liens HelloAsso et autres liens saisonniers doivent être traités
comme des **données variables**.

------------------------------------------------------------------------

# 10. Données variables

Certaines informations changent régulièrement.

Exemples :

-   saison sportive ;
-   catégories réellement engagées ;
-   horaires ;
-   salles ;
-   dates ;
-   matchs ;
-   résultats ;
-   tarifs ;
-   liens d'inscription ;
-   liens HelloAsso ;
-   partenaires ;
-   coordonnées ;
-   informations d'essais.

Ces données ne doivent jamais être déduites d'une saison précédente sans
validation.

Si une donnée manque :

``` text
[À COMPLÉTER]
```

------------------------------------------------------------------------

# 11. Méthode de travail recommandée

## Étape 1 --- Comprendre la demande

Identifier précisément :

-   la page concernée ;
-   le contenu à modifier ;
-   le type de changement ;
-   les fichiers potentiellement impactés.

Classer la demande :

``` text
CONTENU
DESIGN
FONCTIONNALITÉ
STRUCTURE
```

------------------------------------------------------------------------

## Étape 2 --- Lire les fichiers concernés

Ne pas modifier un fichier avant d'avoir examiné :

-   sa structure ;
-   ses classes CSS ;
-   ses scripts ;
-   les liens avec les autres fichiers.

Pour une modification de composant partagé, rechercher toutes les
utilisations du composant avant de modifier sa règle CSS.

------------------------------------------------------------------------

## Étape 3 --- Faire une copie de travail

Ne pas travailler directement sur l'unique copie du site en production.

Conserver une version intacte de référence.

Exemple de logique :

``` text
site-production/
site-travail/
```

ou utiliser un dépôt Git avec une branche de travail.

------------------------------------------------------------------------

## Étape 4 --- Modifier le minimum nécessaire

Une demande ciblée doit produire une modification ciblée.

Exemple :

> « Modifier les horaires U15 »

doit conduire à modifier les horaires concernés.

Elle ne doit pas conduire à :

-   refaire la page Planning ;
-   modifier le menu ;
-   changer les couleurs ;
-   réécrire le CSS général.

------------------------------------------------------------------------

## Étape 5 --- Tester

Tester les fichiers concernés avant livraison.

------------------------------------------------------------------------

## Étape 6 --- Fournir un compte rendu

Respecter le format défini dans `AGENTS.md`.

------------------------------------------------------------------------

# 12. Test local simple

Comme le site est statique, plusieurs méthodes sont possibles.

## Méthode minimale

Ouvrir directement le fichier HTML dans un navigateur.

Cette méthode suffit pour certains contrôles visuels simples.

Cependant, certains comportements ou chemins peuvent se comporter
différemment lorsqu'un site est servi par HTTP.

## Méthode recommandée

Depuis le dossier racine du site, lancer un petit serveur local.

Avec Python installé :

``` bash
python -m http.server 8000
```

Puis ouvrir dans le navigateur :

``` text
http://localhost:8000/
```

Arrêter le serveur avec :

``` text
Ctrl+C
```

Cette méthode permet de tester le site dans des conditions plus proches
d'un hébergement web.

------------------------------------------------------------------------

# 13. Contrôles à effectuer après modification

## Navigation

Vérifier :

-   le menu principal ;
-   le menu mobile ;
-   les liens vers les autres pages ;
-   le retour à l'accueil ;
-   les liens externes modifiés.

## Affichage

Tester au minimum :

-   ordinateur ;
-   largeur tablette ;
-   téléphone.

Vérifier notamment :

-   absence de défilement horizontal involontaire ;
-   cartes correctement dimensionnées ;
-   textes non coupés ;
-   boutons utilisables ;
-   images non déformées ;
-   tableaux exploitables ;
-   formulaires lisibles.

## Technique

Vérifier :

-   absence d'erreur évidente dans la console navigateur ;
-   absence de fichier manquant ;
-   chemins d'images valides ;
-   CSS chargé ;
-   JavaScript chargé ;
-   page 404 préservée.

## Contenu

Vérifier :

-   orthographe « ES Blanquefort Basket » ;
-   données validées ;
-   aucune donnée personnelle exposée ;
-   aucun `[À COMPLÉTER]` oublié sur une page destinée à la production.

------------------------------------------------------------------------

# 14. Vérification des liens internes

Après une modification importante, contrôler les liens relatifs.

Exemples :

``` html
<a href="equipes.html">
<a href="planning.html">
<a href="inscriptions.html">
```

Dans le dossier `app/`, tenir compte du niveau de répertoire :

``` html
<img src="../assets/logo.png">
```

Ne pas transformer arbitrairement les chemins relatifs en chemins
absolus.

------------------------------------------------------------------------

# 15. Ajout d'une nouvelle page

Une nouvelle page ne doit être créée que si son existence est validée.

Lorsqu'elle est validée :

1.  choisir un nom de fichier simple et durable ;
2.  reprendre la structure commune du site ;
3.  réutiliser header, navigation et footer ;
4.  utiliser `style.css` ;
5.  utiliser `script.js` si nécessaire ;
6.  intégrer les composants du Design System ;
7.  vérifier mobile et ordinateur ;
8.  décider explicitement si la page doit apparaître dans le menu ;
9.  mettre à jour `ARBORESCENCE_SITE.md` si elle modifie l'architecture
    officielle.

Ne pas créer une page séparée lorsqu'une section dans une page existante
suffit, sauf demande explicite.

------------------------------------------------------------------------

# 16. Modification du Design System

Le Design System est un chantier distinct de l'arborescence.

Il pourra faire évoluer progressivement :

-   boutons ;
-   cartes ;
-   navigation visuelle ;
-   typographies ;
-   titres ;
-   formulaires ;
-   tableaux ;
-   blocs partenaires ;
-   composants Match ;
-   composants Équipe ;
-   composants utilisés sur les supports de communication.

Une évolution du Design System ne signifie pas automatiquement que
toutes les pages doivent être réécrites dans la même intervention.

La modernisation doit pouvoir être progressive.

------------------------------------------------------------------------

# 17. Site public et application

Le dossier `app/` ne doit pas être traité comme une simple sous-page du
site public.

Il répond à des usages distincts.

Avant de modifier un fichier sous `app/`, identifier le public :

``` text
licencies.html → licenciés / familles
coachs.html    → entraîneurs
bureau.html    → bureau / dirigeants
```

Les données internes ne doivent pas être copiées vers le site public.

Inversement, les informations publiques essentielles doivent rester
accessibles sur le site sans nécessiter l'application.

------------------------------------------------------------------------

# 18. Préparation d'une livraison

Avant de transmettre une version au club :

1.  conserver la structure de dossiers ;
2.  ne pas inclure de fichiers temporaires inutiles ;
3.  vérifier tous les fichiers modifiés ;
4.  indiquer clairement les fichiers concernés ;
5.  préciser les éventuels points restant à valider.

Pour une livraison complète, préparer de préférence une archive :

``` text
public_html.zip
```

contenant directement les fichiers et dossiers destinés à la racine web.

### Attention

Éviter une archive structurée ainsi :

``` text
public_html.zip
└── public_html/
    └── index.html
```

si le but est d'extraire directement son contenu dans le `public_html`
existant.

La structure de l'archive doit être vérifiée avant déploiement.

------------------------------------------------------------------------

# 19. Déploiement Hostinger

Le site est destiné au dossier web du domaine dans Hostinger,
généralement :

``` text
public_html/
```

## Pour une modification ciblée

Privilégier le remplacement des seuls fichiers concernés.

Exemple :

``` text
planning.html
style.css
```

si ce sont réellement les deux seuls fichiers modifiés.

## Pour une mise à jour complète

Avant remplacement :

1.  sauvegarder la version actuellement en ligne ;
2.  conserver cette sauvegarde en dehors du dossier de production ;
3.  téléverser ou extraire la nouvelle version ;
4.  vérifier immédiatement le site public ;
5.  contrôler plusieurs pages ;
6.  vérifier le mobile ;
7.  vérifier les chemins de ressources.

Ne pas supprimer l'ancienne version avant d'avoir une sauvegarde
exploitable.

------------------------------------------------------------------------

# 20. Sauvegarde avant production

Créer une sauvegarde identifiable.

Exemple :

``` text
backup_site_2026-08-11/
```

ou :

``` text
public_html_backup_2026-08-11.zip
```

La date doit correspondre au jour réel de la sauvegarde.

Ne pas inventer une date dans une procédure automatisée : utiliser la
date d'exécution.

Pour une modification importante, conserver au minimum :

-   les fichiers remplacés ;
-   ou une archive complète de la version précédente.

------------------------------------------------------------------------

# 21. Retour arrière

Si une mise à jour provoque un problème :

## Modification ciblée

Restaurer les fichiers sauvegardés correspondant à l'intervention.

## Mise à jour complète

Restaurer la dernière archive complète validée.

Après restauration :

1.  recharger le site sans cache si nécessaire ;
2.  vérifier l'accueil ;
3.  vérifier le menu ;
4.  vérifier les pages concernées ;
5.  vérifier les ressources ;
6.  documenter l'incident avant une nouvelle tentative.

------------------------------------------------------------------------

# 22. Git et agents IA

L'utilisation de Git est recommandée pour permettre à Claude, OpenAI ou
un développeur de suivre précisément les modifications.

Une organisation simple peut être :

``` text
main
└── version validée

branche de travail
└── modifications en cours
```

Avant livraison, examiner les différences entre la version validée et la
version modifiée.

Un agent doit pouvoir expliquer :

-   quels fichiers ont changé ;
-   pourquoi ;
-   quelles lignes fonctionnelles ont été touchées ;
-   quels tests ont été réalisés.

Git est recommandé mais ne doit pas devenir une condition bloquante pour
une petite mise à jour Hostinger si le club utilise une autre méthode de
sauvegarde fiable.

------------------------------------------------------------------------

# 23. Fichiers à ne pas laisser dans la version publique

Ne pas téléverser inutilement dans le dossier public :

-   sauvegardes ZIP ;
-   fichiers temporaires ;
-   captures de test ;
-   brouillons ;
-   notes internes ;
-   exports contenant des données personnelles ;
-   identifiants ;
-   secrets ;
-   fichiers de configuration privés.

Les fichiers de documentation du projet peuvent être conservés dans le
dépôt de travail. Leur publication dans `public_html` doit être décidée
séparément.

------------------------------------------------------------------------

# 24. Sécurité

Ne jamais inscrire directement dans les fichiers publics :

-   mots de passe ;
-   clés API privées ;
-   jetons d'accès ;
-   identifiants Hostinger ;
-   identifiants administrateurs ;
-   données personnelles internes.

Si une future fonctionnalité nécessite un secret côté serveur, le site
statique devra être complété par une architecture adaptée. Ne jamais
contourner cette contrainte en plaçant le secret dans JavaScript côté
navigateur.

------------------------------------------------------------------------

# 25. Procédure type pour une demande

Exemple :

> « Ajoute le nouveau partenaire X sur la page sponsors. »

Procédure attendue :

``` text
1. Lire AGENTS.md.
2. Vérifier le rôle de sponsors.html dans ARBORESCENCE_SITE.md.
3. Examiner sponsors.html et les composants partenaires dans style.css.
4. Vérifier que le logo et les informations du partenaire ont été fournis.
5. Ajouter le partenaire en réutilisant le composant existant.
6. Ajouter son image dans images/sponsors/ si nécessaire.
7. Tester ordinateur et mobile.
8. Vérifier le lien du partenaire.
9. Livrer uniquement les fichiers concernés.
10. Fournir le compte rendu.
```

Ne pas profiter de cette demande pour refaire la page Partenaires ou
modifier l'accueil sans demande complémentaire.

------------------------------------------------------------------------

# 26. État des chantiers

## Architecture générale

**Validée.**

Ne pas refaire l'arborescence sans demande explicite.

## Design System

**En cours de construction.**

Il doit progressivement devenir la référence visuelle commune au site et
aux autres supports du club.

## Page Inscriptions

**Évolution prévue.**

Elle doit devenir un point central du parcours licencié sans provoquer
une refonte globale du site.

## Guide des licenciés

**Prévu.**

Il doit pouvoir être intégré au site et rester cohérent avec le Design
System.

## Guide de l'application

**Prévu ultérieurement.**

Il devra pouvoir être intégré au parcours numérique du club.

## Modernisation générale

Elle doit être **progressive** et réalisée par composants ou pages
validés, sans repartir systématiquement de zéro.

------------------------------------------------------------------------

# 27. Compte rendu de livraison

Après toute intervention, utiliser :

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

Si une information n'a pas pu être vérifiée :

``` text
POINTS À VALIDER
- [élément précis]
```

------------------------------------------------------------------------

# 28. Résumé opérationnel

Avant de toucher au site :

``` text
LIRE
↓
AGENTS.md
ARBORESCENCE_SITE.md
README_SITE.md
```

Puis :

``` text
COMPRENDRE LA DEMANDE
↓
IDENTIFIER LES FICHIERS
↓
SAUVEGARDER
↓
MODIFIER LE MINIMUM NÉCESSAIRE
↓
TESTER
↓
COMPARER
↓
FAIRE VALIDER SI NÉCESSAIRE
↓
LIVRER
↓
DÉPLOYER
```

------------------------------------------------------------------------

# 29. Principe de maintenance

> **Le site ES Blanquefort Basket doit pouvoir évoluer pendant plusieurs
> saisons sans être reconstruit à chaque nouvelle demande.**

L'objectif de cette documentation est qu'un humain, Claude, OpenAI ou un
autre agent puisse reprendre le projet, comprendre immédiatement son
fonctionnement et effectuer une modification ciblée sans réinterpréter
l'ensemble du site.

Toute décision engageant l'architecture, l'identité graphique globale,
les contenus officiels ou la mise en production reste soumise à
validation humaine du club.
