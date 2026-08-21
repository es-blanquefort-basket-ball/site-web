# CONVENTIONS_SITE.md --- ES Blanquefort Basket

> **Conventions de nommage et d'organisation du projet**
>
> Ces conventions sont basées sur la structure et les usages observés
> dans le site actuel.
>
> Elles doivent guider les nouveaux fichiers et les nouvelles classes
> sans imposer une réécriture massive de l'existant.

------------------------------------------------------------------------

# 1. Principe général

Le projet existe déjà.

Les conventions suivantes s'appliquent en priorité :

-   aux nouveaux fichiers ;
-   aux nouveaux composants ;
-   aux nouveaux médias ;
-   aux évolutions réalisées progressivement.

Ne pas renommer massivement les fichiers ou classes existants uniquement
pour les rendre conformes à ce document.

------------------------------------------------------------------------

# 2. Fichiers HTML

Utiliser :

-   minuscules ;
-   mots français explicites ;
-   tirets `-` entre plusieurs mots ;
-   extension `.html`.

Exemples :

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
```

Pour un futur fichier composé de plusieurs mots :

``` text
guide-licencies.html
guide-application.html
```

Éviter :

``` text
GuideLicencies.html
guide_licencies.html
page2.html
nouveau.html
test-final-v3.html
```

------------------------------------------------------------------------

# 3. URL et stabilité des noms

Le nom d'un fichier HTML public constitue généralement une partie de son
URL.

Par conséquent :

-   ne pas renommer un fichier public existant sans validation ;
-   ne pas modifier une URL uniquement pour améliorer son nom ;
-   privilégier des noms durables pour toute nouvelle page.

------------------------------------------------------------------------

# 4. Dossiers

Utiliser des noms :

-   en minuscules ;
-   courts ;
-   explicites ;
-   sans espace ;
-   sans accent.

Exemples existants :

``` text
images/
assets/
app/
images/sponsors/
```

Pour un nouveau dossier, préférer par exemple :

``` text
images/equipes/
images/evenements/
```

plutôt que :

``` text
Images Equipes/
NOUVEAU/
Divers/
```

------------------------------------------------------------------------

# 5. Images

## Nommage

Utiliser :

-   minuscules ;
-   tirets ;
-   description explicite ;
-   pas d'espace ;
-   pas d'accent.

Exemples existants :

``` text
hero-basket-bg.png
equipe-club.jpg
isy-project-electricite.png
gm-toiture.png
```

Exemples recommandés :

``` text
equipe-u15m-2026-2027.jpg
tournoi-u11-2026.jpg
logo-partenaire-exemple.png
```

Éviter :

``` text
IMG_4587.jpg
Photo finale 2.jpg
équipe U15!!.jpg
image1.png
```

Lorsqu'une photo doit être publiée, ne pas mettre de données
personnelles dans son nom de fichier.

------------------------------------------------------------------------

# 6. Logos partenaires

Ranger les logos partenaires dans :

``` text
images/sponsors/
```

Nom recommandé :

``` text
nom-partenaire.png
```

ou :

``` text
nom-partenaire.svg
```

si ce format est validé et correctement pris en charge.

Ne pas créer un dossier différent pour chaque nouveau partenaire sans
besoin réel.

------------------------------------------------------------------------

# 7. Classes CSS

L'existant utilise principalement des classes en minuscules avec tirets.

Conserver cette logique.

Exemples :

``` text
.section-title
.btn-primary
.team-card
.sponsor-logo-card
.footer-brand-block
```

## Convention pour les nouvelles classes

Format :

``` text
bloc-element
bloc-variante
```

Exemples :

``` text
match-card
match-card-header
match-card-score
match-card-home
```

Éviter :

``` text
MatchCard
match_card
card2
nouveauStyle
vert123
```

------------------------------------------------------------------------

# 8. Classes utilitaires

Des classes utilitaires existent déjà :

``` text
.wrap
.container
.grid-2
.grid-3
.full
.soft
.dark
.light
```

Avant de créer une nouvelle classe utilitaire, vérifier si une classe
existante répond au besoin.

Ne pas multiplier les classes du type :

``` text
margin-top-17
padding-special
fix-mobile-2
```

------------------------------------------------------------------------

# 9. Variantes de composants

Une variante doit rester liée au composant principal.

Exemple existant :

``` text
.btn
.btn-primary
.btn-ghost
```

Pour un nouveau composant :

``` text
.match-card
.match-card-home
.match-card-away
```

Éviter de créer deux composants totalement indépendants lorsque seule
une variante change.

------------------------------------------------------------------------

# 10. Identifiants HTML

Les `id` doivent être réservés aux éléments qui nécessitent :

-   une ancre ;
-   une cible JavaScript ;
-   une identification réellement unique.

Utiliser des noms en minuscules avec tirets.

Exemples :

``` text
#hdr
#actualites
#newsletter
#mur
```

Pour les nouveaux identifiants, préférer un nom explicite :

``` text
#guide-licencies
```

plutôt que :

``` text
#section3
#blocX
```

------------------------------------------------------------------------

# 11. JavaScript

Les fonctions communes doivent rester dans :

``` text
script.js
```

sauf besoin technique explicitement validé.

Pour les nouveaux noms JavaScript, utiliser une convention cohérente en
`camelCase`.

Exemples :

``` text
toggleMenu()
updateCounter()
```

Éviter :

``` text
Toggle_Menu()
fonction2()
test()
```

Les constantes JavaScript réellement constantes peuvent utiliser un nom
explicite en majuscules si nécessaire.

------------------------------------------------------------------------

# 12. CSS dans les fichiers HTML

Éviter :

``` html
<div style="...">
```

et les blocs `<style>` spécifiques ajoutés page après page.

Les styles réutilisables doivent être centralisés dans `style.css`.

Exception : prototype temporaire explicitement demandé, à nettoyer avant
livraison de production.

------------------------------------------------------------------------

# 13. JavaScript inline

Éviter :

``` html
<button onclick="...">
```

Préférer des événements gérés proprement dans `script.js`.

------------------------------------------------------------------------

# 14. Texte alternatif des images

Les images informatives doivent disposer d'un `alt` utile.

Exemples :

``` html
<img src="images/logo.png" alt="Logo ES Blanquefort Basket-Ball">
```

Pour un logo partenaire :

``` html
<img src="images/sponsors/nom.png" alt="Nom du partenaire">
```

Ne pas remplir un `alt` avec une description artificiellement longue.

------------------------------------------------------------------------

# 15. Liens externes

Pour un lien externe ouvert dans un nouvel onglet :

``` html
target="_blank" rel="noopener"
```

Ne pas ajouter `target="_blank"` automatiquement à tous les liens
internes.

------------------------------------------------------------------------

# 16. Adresses e-mail

Utiliser :

``` html
mailto:adresse@domaine.fr
```

Ne jamais inventer une adresse à partir d'une adresse existante.

Toute adresse publiée doit être validée.

------------------------------------------------------------------------

# 17. Données saisonnières

Les données liées à une saison doivent être considérées comme variables.

Exemples :

``` text
2026-2027
horaires
équipes
matchs
résultats
tarifs
liens HelloAsso
partenaires
```

Ne pas encoder une nouvelle donnée saisonnière dans un nom de classe
CSS.

Mauvais :

``` text
.u15-2026-green-card
```

Bon :

``` text
.team-card
```

Le contenu porte la saison, pas le composant.

------------------------------------------------------------------------

# 18. Noms des équipes et catégories

Respecter exactement les catégories validées par le club.

Ne pas déduire automatiquement :

-   le sexe d'une équipe ;
-   son niveau ;
-   son engagement ;
-   son existence la saison suivante.

Les catégories sont des données métier, pas des conventions techniques.

------------------------------------------------------------------------

# 19. Nommage des sauvegardes

Utiliser une date ISO :

``` text
AAAA-MM-JJ
```

Exemple :

``` text
public_html_backup_2026-08-11.zip
```

Pour plusieurs sauvegardes le même jour, ajouter l'heure ou un
qualificatif explicite :

``` text
public_html_backup_2026-08-11_1500.zip
```

Ne jamais laisser une sauvegarde importante avec un nom du type :

``` text
backup-final.zip
dernier.zip
site-ok2.zip
```

------------------------------------------------------------------------

# 20. Nommage des versions de travail

Éviter les séries :

``` text
final
final2
final-vraiment
final-ok
```

Avec Git, utiliser des branches descriptives.

Exemples :

``` text
feature/guide-licencies
update/planning
design/menu-mobile
fix/liens-partenaires
```

Sans Git, utiliser un dossier ou une archive datée et descriptive.

------------------------------------------------------------------------

# 21. Fichiers temporaires

Ne pas conserver dans la version destinée à la production :

``` text
*.bak
*.tmp
captures de test
archives de sauvegarde
fichiers de travail
exports internes
```

------------------------------------------------------------------------

# 22. Documentation

Les documents de gouvernance doivent conserver ces noms :

``` text
README_SITE.md
ARBORESCENCE_SITE.md
AGENTS.md
COMPOSANTS_SITE.md
CONVENTIONS_SITE.md
```

Ne pas créer des variantes concurrentes du type :

``` text
AGENTS_V2.md
README_NEW.md
CONSIGNES_CLAUDE_FINAL.md
```

Une évolution doit mettre à jour le document de référence existant.

------------------------------------------------------------------------

# 23. Commentaires dans le code

Ajouter des commentaires uniquement lorsqu'ils apportent une information
utile.

Bon exemple :

``` css
/* Navigation mobile */
```

Éviter les commentaires de version empilés :

``` css
/* FIX V4 */
/* NOUVEAU FIX */
/* FIX FINAL */
/* CORRECTION DEFINITIVE */
```

Lorsqu'un correctif devient permanent, intégrer proprement sa règle dans
la section logique du CSS lorsque le chantier le permet.

------------------------------------------------------------------------

# 24. Principe pour les nouvelles créations

Pour tout nouvel élément, rechercher dans cet ordre :

``` text
1. Le composant existe-t-il ?
2. Une variante existante suffit-elle ?
3. Peut-on étendre proprement le composant ?
4. Un nouveau composant est-il réellement nécessaire ?
```

Si un nouveau composant réutilisable est créé, mettre à jour :

``` text
COMPOSANTS_SITE.md
```

Si une nouvelle règle structurelle ou de nommage apparaît, mettre à jour
:

``` text
CONVENTIONS_SITE.md
```

------------------------------------------------------------------------

# 25. Principe final

> **Les conventions servent à rendre le site prévisible pour les humains
> et les agents IA, pas à provoquer une réécriture de l'existant.**

La priorité reste :

-   stabilité ;
-   lisibilité ;
-   cohérence ;
-   maintenance simple ;
-   modifications ciblées ;
-   respect du Design System et de l'arborescence validée.
