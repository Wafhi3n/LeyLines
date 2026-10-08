# Partage en direct des failles actives

> État : **brouillon, suspendu aux mesures M1 à M4**, rien de codé · Ouverte le 2026-10-08 par le
> user sur une demande de joueur · Transport révisé le même jour par le user : **General en clair,
> avec étiquette, comme les annonces de COC** (D2) · D3 à D9 proposés par l'agent, pas tranchés ;
> **D4 (automatique ou au clic) est au user**
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
Le user pense qu'il suit aussi le calque et qu'il traverse les royaumes, ce qui atteindrait des
joueurs qu'aucun canal custom n'atteint. C'est à mesurer (M1, M2) : le Trade est découpé par
royaume (mesuré le 2026-10-07), General ne l'a jamais été.

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
  chat, limité au royaume) : il reste le plan B si les mesures ferment General.

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

## Décisions

- **D1 (user, 2026-10-08)** : on ouvre une spec de partage en direct, ce qui revient sur « base
  locale au compte, aucun réseau ». Le partage par copier-coller et la liste livrée restent.
- **D2 (user, 2026-10-08, révisée le même jour)** : transport = **le canal General de la zone, en
  texte clair avec une étiquette**, sur le modèle des annonces `#CO` de COC. Sous réserve des
  mesures M1 à M4. Première version, remplacée : un canal custom caché en AddonMessage.
- **D3 (proposé)** : seul un lancer confirmé par le buff long donne une annonce.
- **D4 (au user, le point clé)** : automatique ou au clic ? Le modèle de COC pour le Trade, validé
  par le user le 2026-09-29, est **case décochée au départ, un clic par ligne, jamais
  automatique**. Et la règle de l'écosystème dit « jamais à tous sur un événement local ». Une
  annonce automatique à chaque absorption déroge aux deux. Trois options :
  - (a) **au clic** : après l'absorption, une ligne locale « Annoncer dans General » cliquable ;
    un clic poste la ligne. Prouvé sur Forever (un clic ou une commande tapée écrit dans le Trade,
    constat C15). Proposé pour le palier 1.
  - (b) **au geste suivant, sur option** (`/ley announce auto`) : la ligne attend la prochaine
    touche ou le prochain clic du joueur, puis part. Seulement si M3 passe : la file vidée par
    l'input n'est prouvée que sur Era.
  - (c) **(b) actif par défaut** : c'est ce que demande le joueur (« automatically »), et c'est la
    seule option où le joueur parle dans General sans l'avoir choisi.
- **D5 (proposé)** : pas d'annonce si la même faille (même espèce, `mergeRange`) a été annoncée
  dans General depuis moins de 15 min (la durée du buff), par n'importe qui ; au plus une annonce
  par joueur toutes les 5 min.
- **D6 (proposé)** : les lignes `#LL` des autres restent affichées dans le chat des porteurs de
  l'addon, comme chez tout le monde : le lien leur sert aussi.
- **D7 (proposé)** : une annonce d'une position inconnue du lecteur est ignorée au palier 1. Plus
  tard, peut-être : un point temporaire « annoncé par un joueur », jamais enregistré, qui s'efface.
- **D8 (proposé)** : l'âge s'affiche jusqu'à 24 h, en minutes sous 1 h (« il y a 4 min »), en
  heures au-delà. Il vit dans la base du compte (`node.live`, une date) et survit à un `/reload`.
- **D9 (proposé)** : texte en anglais fixe, quelle que soit la langue du client, comme les jetons
  de COC. La lecture ne s'appuie que sur l'étiquette et sur le lien, jamais sur la phrase.

## Mesures avant tout code (fiche `mesure--general-leylines` de l'appli du banc)

- **M1** : General est-il découpé par royaume, comme le Trade ? Deux comptes de royaumes
  différents, côte à côte dans la même zone, groupés. Si oui, l'argument « entre royaumes » de D2
  tombe. General garde l'intérêt d'être lu et cliqué par tous, mais l'arbitrage avec le spam change.
- **M2** : General suit-il le calque ? Même essai sur deux calques différents (le calque se lit dans
  le GUID d'un même PNJ ciblé des deux côtés).
- **M3** : une ligne mise en attente par l'addon part-elle au clic suivant dans le monde ? Sinon,
  D4 se limite à (a).
- **M4** : le serveur laisse-t-il passer, dans General, un lien de point de route écrit par un
  addon, et l'autre côté peut-il cliquer dessus ? Format exact relevé une fois sur le client
  (`C_Map.GetUserWaypointHyperlink` après un ctrl-clic sur la carte), jamais écrit de mémoire.
- **M5** (attendu) : un personnage Horde dans la même zone ne voit pas le General de l'Alliance.
- **M6** (au palier 1) : comment reconnaître General quelle que soit la langue
  (`GetChannelDisplayInfo`, `C_ChatInfo.GetChannelInfoFromIdentifier`).

## Critères d'acceptation

1. [test] Une annonce construite tient en 255 octets ; relue, elle rend la même espèce, carte et
   position ; une ligne sans `#LL`, sans lien valide, ou aux coordonnées hors bornes est ignorée.
   → `tests/test_leylines_live.lua`
2. [test] Une annonce reçue date (`live`) le point de même espèce le plus proche dans `mergeRange`,
   et ne change ni `src`, ni `seen`, ni `found`, ni le compte du signal de contribution.
3. [test] D5 : une faille annoncée par un autre il y a 2 min ne se réannonce pas ; deux absorptions
   du même joueur à 1 min d'écart ne donnent qu'une annonce.
4. [test] Une ligne de chat aux arguments secrets est ignorée sans erreur.
5. [human] Le compte A absorbe une faille et l'annonce (selon D4). Chez B, même zone : la ligne
   apparaît dans General, le lien pose le point de route sur la faille, et l'infobulle du point dit
   « vue active il y a 0 min ». Témoin : la même infobulle chez B AVANT l'annonce, sans âge.
   Observateur : le user, au banc.
6. [human] Chez B, addon LeyLines désactivé : la ligne se lit et le lien se clique pareil.
7. [human] (si M1 dit que General traverse les royaumes) Même essai que 5, avec A et B sur deux
   royaumes différents.
8. [agent] Aucune écriture hors d'un geste du joueur, débit tenu, gardes de valeurs secrètes en
   place. → `api-gotcha-reviewer`

## Contrat

**La ligne** (texte de canal, 255 octets au plus) :

```
<Espèce en anglais> active at <x>, <y> <lien de point de route> #LL
```

- `<Espèce>` : `Ley Line` ou `Elemental Convergence`. `<x>, <y>` : coordonnées de carte à une
  décimale, pour l'œil seulement.
- Le **lien** porte la carte (`uiMapID`) et la position : c'est lui que l'addon lit, par
  `C_Map.GetUserWaypointFromHyperlink`. Il se construit à la main au format relevé en M4 :
  `C_Map.GetUserWaypointHyperlink` ne lit que le point de route du joueur, et s'en servir
  demanderait d'écraser le sien.
- Si M4 refuse le lien : `#LL<uiMapID>` (par exemple `#LL1429`) et la position lue dans
  `<x>, <y>`.
- L'étiquette `#LL` est la seule marque d'une annonce ; le reste de la phrase peut changer sans
  casser les lecteurs.

**Données** : `LeyLinesDB.announce` (réglage de D4) ; `node.live` (date de la dernière annonce
connue de ce point, la sienne comprise). Rien d'autre n'est ajouté à un point.

## Liens

- Faits d'API : skill public `wow-addon-dev:wow-forever-api`, références
  `chat-channels-and-communities.md` (ce qui porte un AddonMessage, le canal par royaume, écrire du
  texte dans un canal) et `secret-values-and-lockdowns.md`.
- COC : `docs/specs/annonce-commerce.md` (le modèle : ligne lisible + étiquette `#CO`, un clic par
  ligne), `Orders_Announce.lua` (format), `Orders_AnnounceRecv.lua` (lecture).
- Code Blizzard (clone `wow-ui-source-forever`) : `LinkUtil.lua` (`LinkTypes.WorldMapWaypoint` =
  `worldmap`), `ItemRefHandlers.lua` (le clic sur ce lien pose le point de route).
- Skill `leylines-addon` : capture par la durée du buff, `mergeRange`, l'espèce d'un point.
- Specs voisines : `contribution-positions.md`, `signal-contribution.md` (`seen` / `found`).

## Plan (2026-10-08, à revoir après les mesures)

0. Mesures M1 à M4 au banc, fiche `mesure--general-leylines`.
1. Palier 1 : annonce au clic (D4 a), lecture des lignes `#LL`, âge dans les infobulles et le
   bandeau. Critères 1 à 6 et 8.
2. Palier 2, si M3 passe et si le user le veut : annonce au geste suivant (D4 b ou c).
