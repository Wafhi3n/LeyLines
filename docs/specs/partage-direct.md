# Partage en direct des failles actives

> État : **brouillon**, rien de codé · Ouverte le 2026-10-08 par le user (« ouvrir une spec »), sur
> une demande de joueur ; arbitrages D2 à D10 **proposés par l'agent, pas encore tranchés**
> Cible : WoW: Forever / Camelot (16001) · Addon : LeyLines · Revient sur la décision « base locale
> au compte, aucun réseau » (D1)

## Le problème

Commentaire CurseForge du 2026-10-08 :

> Would it be possible for the addon to automatically share active ley lines with other addon users
> with a timer that shows how long ago the last reporting was?

La liste commune dit **où** sont les failles, pas **lesquelles marchent maintenant**. Or elles
disparaissent puis reviennent au même endroit, sans cause connue (dit par le user). Un joueur qui
part vers la plus proche ne sait pas si elle est là. Il le découvre sur place, au buff de 15 s.

Pendant ce temps, un autre porteur de l'addon vient peut-être d'en absorber une à deux zones de là,
et le jeu le lui a prouvé (buff de 15 min). Ce fait reste dans sa base à lui.

## Ce qu'on veut

**Quand le jeu confirme une absorption** (lancer suivi du buff long), l'addon le dit aux autres
porteurs de LeyLines, sans rien écrire dans le chat de personne.

**Chez ceux qui le reçoivent**, le point correspondant porte l'âge du dernier signalement :
« vue active il y a 4 min » dans l'infobulle du point (minicarte et carte du monde) et sur le
bandeau de la plus proche. Un point qu'on a absorbé soi-même porte le même âge.

**Un joueur qui se connecte** ne repart pas de zéro : il reçoit, dans les secondes qui suivent, les
signalements de la dernière heure que les autres connaissent (palier 2).

**`/ley live off`** coupe tout : plus d'envoi, plus de réception, le canal est quitté.
`/ley live on` le remet.

## Ce qu'on NE fait PAS

- **Écrire dans General, Trade ou un autre canal du jeu.** C'était la première idée du user. Un
  AddonMessage sur un canal du jeu rend `Success` et n'arrive nulle part, pas même en écho (mesuré
  le 2026-09-29, build 70058). Du TEXTE y passe, mais chaque joueur de la zone le voit, addon ou
  non, il faut un clic ou une touche pour chaque ligne, et le serveur refuse le 3e message en 10 s.
  Ce serait du spam, et la règle de l'écosystème l'interdit : jamais de message « à tous » sur un
  événement local.
- **Atteindre les autres royaumes.** Un canal s'arrête au royaume sous-jacent, qui suit le compte
  (mesuré le 2026-10-07). Les joueurs des deux royaumes partagent pourtant le même monde : un
  joueur de « PvE » ne verra pas les signalements de « PvE 2 ». Le relais par chuchotement (comme
  le passeur de COC) est un chantier à part.
- **Dire qu'une faille est ÉTEINTE.** Un buff de 15 s près d'un point ne prouve pas l'absence : la
  position d'un point capturé au sort est incertaine de ~25 yd. Seul le positif circule.
- **Nourrir la liste commune.** Un signalement reçu ne touche ni `src`, ni `seen`, ni `found` :
  `/ley contribute` et le signal de contribution restent exactement ce qu'ils sont.
- **Nommer qui a signalé dans l'interface.** Ça ne cache rien pour autant : `CHAT_MSG_ADDON` donne
  le nom complet de l'expéditeur à tout addon qui écoute le canal. N'importe quelle copie modifiée,
  ou un autre addon branché sur `LeyLinesNet`, peut noter « tel joueur a absorbé ici, à telle
  heure ». Envoyer un signalement, c'est donner son nom et sa position à tout le canal du royaume.
- **Prévenir à l'arrivée d'un signalement.** Pas de ligne de chat, pas de son, pas d'icône : l'âge
  s'affiche quand on regarde un point.
- **Partager un `/ley add`, une infobulle, un point importé.** Seul le jeu confirme (sort).
- **Dépendre de COC ou de CraftLink.** LeyLines a son propre canal, minimal.

## Cas limites

- **Point inconnu chez le receveur** (pas de point de même espèce à moins de `mergeRange`) : voir D4.
- **Taille de zone inconnue** (`C_Map.GetMapWorldSize` muet, donc pas de distance) : le
  signalement est ignoré, comme l'anti-doublon s'abstient aujourd'hui.
- **Deux joueurs absorbent la même faille à la même minute** : le second ne renvoie rien s'il a
  reçu le premier depuis moins de 2 min (D7).
- **Un joueur relance son sort en boucle** : un envoi par point toutes les 5 min au plus (D7).
- **Message forgé** (carte qui n'existe pas, coordonnées hors de [0, 1], espèce inconnue, version
  inconnue, plus de 255 octets) : jeté sans erreur. Un expéditeur qui dépasse le débit permis est
  ignoré pour la session.
- **Valeurs secrètes** (combat de boss, sur Forever) : un `CHAT_MSG_ADDON` dont un argument est
  secret est ignoré avant toute lecture (voir les Liens).
- **Notre propre écho** : le canal nous renvoie nos messages. Il tamponne un point qu'on vient de
  tamponner soi-même : sans effet, on ne le filtre pas.
- **Canal impossible à rejoindre** (le joueur a déjà tous ses numéros de canaux) : le partage est
  inactif, `/ley` le dit, rien d'autre ne casse.
- **Personnage neuf** : le canal ne doit pas prendre le `/1` de General (voir le Contrat).
- **COC installé aussi** : deux canaux custom cachés (`CraftLinkNet` et le nôtre) et deux
  réparations du `/1` indépendantes, chacune avec `SwapChatChannelsByChannelIndex`. Elles ne
  doivent pas se battre : aucune ne déplace un canal custom de l'autre, et le `/1` finit à un canal
  du jeu. Mécanisme à trancher au palier 1 (Q4).
- **Calques** (layers) : on ignore si l'état d'une faille dépend du calque. Si oui, « vue active il
  y a 4 min » peut être vrai sur le calque d'un autre et faux sur le tien. À mesurer au banc (Q1).
- **Signalement très vieux** : au-delà de 24 h, l'âge ne s'affiche plus (D5).

## Décisions

- **D1 (user, 2026-10-08)** : on ouvre une spec de partage en direct, ce qui revient sur « base
  locale au compte, aucun réseau ». Le partage par copier-coller et la liste livrée restent.
- **D2 (proposé)** : transport = un canal **custom caché** propre à LeyLines (nom proposé
  `LeyLinesNet`), en AddonMessage. C'est la seule voie diffusée qui arrive sur Forever, sans clic
  du joueur et invisible du chat.
- **D3 (proposé)** : seul un lancer confirmé par le buff long envoie un signalement. La vignette
  aussi si un jour elle marche (elle ne marche pas aujourd'hui).
- **D4 (proposé)** : un signalement d'une position inconnue du receveur est **ignoré** au palier 1.
  Variante à trancher pour plus tard : point temporaire « signalé par un joueur », jamais
  enregistré, qui s'efface à l'expiration.
- **D5 (proposé)** : l'âge s'affiche jusqu'à 24 h, en minutes sous 1 h (« il y a 4 min »), en
  heures au-delà (« il y a 3 h »). Un point vu il y a moins de 15 min (la durée du buff) ressort
  sur la carte. Comment il ressort reste à dessiner.
- **D6 (proposé)** : l'âge vit dans la base du compte (`node.live`, une date). Il survit à un
  `/reload` et à une déconnexion.
- **D7 (proposé)** : débit. Envoi : un par point toutes les 5 min au plus, rien si ce point a été
  signalé par un autre il y a moins de 2 min. Réception : au-delà de 10 messages par minute d'un
  même expéditeur, on l'ignore pour la session.
- **D8 (proposé, le point le plus délicat)** : actif par défaut. Une seule ligne de chat, la
  première fois, dit ce qui est partagé et comment couper (`/ley live off`). À peser : actif par
  défaut, chaque absorption annonce le nom du joueur et sa position à tous les porteurs de
  l'addon de son royaume, sans qu'il l'ait choisi (voir « Nommer qui a signalé »). Coupé par
  défaut, presque personne ne l'allumera et il n'y aura rien à recevoir.
- **D9 (proposé)** : rattrapage au palier 2. À l'arrivée sur le canal, une demande ; ceux qui ont
  des signalements de moins d'une heure répondent sur le canal après un délai tiré au hasard
  (1 à 6 s), et se taisent s'ils ont entendu une réponse qui couvre déjà les leurs.
- **D10 (proposé)** : l'âge voyage en **minutes écoulées**, pas en date. Le receveur le convertit
  avec sa propre horloge : aucune dépendance aux horloges des autres.

## Questions ouvertes (à mesurer, pas à décider)

- **Q1** : l'état actif d'une faille dépend-il du calque ? Deux comptes, même faille, calques
  différents (groupe puis dégroupe), l'un absorbe, l'autre tente.
- **Q2** : combien de canaux custom un joueur peut-il rejoindre sur Forever, et que se passe-t-il au
  dernier ? (Ceux qui ont COC ont déjà `CraftLinkNet`.)
- **Q3** : `GetServerTime` est-il fiable sur Forever ? Seulement si D10 est rejetée.
- **Q4** : COC et LeyLines ensemble, sur un personnage neuf : où finissent `/1`, `/2` et les deux
  canaux cachés après deux connexions ?

## Critères d'acceptation

1. [test] Un signalement encodé puis décodé rend la même espèce, carte et position ; un message
   forgé (carte nulle, coordonnée hors bornes, espèce inconnue, version inconnue) est rejeté sans
   erreur. → `tests/test_leylines_live.lua`
2. [test] Un signalement reçu tamponne `live` du point de même espèce le plus proche dans
   `mergeRange`, et ne change ni `src`, ni `seen`, ni `found`, ni le compte du signal de
   contribution.
3. [test] Débit d'envoi (D7) : deux absorptions du même point à 1 min d'intervalle n'envoient
   qu'un message ; une absorption 1 min après un signalement reçu du même point n'en envoie aucun.
4. [test] Un `CHAT_MSG_ADDON` aux arguments secrets est ignoré sans erreur.
5. [human] À deux comptes du même royaume, le compte A absorbe une faille ; dans les 5 s,
   l'infobulle de ce point chez B dit « vue active il y a 0 min ». Témoin : la même infobulle chez
   B AVANT l'absorption, sans âge. Observateur : le user, au banc.
6. [human] Sur un personnage neuf, après la première connexion, `/1` écrit dans General et aucune
   ligne du canal de LeyLines n'apparaît dans le chat. Témoin : le même personnage addon coupé.
7. [human] `/ley live off` chez B, puis A absorbe : rien ne change chez B, et
   `/run print(GetChannelName("LeyLinesNet"))` rend `0` chez B. `/ley live on` : il revient.
8. [human] (palier 2) A absorbe, puis B fait `/reload` : dans les 10 s, l'infobulle chez B donne
   l'âge du signalement de A.
9. [agent] Pas d'écriture dans le chat d'un autre joueur, pas d'envoi hors débit, gardes de valeurs
   secrètes en place. → `api-gotcha-reviewer`

## Contrat

**Préfixe** AddonMessage : `LeyLines` (≤ 16 caractères, inscrit par
`C_ChatInfo.RegisterAddonMessagePrefix`). Distribution `CHANNEL` sur le canal custom de D2.

**Messages** (un message ≤ 255 octets, coupé sinon sans erreur nulle part) :

| Message | Sens | Forme |
|---|---|---|
| Signalement | « je viens d'absorber ici » | `S1;<espèce><uiMapID>=<x>,<y>` |
| Demande (palier 2) | « qu'avez-vous de récent ? » | `Q1` |
| Réponse (palier 2) | les signalements de moins d'une heure | `A1;<espèce><uiMapID>=<x>,<y>,<minutes>;…` |

Espèce `L` (fissure) ou `V` (tornade), coordonnées en dix-millièmes de carte, comme le code `LL2`.
Le chiffre après la lettre est la version du message : un client ignore une version qu'il ne
connaît pas. Une réponse trop longue se coupe en plusieurs messages, chacun lisible seul.

**Canal** : rejoint seulement quand un canal du jeu tient déjà le `/1`, ou après 10 s ; rendu au
`/1` sinon (`C_ChatInfo.SwapChatChannelsByChannelIndex`) ; retiré de l'affichage de toutes les
fenêtres de chat ; surveillé et rejoint s'il se perd. C'est la mécanique de CraftLink
(`CraftLink_Transport.lua`, `_FixSlot1` de `CraftLink_Fanout.lua`), à refaire petit, pas à
embarquer.

**Données** : `LeyLinesDB.live` (réglage, vrai par défaut si D8 tient) ; `node.live` (date du
dernier signalement connu de ce point, le sien compris). Aucune autre donnée n'est ajoutée à un
point.

## Liens

- Faits d'API : skill public `wow-addon-dev:wow-forever-api`, références
  `chat-channels-and-communities.md` (ce qui porte un AddonMessage, le canal par royaume, le `/1`)
  et `secret-values-and-lockdowns.md`.
- Skill `leylines-addon` : capture par la durée du buff, `mergeRange`, l'espèce d'un point.
- Specs voisines : `contribution-positions.md` (le code `LL2`, ce qui part vers la liste),
  `signal-contribution.md` (`seen` / `found`, à ne pas toucher).
- COC : `docs/specs/pont-royaumes.md` (relais entre royaumes), pour un éventuel palier 4.

## Plan (2026-10-08, à revoir après les arbitrages)

1. Palier 1 : canal, envoi du signalement, réception et tamponnage, âge dans les infobulles et le
   bandeau, `/ley live`. Critères 1 à 7 et 9.
2. Palier 2 : rattrapage à l'arrivée (D9). Critère 8.
3. Palier 3, si D4 change : point temporaire pour une position inconnue.
4. Palier 4, spec à part : relais vers les autres royaumes.
