# Partage en direct des failles actives

> État : **approuvée, palier 1 codé** (branche `feat/partage-direct`, 2026-10-08), **pas encore vu
> en jeu** · Mesures faites (M1, M3 et M4 tiennent, 2026-10-08) · Ouverte le 2026-10-08 par le
> user sur une demande de joueur · Transport révisé le même jour par le user : **General en clair,
> avec étiquette, comme les annonces de COC** (D2) · Tranchés par le user le même jour : D4 (le
> joueur choisit automatique, popup ou désactivé), D5, D7, D9, D10 (un panneau d'options), puis D3,
> D6 et D8 : **toutes les décisions sont prises**
> Cible : WoW: Forever / Camelot (16001) · Addon : LeyLines · Revient sur « base locale au compte,
> aucun réseau » (D1)

## Le problème

Commentaire CurseForge du 2026-10-08 :

> Would it be possible for the addon to automatically share active ley lines with other addon users
> with a timer that shows how long ago the last reporting was?

La liste commune dit **où** sont les failles, pas **lesquelles marchent maintenant**. Or elles
disparaissent puis reviennent au même endroit, sans cause connue (dit par le user). Un joueur qui
part vers la plus proche ne sait pas si elle est là. Il le découvre sur place, au buff de 15 s.

Pendant ce temps, un autre joueur vient peut-être d'en absorber une dans la même zone, et le jeu le
lui a prouvé (buff de 15 min). Ce fait reste dans sa base à lui.

## Ce qu'on veut

**Quand le jeu confirme une absorption** (lancer suivi du buff long), une ligne lisible part dans
le canal General de la zone :

```
Ley Line active at 54.3, 62.6 [Map Pin Location] #LL
```

(`Elemental Convergence active at …` côté Horde.) `[Map Pin Location]` est le lien de point de
route du jeu : un clic pose le point de route natif au bon endroit.

**Un joueur sans l'addon** lit la ligne et peut cliquer sur le lien. L'information sert à tout le
monde, pas seulement aux porteurs de l'addon.

**Un porteur de l'addon** voit la même ligne, et le point correspondant prend l'âge du dernier
signalement : « vue active il y a 4 min » dans l'infobulle du point (minicarte et carte du monde)
et sur le bandeau. Un point qu'on a absorbé soi-même porte le même âge.

**Pourquoi General (D2)** : c'est le canal de la zone, donc l'audience qui peut aller à la faille.
Et il **traverse les royaumes** (M1, mesuré le 2026-10-08), là où le Trade et tout canal custom
s'arrêtent au royaume du compte : une annonce atteint tous les joueurs de la zone, quel que soit
leur royaume. Qu'il suive le calque reste à mesurer (M2).

## Ce qu'on NE fait PAS

- **Un AddonMessage sur General.** Il rend `Success` et n'arrive nulle part, pas même en écho
  (mesuré le 2026-09-29). Seul le texte passe, d'où la ligne en clair.
- **Poster sans aucun geste du joueur.** Écrire dans un canal du jeu est protégé : il faut un clic
  ou une touche. Au mieux, la ligne part au geste qui suit l'absorption (M3, D4).
- **Une ligne par lancer.** Une faille annoncée récemment par quiconque ne se réannonce pas (D5).
- **Rattraper à la connexion.** L'historique du chat ne se relit pas : un joueur qui arrive ne voit
  que les annonces suivantes. Réannoncer pour lui serait du spam.
- **Dire qu'une faille est ÉTEINTE.** Un buff de 15 s près d'un point ne prouve pas l'absence : la
  position d'un point capturé au sort est incertaine de ~25 yd.
- **Nourrir la liste commune.** Une annonce reçue ne touche ni `src`, ni `seen`, ni `found` :
  `/ley contribute` et le signal de contribution restent ce qu'ils sont.
- **Créer un point à partir d'une annonce** au palier 1 : n'importe qui peut taper une ligne `#LL`
  à la main (D7).
- **Prévenir à l'arrivée d'une annonce** : pas de son, pas d'icône, pas de seconde ligne.
- **Dépendre de COC ou de CraftLink.**
- **Le canal custom caché** de la première version de cette spec (en AddonMessage, invisible du
  chat) : écarté, il s'arrête au royaume du compte, General non (M1).

## Cas limites

- **Sous-carte ou continent** : la meilleure carte de l'auteur peut être une grotte ou le continent
  (ticket #66), différente de celle du lecteur. La carte voyage donc dans la ligne (le lien la
  porte), jamais déduite de la zone du lecteur.
- **Même faille, deux joueurs** : celui qui a vu passer une annonce de la faille depuis moins de
  15 min n'annonce pas (D5). Deux annonces croisées à la même seconde restent possibles et sans
  gravité.
- **Débit du serveur** : le 3e message en 10 s sur un même canal est refusé (mesuré sur le Trade).
  L'addon n'en approche pas (D5).
- **Ligne forgée** (tapée à la main, carte qui n'existe pas, coordonnées hors de [0, 1], plus de
  255 octets) : rien ne se passe. Une ligne valide ne fait que dater un point déjà connu (D7).
- **Valeurs secrètes** (combat de boss) : une ligne de chat dont un argument est secret est
  ignorée avant toute lecture.
- **Nom du canal** : « General - Elwynn Forest » est localisé et porte la zone. Le canal se
  reconnaît par son genre, pas par son texte (M6).
- **Joueur sorti de General** (`/leave 1`) : rien ne part, rien n'est lu, rien ne casse.
- **Faction** : General est sans doute propre à chaque faction, ce qui colle aux deux espèces
  (fissure Alliance, tornade Horde). Attendu, pas mesuré (M5).
- **Calque** : si General suit le calque, une annonce vient d'un joueur qui voit la même faille que
  toi. Sinon, « vue active » peut être vrai sur son calque et faux sur le tien (M2).
- **Annonce très vieille** : au-delà de 24 h, l'âge ne s'affiche plus (D8).
- **Point de route du joueur pendant l'emprunt du lien** (Contrat) : il est mis de côté et rendu
  dans le même geste, jamais perdu (vu en M4). Un autre addon qui écoute les changements de point
  de route (`USER_WAYPOINT_UPDATED`) en voit passer deux ; sans effet connu.
- **Langue du lien** : le texte affiché du lien (« Map Pin Location ») est celui du client qui
  l'a fabriqué. Seule la phrase autour est en anglais fixe (D9).

## Décisions

- **D1 (user, 2026-10-08)** : on ouvre une spec de partage en direct, ce qui revient sur « base
  locale au compte, aucun réseau ». Le partage par copier-coller et la liste livrée restent.
- **D2 (user, 2026-10-08, révisée le même jour)** : transport = **le canal General de la zone, en
  texte clair avec une étiquette**, sur le modèle des annonces `#CO` de COC. Les mesures M1, M3 et
  M4 l'ont confirmé le 2026-10-08. Première version, remplacée : un canal custom caché en
  AddonMessage.
- **D3 (user, 2026-10-08)** : seul un lancer confirmé par le buff long donne une annonce.
- **D4 (user, 2026-10-08)** : **le joueur choisit**, dans une option de l'addon, entre trois modes,
  et l'addon lui **demande** lequel. Le joueur ne parle donc jamais dans General sans l'avoir
  choisi : c'est ce qui concilie la demande (« automatically ») avec le modèle de COC (rien
  d'automatique sans accord) et la règle « jamais à tous sur un événement local ».
  - **automatique** : la ligne attend le prochain clic ou la prochaine touche du joueur, puis part
    (écrire dans un canal du jeu exige un geste). M3 tient : la ligne part au clic suivant dans le
    monde (la touche n'a pas été essayée).
  - **popup** : après l'absorption, une fenêtre « Annoncer cette Ley Line dans General ? Oui /
    Non ». Le clic sur Oui est le geste qui poste. Prouvé sur Forever (un clic ou une commande
    tapée écrit dans le Trade, constat C15).
  - **désactivé** : rien ne part. La lecture des annonces des autres continue (voir D10).
  - **La question** : à la première absorption confirmée après la mise à jour, une fenêtre propose
    les trois modes. Tant que le joueur n'a pas répondu, rien ne part. Fermée sans choix (Échap),
    elle revient à l'absorption suivante, une fois par session au plus.
  - **Où se règle le mode** : une commande `/ley announce auto|popup|off`, et une option dans le
    panneau d'options de l'addon (Options → AddOns), comme les autres réglages (D10).
  - **Débit** : D5 vaut pour les modes automatique et popup ; en popup, une faille déjà annoncée
    (D5) n'ouvre même pas la fenêtre.
- **D5 (user, 2026-10-08)** : pas d'annonce si la même faille (même espèce, `mergeRange`) a été
  annoncée dans General depuis moins de 15 min (la durée du buff), par n'importe qui ; au plus une
  annonce par joueur toutes les 5 min. Le user ajoute que **connaître le cycle d'apparition et de
  disparition des failles compte plus encore** (Q5) : si on l'apprend, ces 15 min deviendront « le
  temps qu'il reste à la faille ».
- **D6 (user, 2026-10-08)** : les lignes `#LL` des autres restent affichées dans le chat des porteurs de
  l'addon, comme chez tout le monde : le lien leur sert aussi.
- **D7 (user, 2026-10-08)** : une annonce d'une position inconnue du lecteur est ignorée au palier 1. Plus
  tard, peut-être : un point temporaire « annoncé par un joueur », jamais enregistré, qui s'efface.
- **D8 (user, 2026-10-08)** : l'âge s'affiche jusqu'à 24 h, en minutes sous 1 h (« il y a 4 min »), en
  heures au-delà. Il vit dans la base du compte (`node.live`, une date) et survit à un `/reload`.
- **D9 (user, 2026-10-08)** : texte en anglais fixe, quelle que soit la langue du client, comme les
  jetons de COC. La lecture ne s'appuie que sur l'étiquette et sur le lien, jamais sur la phrase.
- **D10 (user, 2026-10-08)** : un **panneau d'options** est nécessaire (« les joueurs ne vont pas
  faire que des commandes »), avec **toutes** les options de l'addon, pas seulement celles de
  l'annonce. C'est une fonctionnalité à part : spec `panneau-options.md`. Ici, il porte le mode
  d'annonce (D4) et la lecture des annonces des autres (oui / non).

## Le cycle des failles (Q5, à étudier)

Le user le dit plus important que le réglage de D5 : comment une faille disparaît, et quand elle
revient. On sait seulement qu'elle disparaît puis revient au même endroit, sans cause connue. Les
annonces de cette spec en sont la première source : chaque annonce dit « active à telle heure ».
Ce qu'il faudrait savoir :

- combien de temps une faille reste active, et combien de temps elle reste absente ;
- si toutes les failles d'une zone suivent le même rythme, ou chacune le sien ;
- si une absorption la fait disparaître (pour tous, ou pour le seul joueur) ;
- si l'état dépend du calque (M2).

Piste proposée, pas tranchée : chaque client tient un petit journal par point, « vue active à T »
(absorption ou annonce) et « lancer raté près du point à T » (buff de 15 s à moins de ~10 yd d'un
point connu : un indice d'absence, pas une preuve, la position d'un point étant incertaine de
~25 yd). Ces journaux partiraient avec `/ley contribute`, et l'outillage chercherait le rythme.
Le jour où le cycle est connu, le bandeau peut dire « active encore ~10 min » ou « revient dans
~20 min ». Assez gros pour sa propre spec (`cycle-failles.md`), à ouvrir sur le mot du user.

## Mesures

Fiche `mesure--general-leylines` de l'appli du banc, cochée par le user le 2026-10-08 entre 13:39
et 13:50, build 70245 : Zef Lora (royaume 4618) et Mal Fanisa (4620), groupés, même zone, même
calque (même GUID d'un PNJ ciblé des deux côtés). Les faits sont versés au skill public
(`chat-channels-and-communities.md`).

- **M1, tient** : General n'est PAS découpé par royaume. Chacun a lu la ligne de l'autre dans
  `/1`, et le lien posté par l'un a été cliqué par l'autre. Le Trade, lui, l'est (2026-10-07).
- **M2, pas mesuré** : se dégrouper ne change pas de calque tout de suite (dit par le user : une
  annonce du jeu prévient d'abord). General suit-il le calque ? On ne sait pas.
- **M3, tient** : une ligne mise en attente par du code d'addon est partie dans General au clic
  suivant dans le monde (`WorldFrame` `OnMouseDown`). La touche n'a pas été essayée.
- **M4, tient à moitié** : le lien fabriqué par le jeu (`C_Map.GetUserWaypointHyperlink`), posté
  par du code d'addon, arrive cliquable dans l'autre royaume. Un lien écrit à la main
  (`[Map Pin Location]` sans l'icône) arrive en texte brut, sans lien. Le vrai texte affiché est
  `[|A:Waypoint-MapPin-ChatIcon:13:13:0:0|a Map Pin Location]`. **L'emprunt marche** : mettre de
  côté le point de route du joueur, poser le nôtre, prendre le lien, rendre le sien ; le lien est
  arrivé cliquable au centre de la zone, et le point du joueur est revenu à sa place.
- **M5** (attendu, pas mesuré) : un personnage Horde dans la même zone ne voit pas le General de
  l'Alliance.
- **M6** (au palier 1) : comment reconnaître General quelle que soit la langue
  (`GetChannelDisplayInfo`, `C_ChatInfo.GetChannelInfoFromIdentifier`).

## Critères d'acceptation

1. [test] Une annonce construite tient en 255 octets ; relue, elle rend la même espèce, carte et
   position ; une ligne sans `#LL`, sans lien valide, ou aux coordonnées hors bornes est ignorée.
   L'emprunt du lien rend au joueur son point de route, ou n'en laisse aucun s'il n'en avait pas.
   → `tests/test_leylines_live.lua`
2. [test] Une annonce reçue date (`live`) le point de même espèce le plus proche dans `mergeRange`,
   et ne change ni `src`, ni `seen`, ni `found`, ni le compte du signal de contribution.
3. [test] D5 : une faille annoncée par un autre il y a 2 min ne se réannonce pas ; deux absorptions
   du même joueur à 1 min d'écart ne donnent qu'une annonce.
4. [test] Une ligne de chat aux arguments secrets est ignorée sans erreur.
5. [test] D4 : sans mode choisi, une absorption ouvre la question et ne poste rien ; en
   « désactivé », rien ne s'ouvre ni ne part ; en « popup », la fenêtre s'ouvre et rien ne part
   avant Oui ; une faille déjà annoncée (D5) n'ouvre pas la fenêtre.
6. [human] Première absorption après la mise à jour : la question des trois modes s'affiche ; le
   choix « popup » survit à un `/reload`. Témoin : un second personnage du même compte ne reçoit
   plus la question (le réglage est au compte).
7. [human] Le compte A absorbe une faille et l'annonce (mode popup, Oui). Chez B, même zone : la ligne
   apparaît dans General, le lien pose le point de route sur la faille, et l'infobulle du point dit
   « vue active il y a 0 min ». Témoin : la même infobulle chez B AVANT l'annonce, sans âge.
   Observateur : le user, au banc.
8. [human] Chez B, addon LeyLines désactivé : la ligne se lit et le lien se clique pareil.
9. [human] Même essai que 7, avec A et B sur deux royaumes différents. Chez A, un point de route
   posé avant l'absorption est toujours là après l'annonce.
10. [human] (palier 3) Mode automatique : A absorbe, puis clique par terre ; la ligne part à ce
    clic, pas avant.
11. [agent] Aucune écriture hors d'un geste du joueur, débit tenu, gardes de valeurs secrètes en
    place, pas de taint par le panneau d'options. → `api-gotcha-reviewer`

## Contrat

**La ligne** (texte de canal, 255 octets au plus) :

```
<Espèce en anglais> active at <x>, <y> <lien de point de route> #LL
```

- `<Espèce>` : `Ley Line` ou `Elemental Convergence`. `<x>, <y>` : coordonnées de carte à une
  décimale, pour l'œil seulement.
- Le **lien** porte la carte (`uiMapID`) et la position (`|Hworldmap:<carte>:<x>:<y>|h`, en
  dix-millièmes) : c'est lui que l'addon lit, par `C_Map.GetUserWaypointFromHyperlink`. Il est
  **emprunté au jeu**, jamais écrit à la main (un lien fait main arrive sans lien, M4) : dans le
  même geste, `C_Map.GetUserWaypoint()` met de côté le point du joueur, `C_Map.SetUserWaypoint`
  pose celui de la faille, `C_Map.GetUserWaypointHyperlink()` donne le lien, puis le point du
  joueur est rendu (`SetUserWaypoint`), ou effacé s'il n'y en avait pas (`ClearUserWaypoint`).
- L'étiquette `#LL` est la seule marque d'une annonce ; le reste de la phrase peut changer sans
  casser les lecteurs.

**Données** (au compte) : `LeyLinesDB.announce` = `nil` (jamais demandé), `"auto"`, `"popup"` ou
`"off"` (D4) ; `LeyLinesDB.readAnnounces` (D10, vrai par défaut) ; `node.live` (date de la
dernière annonce connue de ce point, la sienne comprise). Rien d'autre n'est ajouté à un point.
`announce` est une clé neuve sans défaut : `nil` est un état, celui où l'on doit encore demander.

## Liens

- Faits d'API : skill public `wow-addon-dev:wow-forever-api`, références
  `chat-channels-and-communities.md` (ce qui porte un AddonMessage, le canal par royaume, écrire du
  texte dans un canal) et `secret-values-and-lockdowns.md`.
- COC : `docs/specs/annonce-commerce.md` (le modèle : ligne lisible + étiquette `#CO`, un clic par
  ligne), `Orders_Announce.lua` (format), `Orders_AnnounceRecv.lua` (lecture).
- Code Blizzard (clone `wow-ui-source-forever`) : `LinkUtil.lua` (`LinkTypes.WorldMapWaypoint` =
  `worldmap`), `ItemRefHandlers.lua` (le clic sur ce lien pose le point de route).
- Skill `leylines-addon` : capture par la durée du buff, `mergeRange`, l'espèce d'un point.
- Specs voisines : `contribution-positions.md`, `signal-contribution.md` (`seen` / `found`),
  `panneau-options.md` (D10).

## Plan (2026-10-08, mesures faites)

1. Palier 1 : la question et les modes popup et désactivé (`/ley announce`), l'annonce avec le
   lien emprunté, lecture des lignes `#LL`, âge dans les infobulles et le bandeau. Critères 1 à 9
   et 11. **Codé** (`LeyLines_Live.lua`), critères 1 à 5 tenus par `tests/test_leylines_live.lua`.
2. Palier 2 : le mode d'annonce et la lecture dans le panneau d'options. **Fait avec le palier 1** :
   le panneau est sorti en v1.7.0, il a suffi de deux entrées dans `LL.Options.LIST`.
3. Palier 3 : le mode automatique, proposé dans la question. Critère 10.

## Ce que le code du palier 1 a tranché (2026-10-08)

Des points que les décisions laissaient ouverts, tranchés en codant, à revoir au banc :

- **La question** propose les deux modes du palier : **Oui** passe en « demander » et poste
  aussitôt (ce clic est le geste), **Jamais** passe en « désactivé », **Échap** ne tranche rien.
  Elle s'ouvre une fois par session au plus. Elle ne s'ouvre pas sans canal General.
- **La fenêtre « demander »** se ferme seule au bout de 2 min, et ne se rouvre pas pour la même
  faille avant 15 min. Une annonce de la même faille lue pendant qu'elle est ouverte la ferme.
  Au clic sur Oui, tout se revérifie : annonce lue entre-temps, General parti, messagerie
  verrouillée (`C_ChatInfo.InChatMessagingLockdown`, combat de boss) : rien ne part, et le chat
  le dit.
- **D5 vit en mémoire de session**, pas dans la base (le contrat n'ajoute que `live` à un point) :
  après un `/reload`, une faille annoncée il y a 5 min peut l'être une fois de plus. Une annonce
  lue compte pour D5 même lecture coupée : se taire après un autre n'est pas un affichage.
- **Les coordonnées annoncées sont celles du point**, pas celles du lancer : le lecteur les
  cherche dans sa liste à `mergeRange` près.
- **L'espèce d'une annonce lue est celle du lecteur** : la phrase n'est pas lue (D9), et General
  est attendu propre à chaque faction (M5, pas mesuré).
- **General se reconnaît à son nom**, numéro et zone retirés (« General », « Général »,
  « Allgemein »), à l'envoi comme à la lecture. Une ligne `#LL` d'un autre canal est ignorée. Le
  `zoneChannelID` dirait General sans texte, mais il n'est pas mesuré (M6) : `/ley probe` le relève.
- **Notre propre ligne revient en écho** : écartée par le GUID de l'auteur, jamais par son nom.
- **Réglages** : `LeyLinesDB.announce` est un choix sans défaut, que la réinitialisation des
  options ne touche pas (c'est une réponse du joueur). `readAnnounces` n'a pas de clé dans
  `DEFAULTS` : nil vaut vrai. Commande `/ley announce popup|off` (alias `annonce`) ; dans le
  panneau, deux cases qui s'excluent, section Partage (jamais un menu déroulant, C17).
- **L'âge** s'affiche sur une 3e ligne du bandeau, qui grandit seulement quand il y en a un.
