# Panneau d'options

> État : **brouillon**, rien de codé · Demandé par le user le 2026-10-08 (« il faut un panneau
> d'options, les joueurs ne vont pas faire que des commandes ; essaie de prévoir les options
> possibles de l'addon ») · Arbitrages O1 à O6 proposés par l'agent, pas tranchés
> Cible : WoW: Forever / Camelot (16001) · Addon : LeyLines · Spec voisine : `partage-direct.md`
> (D4 et D10 y renvoient)

## Le problème

Tout se règle aujourd'hui par `/ley` : une vingtaine de sous-commandes, que `/ley help` liste sur
une ligne. Un joueur qui ne lit pas la page CurseForge ne sait pas qu'il peut couper le bandeau,
changer le rappel ou n'afficher les points que sur ses Skyborne. Le 2026-10-08, un joueur demandait
sur CurseForge comment arrêter les points sur sa carte : la réponse était une commande qu'il ne
pouvait pas deviner. Et le partage en direct apporte un réglage de plus, à trois valeurs (D4 de
`partage-direct.md`), qu'une commande explique mal.

## Ce qu'on veut

Une page **« Ley Line / Elemental Convergence Tracker »** dans les options du jeu (Options →
AddOns), en quatre sections, avec chaque réglage de l'addon que le joueur peut vouloir changer. Le
texte est localisé (FR, EN, DE, ES). Chaque contrôle a une infobulle d'une ou deux phrases qui dit
ce qu'il fait.

En tête de page, une ligne dit que les réglages valent **pour tous les personnages du compte** (la
base est au compte).

Les commandes `/ley` restent toutes. Une commande et le contrôle du panneau changent le même
réglage par le même chemin : ce qu'on règle d'un côté se voit de l'autre.

`/ley options` ouvre la page. Le compartiment d'addons peut l'ouvrir aussi (O3).

### Les réglages (inventaire du code au 2026-10-08)

| Section | Contrôle | Réglage (`LeyLinesDB`) | Commande | Défaut |
|---|---|---|---|---|
| Affichage | case : points sur la minicarte | `minimap.show` | `/ley pins` | oui |
| Affichage | case : garder au bord de la minicarte les points hors de portée | `minimap.edge` | aucune | oui |
| Affichage | curseur : taille des points de la minicarte | `minimap.size` | aucune | 16 |
| Affichage | case : points sur la carte du monde | `worldmap.show` | `/ley map` | oui |
| Affichage | curseur : taille des points de la carte du monde | `worldmap.size` | aucune | 18 |
| Affichage | case : bandeau de la plus proche | `hud.show` | `/ley hud` | oui |
| Affichage | bouton : replacer le bandeau | `hud.point`, `hud.x`, `hud.y` | aucune (glisser) | centre |
| Affichage | case : points sur mes personnages Skyborne seulement | `skyborneOnly` | `/ley skyborne` | non |
| Affichage | curseur (avancé) : échelle de la minicarte | `minimap.scale` | `/ley scale` | 1,0 |
| Capture | case : capture automatique (sort, vignette) | `capture.spell`, `capture.vignette` | `/ley auto` | oui |
| Capture | case : capture par infobulle (approximative) | `capture.tooltip` | `/ley tooltip` | non |
| Capture | bouton : apprendre mon sort | — | `/ley learn` | — |
| Capture | bouton : effacer les relevés d'infobulle | — | `/ley clean` | — |
| Rappel | curseur : prévenir à N min de la fin du buff (0 = jamais) | `warnMinutes` | `/ley warn` | 5 |
| Rappel | case : poser aussi un point de route | `autoWaypoint` | `/ley waypoint` | non |
| Partage | case : signal des positions à partager | `signal` | `/ley signal` | oui |
| Partage | choix : annoncer dans General (automatique / popup / désactivé) | `announce` | `/ley announce` | à demander |
| Partage | case : lire les annonces des autres | `readAnnounces` | à créer | oui |
| Partage | boutons : contribuer, exporter, importer, contributeurs | — | `/ley contribute`, `export`, `import`, `credits` | — |

Les trois dernières lignes de « Partage » sur l'annonce n'apparaissent qu'avec le partage en direct
(`partage-direct.md`). `autoWaypoint` arrive avec `/ley waypoint` (branche
`feat/point-de-route-option`).

En bas de page : un bouton « Rétablir les réglages par défaut » (O4), et une ligne qui renvoie aux
raccourcis clavier (Options → Raccourcis) et à `/ley help`.

## Ce qu'on NE fait PAS

- **Un menu déroulant.** Sur Forever, ouvrir un menu du système `Menu` créé par un addon fait
  planter le client (2026-09-27), et `UIDropDownMenu` taint les barres d'action (skill public,
  `taint-and-protected-frames.md`). Le choix à trois valeurs se fait par trois boutons radio.
- **Supprimer ou cacher une commande.** Le panneau s'ajoute aux commandes, il ne les remplace pas.
- **Les actions liées à la position** : `/ley add`, `del`, `list`, `clear` (zone), `track`. Elles
  se font sur place, au raccourci ou à la commande ; un bouton dans les options n'aurait pas de sens.
- **Les réglages internes** : `mergeRange`, `auras`, `spells`, `spellNames`, `names`. Ce sont des
  données de capture, pas des préférences ; `/ley name` reste pour le cas rare d'un client qui
  nomme l'objet autrement.
- **Le diagnostic** (`/ley probe`) : il s'adresse au mainteneur.
- **Des réglages par personnage.** La base est au compte, les réglages aussi.
- **Un bouton sur la minicarte** (LibDBIcon) : le compartiment d'addons tient déjà ce rôle.

## Cas limites

- **Réglage changé par une commande, panneau ouvert** : le panneau relit les réglages chaque fois
  qu'il s'affiche, et après chaque commande qui en change un.
- **Combat** : le panneau est un cadre ordinaire, rien n'y est protégé. Un réglage changé en combat
  s'applique tout de suite (le bandeau et les points sont des cadres ordinaires eux aussi).
- **Annonce jamais choisie** (`announce` vide) : aucun des trois boutons n'est coché, et une ligne
  dit que la question viendra à la première absorption. Cocher un bouton vaut réponse.
- **Rétablir les défauts** : seulement les réglages du tableau. Jamais les positions, les
  contributions, le palier de la liste livrée ou la sauvegarde interne.
- **Curseur du rappel** : de 0 à 14 min (le buff dure 15 min) ; une valeur posée plus haut par
  `/ley warn` (jusqu'à 60) s'affiche au maximum du curseur sans être réécrite.
- **Taille d'écran** : la page tient dans la zone de contenu des options sans défiler à 1080 p ;
  sinon, un défilement natif.

## Arbitrages proposés

- **O1** : une page « canevas » (`Settings.RegisterCanvasLayoutCategory` puis
  `Settings.RegisterAddOnCategory`), avec nos propres contrôles faits des modèles du jeu (case,
  curseur, bouton radio, bouton). Plutôt que la mise en page verticale de Blizzard
  (`RegisterVerticalLayoutCategory` + `RegisterAddOnSetting`) : elle n'offre qu'un menu déroulant
  pour un choix à trois valeurs (interdit, voir plus haut), et elle fait tourner le code des réglages de
  Blizzard sur nos tables, une surface de taint plus large. Ce qu'on perd : la recherche des options
  du jeu ne trouvera pas nos réglages.
- **O2** : une seule liste déclarative des réglages (clé, genre, bornes, texte, commande) nourrit
  à la fois le panneau et les commandes, pour qu'ils ne divergent jamais.
- **O3** : le compartiment d'addons garde clic gauche = contribuer, clic droit = bandeau, et gagne
  **Maj + clic = options** ; son infobulle le dit.
- **O4** : un bouton « Rétablir les réglages par défaut », avec confirmation.
- **O5** : `/ley options` (alias `/ley config`) ouvre la page ; `/ley` sans argument rappelle en
  fin de ligne que la page existe.
- **O6** : le panneau peut sortir AVANT le partage en direct, avec les réglages d'aujourd'hui ; les
  lignes de l'annonce s'y ajoutent avec lui.

## Mesures avant le code

Aucun de nos addons n'a encore de page d'options sur Forever : pas de précédent.

- **M7** : enregistrer une page canevas, l'ouvrir, puis passer en mode Édition et entrer en combat,
  avec `/console taintLog 1` : aucune erreur, aucun `ADDON_ACTION_BLOCKED` au nom de LeyLines.
  Témoin : les mêmes gestes, addon désactivé.
- **M8** : `Settings.OpenToCategory` appelé depuis une commande tapée, puis depuis un clic sur le
  compartiment, ouvre bien notre page.

Les deux se font par `/run`, sans rien coder, sur une fiche de l'appli du banc.

## Critères d'acceptation

1. [test] Chaque entrée de la liste déclarative (O2) vise un réglage qui existe dans
   `LL.DEFAULTS`, et la commande et le contrôle passent par le même setter.
   → `tests/test_leylines_options.lua`
2. [test] « Rétablir les défauts » remet les réglages du tableau et ne touche ni `nodes`, ni
   `contrib`, ni `dataVersion`, ni `backup`, ni `legacy`.
3. [check] Chaque libellé et chaque infobulle existe dans les quatre langues. → `check_locale.ps1`
4. [human] Options → AddOns liste l'addon ; décocher « points sur la minicarte » les fait
   disparaître, et `/ley` dit « Minicarte désactivé ». Témoin : `/ley pins` fait la même chose.
5. [human] Le curseur du rappel sur 10, puis `/ley warn` sans argument : « à 10 min restantes ».
6. [human] Après avoir ouvert la page, mode Édition puis combat : pas d'erreur Lua, pas de blocage
   au nom de LeyLines dans `taint.log`. Témoin : mêmes gestes, addon désactivé (M7).
7. [human] `/ley options` et Maj + clic sur le compartiment ouvrent la page de l'addon.
8. [agent] Aucun menu déroulant, aucune écriture dans le panneau des options de Blizzard ni dans
   ses tables. → `api-gotcha-reviewer`

## Contrat

Aucun réglage existant ne change de nom, de forme ou de défaut. Ajouts : `/ley options` (alias
`config`), Maj + clic sur le compartiment. Les réglages neufs (`announce`, `readAnnounces`) sont
définis par `partage-direct.md`.

## Liens

- Faits d'API : skill public `wow-addon-dev:wow-forever-api`, `taint-and-protected-frames.md`
  (menus, panneaux de l'interface).
- Code Blizzard (clone `wow-ui-source-forever`) : `Blizzard_Settings_Shared/Blizzard_Settings.lua`
  (`RegisterCanvasLayoutCategory`, `RegisterAddOnCategory`, `OpenToCategory`),
  `Blizzard_SharedXML/Shared/Button/CheckButtonTemplates.xml`,
  `Blizzard_SharedXML/Shared/Slider/MinimalSlider.xml`.
- Skill `leylines-addon` : la carte du code, `LL.DEFAULTS`, les commandes.
- Spec voisine : `partage-direct.md` (D4, D10).

## Plan (2026-10-08)

0. Mesures M7 et M8 au banc.
1. La liste déclarative (O2) et le panneau avec les réglages d'aujourd'hui, `/ley options`, le
   compartiment. Critères 1 à 8.
2. Les lignes de l'annonce, avec le palier 1 du partage en direct.
