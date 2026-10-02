# Contribution des positions (crowdsourcing)

> État : **validée, en cours** · Rédigée le 2026-09-27 · Décisions D1-D4 et arbitrages A1-A4
> tranchés par le user le 2026-09-27 (un amendement de A4 essayé puis retiré) · **Publié** : v1.1.0
> (espèce, `LL2`, `/ley contribute`, pipeline v1 à la main, liste générée en triplets), v1.1.1 (nom,
> icône), v1.2.0 (compartiment d'addons : clic gauche = contribute). **Codé, pas publié** (branche
> `feat/signal-contribution`) : `seen`, lien pré-rempli. Reste : retraits signalés par les joueurs
> (`gone`, D7), couleur « à confirmer ». Registre des contributeurs et exclusion d'un auteur (D8,
> `LL.GONE` côté client) : codés le 2026-10-02, pas publiés. GitHub Action (D6) : ACTIVE depuis le 2026-10-01 (une PR par ticket),
> essai de bout en bout vert sur un ticket de test (critère 11), pas encore sur un vrai ticket
> Cible : WoW: Forever / Camelot (16001) uniquement · Addon : Ley Line / Elemental Convergence Tracker (dossier `LeyLines`)
>
> Origine : premier commentaire sur la page CurseForge (2026-09-27) — un joueur demande où partager
> son `/ley export` pour « avoir la liste de toutes les lignes de Forever ».

## Le problème

Aujourd'hui, un joueur ne connaît que les failles qu'il a trouvées lui-même, plus les deux points de
Zephras Isle livrés avec l'addon. `/ley export` produit bien un code texte, mais rien ne le relie aux
autres joueurs : il le colle sur Discord, dans un commentaire, et la trouvaille s'arrête là. Chaque
joueur refait la même exploration.

Trois défauts de l'existant empêchent de brancher un recueil tel quel :

1. **Un export renvoie la liste reçue à l'identique.** `Share:Encode` exporte TOUTE la base, y
   compris les points livrés et importés. Un joueur qui réexporte la liste qu'il a reçue la
   « confirme » sans être allé nulle part. C'est le même piège que l'infobulle qui relisait notre
   propre texte (v1.0.0) : un canal partagé finit par relire ce que l'addon y a lui-même écrit.
2. **Un point ne sait pas quel objet il est.** L'Alliance absorbe une **fissure au sol** (Ley Line,
   sort Skyborn), la Horde une **tornade** (Elemental Convergence, sort Skysight) : même mécanisme,
   objets différents, à des endroits différents. Or `Nodes:Label` tire le nom de la faction de CELUI
   QUI REGARDE, l'anti-doublon fusionne deux points à moins de `mergeRange` quelle que soit leur nature, et
   `LL.DATA` part chez les deux factions. La base est au niveau du compte : un joueur qui a des
   personnages des deux côtés mélange déjà les deux.
3. **Effacer ne laisse aucune trace.** `/ley del` retire le point, sans rien retenir. Impossible donc
   de dire aux autres « celle-ci n'existe plus ».

## Ce qu'on veut

**Côté joueur.** Une commande `/ley contribute` (alias `/ley contribuer`) ouvre la fenêtre de
partage avec un **lien** déjà sélectionné. Le joueur le copie (Ctrl+C), le colle dans son navigateur,
et tombe sur le formulaire « Share positions » du dépôt GitHub, **déjà rempli**. Il n'a plus qu'à
cliquer sur *Submit*. Le lien ne contient que ce que CE joueur a observé lui-même depuis sa dernière
contribution : les failles et tornades confirmées par le jeu, et les points qu'il a effacés sur place.

**Côté dépôt.** À l'ouverture du ticket, une GitHub Action le passe au garde-fou, le verse, et
pousse **une branche par ticket** (`feat/positions-gh-NNNN`, plus une PR si le dépôt le permet),
avec son rapport : chaque point, le point connu le plus proche, son verdict, et les drapeaux à
relire. Le mainteneur relit, passe les portes et les tests de l'outillage, fusionne, puis publie
une release. L'Action ne commente pas le ticket (D6).

**Pour tout le monde.** À la mise à jour, chaque joueur reçoit les nouveaux points de SA faction, et
les points livrés déclarés disparus s'effacent de sa carte. Ses propres relevés ne sont jamais
déplacés ni effacés par une donnée reçue.

`/ley export` / `/ley import` restent l'échange de joueur à joueur (un ami, une guilde), et portent
désormais l'espèce de chaque point.

## Ce qu'on NE fait PAS

- **L'addon ne poste rien.** WoW ne donne aucun accès réseau aux addons, ni HTTP ni navigateur. Le
  lien pré-rempli est ce qui s'en approche le plus.
- **Pas de Discord ni d'autre canal de recueil** (D1). Un joueur sans compte GitHub colle son code en
  commentaire CurseForge, et le mainteneur ouvre le ticket à sa place : même format, même pipeline.
- **Pas de JSON ni de Lua produit en jeu.** Le transport reste un texte compact (`LL2`), parce que ce
  même texte doit pouvoir se réimporter en jeu. Il faudrait sinon un lecteur JSON dans l'addon. La
  conversion en Lua se fait une fois, dans l'Action.
- **Pas de merge automatique.** Ce que compile l'Action finit dans le client de chaque joueur :
  un humain relit la branche, toujours. L'Action ne fusionne, ne tague, ne commente ni ne ferme rien.
- **Pas de preuve automatique de disparition par le buff court.** Un lancer qui rend le buff de 15 s
  à côté d'un point connu est bien un verdict du jeu, mais un point livré peut être décalé de
  quelques yards : on ne peut pas conclure « disparu » de façon sûre. Piste pour plus tard.
- **Pas de carte web publique.** La liste compilée la rendrait possible ; hors périmètre.

## Cas particuliers

- **Relevé manuel à plus de `mergeRange` (50 yd) de la vraie faille** (au-delà de l'anti-doublon) → le lancer
  réussi ABSORBE le point « à confirmer » de même espèce le plus proche dans un rayon de 60 yd (le
  rayon de `/ley del`) : le point se déplace sur la position du lancer et passe en `spell`. Sans
  ça, le point gris resterait à côté, et `/ley del`, qui prend le plus proche, risquerait d'effacer
  le bon.
- **Lancer du bord de la portée** → vu en jeu le 2026-09-29 (rapporté par le user) : le buff long
  se donne jusqu'à ~25 yd de la fissure. Un lancer à 22 yd d'un point posé pile dessus créait un
  DOUBLON avec l'anti-doublon de 20 yd, et le signal puis la liste commune l'auraient propagé.
  Deux lancers réussis d'une même fissure peuvent être à 2 × 25 = 50 yd : `mergeRange` passe à
  **50 yd** (migration `schemaVer` 4), et à précision égale **le premier point reste**
  (un lancer confirme sans déplacer). Contrepartie acceptée : deux vraies fissures à moins de
  100 yd, absorbées par leurs bords qui se font face, peuvent fusionner (une seule paire connue,
  à 73,5 yd ; simulé : ~8 % des cas avec des lancers au hasard dans la portée). Un doublon, lui,
  partait chez tout le monde sans moyen de le retirer.
- **`/ley del` sur un point `manual` ou `tooltip`** → pas de retrait à contribuer : ce point
  n'était jamais parti vers la liste.
- **Rien de neuf depuis la dernière contribution** → message « rien de neuf à partager », pas de
  lien. `/ley contribute all` renvoie tout ce que le joueur a observé lui-même.
- **Lien trop long** (au-delà d'environ 6000 caractères, GitHub refuse l'adresse) → la fenêtre montre
  un lien court sans code, et le bouton « Code » donne le code : le joueur le colle dans le champ.
- **Joueur à deux factions** → chaque point porte son espèce ; la contribution les mélange sans les
  confondre.
- **Même contribution envoyée deux fois** → sans effet : les mêmes points se fusionnent, aucun
  doublon.
- **Retrait d'un point jamais livré** → sans effet sur la liste.
- **Objet absent à un passage, revenu ensuite** → une absence vue une fois n'est PAS un retrait.
  Vu en jeu le 2026-09-28 (registre, relevé de 19:25) : une tornade des Tarides absente, revenue
  au même endroit dans la soirée ; cause inconnue (serveur de la bêta, réapparition après
  absorption, couche). **Tranché le 2026-10-02 (D7)** : un retrait n'entre dans `LL.GONE` que
  signalé par deux joueurs différents, ou par celui qui a posé le point. Sinon un simple décalage
  de réapparition effacerait l'objet chez tout le monde à la mise à jour suivante.
- **Deux contributions contradictoires** (l'une ajoute, l'autre retire au même endroit) → la plus
  récente l'emporte, par date du ticket.
- **Ticket édité** → ignoré : la branche fige le code qui a été relu. Pour retraiter un ticket, le
  relancer à la main (Actions → « Positions ticket » → *Run workflow*, numéro du ticket).
- **Ticket malveillant.** Le contenu du ticket est une entrée non fiable, et ce qui en sort finit en
  Lua exécuté par chaque client. Le décodeur n'accepte que la grammaire du contrat (chiffres,
  `L`/`V`, séparateurs). Tout le reste est jeté, et aucun caractère du ticket n'est recopié tel quel
  dans le fichier généré. Côté Action (D6), le garde-fou `tools/ll_guard.lua` ne garde du ticket
  que le jeton `LL2`, réécrit en code canonique : un fichier de sauvegarde (du Lua à évaluer) ou un
  code `LL1` ne passent jamais par elle, ils sont versés à la main.
- **Code sans espèce reçu** (`LL1` d'un build antérieur, ou segment `LL2` sans lettre) → refusé à
  l'import, avec un message qui demande un nouvel export. Le décodeur le lit encore, pour
  l'instantané interne d'une vieille base, restauré en fissures (A4).
- **Client plus ancien qui reçoit un code `LL2`** → « code invalide ». Accepté : il doit mettre à
  jour.
- **Carte dont la taille n'a jamais été transmise** → points gardés, mais le dédoublonnage en yards
  est impossible : le rapport de l'Action donne alors l'écart en unités de carte.

## Décisions

- **D1 — 2026-09-27, user** : GitHub est le seul point de recueil. Pas de Discord.
- **D2 — 2026-09-27, user** : un seul contributeur suffit pour qu'un point entre dans la liste.
  Justification : un point livré est de basse précision et ne déplace jamais un relevé du joueur,
  donc une erreur coûte au pire un trajet pour rien, et la PR est relue.
- **D3 — 2026-09-27, user** : une contribution peut dire qu'un point n'existe plus.
- **D4 — 2026-09-27, user** : Alliance = fissures au sol (Ley Line), Horde = tornades (Elemental
  Convergence — nom relevé par le client, compte #4). Même mécanisme, objets différents →
  **l'espèce est une propriété du point**, jamais déduite de celui qui regarde.
  Précisé par le user le même jour : **chaque faction ne peut absorber que SON objet** (Skysight ne
  part pas sur une ley line). L'espèce d'une capture au sort ou manuelle est donc la faction du
  personnage, sans rien deviner ; seuls une infobulle ou une vignette se fient au nom lu. Et chaque
  message nomme l'objet de la faction du joueur (« Short buff: no elemental convergence here »).
- **D5 — 2026-09-27, contrainte technique** : l'addon fabrique un lien, il ne poste pas.
- **D6 — 2026-10-01, user** : l'Action prépare **une branche par ticket**, « que tu as juste à
  check et à incorporer après », avec des vérifications contre les malins. Elle remplace la PR
  unique et le commentaire prévus au départ. Précisé avec l'agent le même jour :
  - **Refuse** seulement ce qu'une machine tranche sans se tromper : pas de jeton `LL2` (fichier
    de sauvegarde, `LL1`, rien), pseudo hors `[A-Za-z0-9-]`, plus de 40 points, ticket de plus de
    20 000 octets, numéro de carte impossible, code identique à une contribution déjà versée, plus
    de 20 tickets du même auteur en 24 h.
  - **Signale** le reste, sans refuser : compte GitHub de moins de 30 jours, plus de 5 tickets en
    24 h, premier ticket de l'auteur, fissures et tornades mêlées, plus de 10 points, carte jamais
    vue, point sur le bord de la carte, aucun point qui recoupe la liste. Raison : ces signaux
    visent aussi de vrais joueurs. Un compte ouvert pour l'occasion est la norme, et sionnabhan a
    envoyé cinq tickets légitimes en trois heures (#11 à #15).
  - **Pas de commentaire** sur le ticket : le mainteneur répond lui-même. **Ticket édité** :
    ignoré. Le rapport est public, comme tout le dépôt : il s'en tient aux faits, et ne cite
    jamais le ticket par « #N » (GitHub accrocherait sinon le rapport et ses drapeaux à la page du
    ticket, sous les yeux du joueur).
  - **Rien ne prévient le mainteneur** : ni une branche poussée, ni un run refusé (déclenché par un
    inconnu). Il faut une relecture : la veille de session, devenue « relire » (voir T5).
  - **Ce que la CI ne vérifie pas** : l'outillage (portes, tests headless) vit dans un dépôt privé.
    Une Action verte prouve seulement que le code lu est propre et que la liste générée se charge
    (`luac -p` + chargement). Les portes et les tests se passent en local, avant la fusion.
- **D7 — 2026-10-02, user** : un retrait n'entre dans `LL.GONE` que **signalé par deux joueurs
  différents**, **sauf si c'est la personne qui a posé le point** : son retrait seul suffit.
  Proposé par l'agent (deux joueurs), précisé par le user. Raison : une absence vue une fois n'est
  pas une preuve (tornade des Tarides absente puis revenue le 2026-09-28), mais celui qui a mis un
  faux point dans la liste doit pouvoir le retirer sans attendre un second témoin. Précisions de
  l'agent, à relire :
  - « celui qui a posé le point » = l'auteur (`from=`) de la contribution qui l'a INTRODUIT dans la
    liste (son premier palier), pas celui d'une simple confirmation ;
  - « deux joueurs différents » = deux `from=` distincts parmi les retraits qui tombent sur le même
    objet (même rayon que la fusion des ajouts : 50 yd, 0,01 de carte sans taille connue) ;
  - un ajout plus récent au même endroit le fait revenir (cas « deux contributions
    contradictoires ») ;
  - le clic droit sur la grande carte (`feat/effacer-clic`) et `/ley del` passent par le même
    `LL:DeleteNode` : c'est là que `db.gone` s'inscrira.
- **D8 — 2026-10-02, user** : « un registre au moins local des gens et de leur contribution : si
  un jour on remarque un fraudeur, il faut pouvoir retirer et contrôler ses points ». Venu du
  ticket 29 (8 tornades d'un compte ouvert le jour même, aucun recoupement). Mis en œuvre par
  l'agent le même jour (branche `feat/registre-contributeurs`, LeyLines et outillage) :
  - **le registre se déduit**, il n'est pas stocké : chaque `data/contrib/<id>.ll` porte son
    auteur (`from=`). `ll_ingest.ps1 -Registre [-Auteur x]` dit, par auteur, chaque point posé,
    qui l'a relevé aussi, chaque confirmation, et ce que son exclusion retirerait. Un fichier
    généré et commité aurait été réécrit par chaque branche de ticket (le piège de
    `LeyLines_Data.lua`) ;
  - **l'exclusion est commitée** : `data/exclus.txt`, `<pseudo> <palier> <date>`, lu par
    `ll_ingest.lua build` lui-même, parce que l'Action reconstruit la liste à chaque ticket. Une
    exclusion qui ne vivrait que sur un poste serait défaite par la PR suivante. Faits seulement,
    pas de motif : le dépôt est public ;
  - **exclure** = ignorer toutes ses contributions (le `.ll` reste, pièce du dossier). Un point
    qu'il a posé et qu'un AUTRE auteur a relevé reste, au palier de cet autre. Un point dont il
    était le seul témoin part dans `LL.GONE`, au palier de l'exclusion, et le client l'efface chez
    ceux qui l'avaient reçu (`Nodes:ApplyGone`, A3 : jamais un relevé du joueur). Il quitte
    `LL.THANKS`. Le garde-fou de l'Action REFUSE ensuite ses tickets ;
  - **une confirmation n'est pas une preuve** : deux comptes neufs peuvent se confirmer l'un
    l'autre. Le registre montre qui a confirmé, le mainteneur juge ;
  - **le palier de l'exclusion** est au-dessus de la liste du moment (`-Exclure` le prend) : sans
    lui, `DATA_VERSION` ne bougerait pas et un client à jour ne relirait jamais les retraits. Même
    règle qu'une branche de ticket : s'il est déjà distribué au moment de la fusion, reprendre ;
  - **limite connue** : lever une exclusion (effacer sa ligne) remet ses points dans la liste à
    leurs paliers d'origine, donc seulement chez les nouveaux joueurs ; pour les rendre à tous,
    reverser ses contributions sous un palier neuf. Et un client d'avant cette version ignore
    `LL.GONE` : un retrait ne touche que les joueurs à jour.
  Ce n'est PAS le retrait signalé par un joueur (D7, T4 étape 1) : celui-là reste à faire, et
  réutilisera `LL.GONE` et `Nodes:ApplyGone`.

## Arbitrages — proposés par l'agent, validés par le user le 2026-09-27

- **A1 — Affichage filtré par faction.** Un personnage Alliance ne voit que les fissures, un
  personnage Horde que les tornades. Les deux restent dans la base du compte. Raison : l'objet de
  l'autre faction ne s'absorbe pas, l'afficher n'ajoute que du bruit.
- **A2 — Une contribution ne porte que ce que le jeu a confirmé** : captures par sort (buff long) et
  par vignette. Les relevés manuels (`/ley add`) restent dans la base du joueur mais ne partent pas
  vers la liste commune. Raison : D2 n'est tenable que si chaque point entrant a été tranché par le
  jeu.
  **Complément du user** : un point à confirmer doit se VOIR. Un relevé `manual` ou `tooltip`
  s'affiche dans une couleur distincte « à confirmer » (minicarte, carte du monde, bandeau), et son
  infobulle dit quoi faire : y revenir et lancer le sort. Un lancer réussi dessus le fait passer en
  `spell` : couleur normale, et il devient contribuable. Les points `import` et `shipped` ne sont pas
  colorés : ils viennent d'autres joueurs, et la liste livrée n'est faite que de captures confirmées.
- **A3 — Un retrait livré n'efface jamais un relevé du joueur.** Il n'efface que les points
  `shipped` et `import`. Même logique que `PRECISION` : une donnée reçue comble un trou, elle ne
  corrige pas une vérité locale.
- **A4 — Migration des points existants** : `V` si leur nom contient « vergence », `L` sinon.
  **Affiné le 2026-09-27 à la relecture du tag `v1.0.0`** (demande du user : les données du premier
  contributeur ne doivent pas être corrompues) : la v1.0.0 capturait AUSSI côté Horde, via
  `/ley learn` + Skysight, et inscrivait alors le buff Horde (1270893) dans `auras`. D'où : base
  rendue par le client SANS ce buff → `L` (certain) ; AVEC → faction du personnage qui la charge
  en premier (juste pour un compte d'une seule faction). Et avant tout classement, une copie texte
  de la base telle quelle (`db.legacy`), jamais réécrite : aucun classement ne peut rien perdre.
  **Amendement essayé puis RETIRÉ le 2026-09-27.** L'agent avait remplacé « `L` sinon » par une
  espèce « inconnue, visible des deux factions », pour épargner les deux captures Horde SANS nom de
  la base de développement #4. Testé en jeu le jour même : ces deux points, exportés sans espèce,
  s'affichaient en « Ley Line » dans les Tarides chez un personnage Alliance — le défaut même que
  la fonctionnalité doit supprimer. Retour à A4 tel que validé, plus une règle : **un point sans
  espèce ne s'importe pas** (code `LL1`, ou `LL2` exporté avant correction). Les captures Horde sans
  nom d'une base de développement se rattachent une fois à la main.

## Critères d'acceptation

1. [test] Un code `LL2` encodé puis décodé rend les mêmes points, espèces et retraits compris ; un
   code `LL1` se décode encore. → `tests/test_leylines.lua`
2. [test] Un point `L` et un point `V` à 5 yd l'un de l'autre restent DEUX points.
3. [test] La contribution exclut les sources `shipped`, `import`, `restored`, `tooltip` et `manual`
   (A2). Elle n'inclut que les observations et les retraits postérieurs à la précédente.
   → `tests/test_leylines.lua` § 17 (sources), `tests/test_leylines_contribute.lua` (« postérieurs »,
   hors retraits ; codé le 2026-09-28, branche `feat/signal-contribution`)
3b. [test] Un lancer réussi à 40 yd d'un point `manual` de même espèce le déplace et le fait passer
   en `spell`, sans créer de second point ; à 40 yd d'un point `manual` de l'AUTRE espèce, il crée
   un point à part.
4. [test] Un point confirmé par une fusion de données livrées n'est PAS considéré comme revu : il ne
   repart pas dans la contribution suivante. → `tests/test_leylines_contribute.lua` § 3
5. [test] Un retrait livré efface un point `shipped` ou `import` voisin, et laisse un point `spell`
   (A3). → `tests/test_leylines_gone.lua` (2026-10-02, D8).
6. [test] Compilation : ajout (#12) puis retrait (#15) au même endroit → absent ; retrait puis ajout
   → présent.
7. [test] Compilation : un ticket contenant autre chose que la grammaire (`]] os.exit() --`,
   guillemets, retours à la ligne) ne produit AUCUN caractère hors chiffres, virgules et accolades
   dans `LeyLines_Data.lua`.
8. [porte] Les quatre portes passent ; chaque chaîne nouvelle est dans les overlays enUS, deDE et
   esES. → `deploy.ps1`
9. [humain] `/ley contribute` sur un personnage qui a capturé par sort → la fenêtre montre un lien
   sélectionné ; collé dans un navigateur connecté à GitHub, il ouvre le formulaire avec le champ
   « code » rempli. Témoin connu-bon : `/ley export` de la même version, qui montre un code dans la
   même fenêtre. Observateur : le user.
10. [humain] Sur un compte avec un personnage de chaque faction, le personnage Alliance ne voit sur sa
    minicarte aucune tornade capturée par le personnage Horde (A1). Témoin connu-bon : la v1.1.0,
    qui les montre. Observateur : le user, à 2 personnages.
10b. [humain] Un `/ley add` pose un point dans la couleur « à confirmer », distincte d'un point
    capturé par sort sur la même minicarte ; après un lancer réussi dessus, il reprend la couleur
    normale. Témoin connu-bon : un point `spell` voisin. Observateur : le user, en jeu.
11. [humain] Pour un ticket de test, l'Action pousse une branche `feat/positions-gh-NNNN` qui ne
    modifie que `LeyLines_Data.lua` et `data/contrib/gh-NNNN.ll`, avec le rapport du garde-fou
    dans son commit (et une PR si le dépôt l'autorise). Le ticket ne reçoit aucun commentaire.
    Un ticket refusé donne un run rouge et aucune branche. Observateur : le user, sur GitHub
    (D6, 2026-10-01).
12. [test] Exclure un auteur (D8) retire de la liste ses points sans autre témoin et les inscrit
    dans `LL.GONE` au palier de l'exclusion, garde ceux qu'un autre auteur a relevés, l'ôte des
    remerciements ; sans exclusion, la liste générée ne change pas d'un octet ; le garde-fou
    refuse son ticket. → `tests/test_ll_registre.lua`.
13. [humain] Sur un compte qui a reçu un point livré, un retrait qui le vise l'efface de la
    minicarte et de la grande carte ; un point relevé au sort par ce compte, visé de la même façon,
    reste. Témoin connu-bon : un autre point livré de la même zone, qui reste. Observateur : le
    user, au banc (le retrait se pose par `/run` sur `LeyLines.GONE`, la fiche de test dit comment
    et comment remettre `dataVersion` ; aucune exclusion d'essai ne se commite).

## Contrat

### Texte d'échange `LL2` (en jeu, et dans le ticket)

```
LL2;<segment>[;<segment>...]
segment := [-][<espèce>]<uiMapID>=<x>,<y>[,<x>,<y>...]
espèce  := L   fissure / Ley Line (Alliance)
         | V   tornade / Elemental Convergence (Horde)
         | (absente) pas d'espèce : lue par le décodeur, REFUSÉE à l'import
-       := retrait : « ces points n'existent plus »
x, y    := dix-millièmes de la carte, entiers 0..10000 (inchangé depuis LL1)
```

Exemple : `LL2;L2521=3537,3370,3881,4759;-L2521=5012,4410`. Segments triés, sortie stable.
Le décodeur jette point par point ce qui est douteux, comme `LL1` aujourd'hui.

**Livré en v1.1.0** (sauf le retrait) : la v1.1.0 écrit et lit `LL2`, lit encore `LL1`, et
**ignore** un segment de retrait ou d'espèce qu'elle ne connaît pas — un client v1.1.0 qui reçoit un
code v1.2.0 ne prendra jamais un retrait pour un ajout. Verrouillé dans `tests/test_leylines.lua`.

### Lien de contribution

```
https://github.com/Wafhi3n/LeyLines/issues/new?template=positions.yml
    &title=<« Positions: » + les zones du code, encodé en pourcent>   (signal-contribution.md, S5)
    &code=<LL2, encodé en pourcent>
    &maps=<uiMapID>:<largeur>x<hauteur>[,...]   tailles en yards, lues par C_Map.GetMapWorldSize
    &version=<LL.VERSION>
```

**Codé le 2026-09-28** (branche `feat/signal-contribution`, `Share:ContributeURL`) : `title` et
`code` seulement, et jamais `faction` (I2 de `signal-contribution.md`). `maps` et `version`
attendent un champ du formulaire où arriver. Encodage : tout octet hors `[A-Za-z0-9-._~]` passe en
`%XX`, les `;` et `=` du code compris.

`maps` existe parce que la CI ne peut pas appeler `C_Map` : sans la taille de la carte, elle ne
peut pas fusionner deux points à 50 yd. C'est le client qui la connaît, c'est donc lui qui la
transmet. Les identifiants `code`, `maps` et `version` sont ceux des champs du formulaire
`.github/ISSUE_TEMPLATE/positions.yml`.

### Base persistée

| Champ | Sens |
|---|---|
| `node.kind` | **Livré en v1.1.0, sans changer `schemaVer`** (posé par `Nodes:Init` à chaque chargement). `"L"` ou `"V"`, **toujours présent** : un point ancien le reçoit au chargement (A4). Fixé à la capture : faction du personnage pour un sort ou un relevé manuel (D4), nom lu pour une infobulle ou une vignette. |
| `node.seen` | **Codé le 2026-09-28** (branche `feat/signal-contribution`, pas publié). Dernière observation **confirmée par le jeu** (sort, vignette). Contrairement à `node.last`, une fusion de données livrées ou importées ne le touche pas. Un point confirmé d'une base plus ancienne reçoit son `last` au chargement. |
| `node.found` | **Codé le 2026-09-28** (même branche, P3 de `signal-contribution.md`). PREMIÈRE observation confirmée par le jeu, jamais déplacée : sert au signal des positions à partager, pas à la contribution. Un point confirmé d'une base plus ancienne reçoit son `seen`. |
| `db.gone[map]` | Retraits faits sur place par `/ley del` d'un point partageable (`spell`, `vignette`, `shipped`, `import`) : `{ x, y, kind, at }`. Pas `/ley clear` ni `/ley clean`, qui sont du ménage et pas une observation. |
| `db.contrib.at` | **Codé le 2026-09-28** (même branche). Date (`time()`) de la dernière contribution générée, posée à l'ouverture de la fenêtre ; une contribution vide (« rien de neuf ») ne la change pas. |
| `db.legacy` | **Livré en v1.1.0.** Copie texte (`{ at, blob }`) d'une base d'avant l'espèce, prise AVANT de lui donner ses espèces et jamais réécrite : si le classement A4 se trompe, rien n'est perdu. |

### Données livrées — `LeyLines_Data.lua`, **généré**

```lua
LL.DATA_VERSION = <n>
LL.DATA = { L = { [uiMapID] = { x, y, palier, ... } }, V = { ... } }   -- ajouts
LL.GONE = { L = { [uiMapID] = { x, y, palier, ... } }, V = { ... } }   -- retraits (A3)
```

**`LL.GONE` écrit depuis D8** (2026-10-02, branche `feat/registre-contributeurs`), seulement s'il a
des points : sans exclusion, le fichier généré ne change pas d'un octet. Aujourd'hui, seule une
exclusion d'auteur (`data/exclus.txt`) y met des points ; les retraits signalés par les joueurs (D7)
y viendront aussi. Côté client, `Nodes:ApplyGone` passe AVANT les ajouts dans `ApplyShipped` (un
point re-livré par la même mise à jour revient) : pour chaque retrait d'un palier pas encore reçu,
le point le plus proche de même espèce dans `mergeRange` s'en va s'il est `shipped` ou `import`.

**Livré en v1.1.0 : `LL.DATA` en triplets.** Le palier est le `DATA_VERSION` qui a introduit le
point ; `Nodes:ApplyShipped` ne fusionne que les points plus récents que la dernière fusion du
joueur. Avant, chaque livraison recopiait la liste ENTIÈRE : un point effacé exprès revenait à
chaque release de données.

Le fichier n'est plus écrit à la main : `tools/ll_ingest.lua` le produit à partir de
`data/contrib/<id>.ll` (une contribution par fichier : `from`, `date`, `source`, `version`, `code`
en LL2), qui sont la source de vérité (et le registre des contributeurs, D8). Retirer UN ticket
qui n'est jamais parti = supprimer son fichier et régénérer ; retirer un AUTEUR, ou un point déjà
livré = l'exclure (`-Exclure`, D8). Les deux points de Zephras Isle sont la contribution `seed-zephras` (palier 2).
`.pkgmeta` ignore `data`, `tools` et `.github`.

### Pipeline v1 — outillé mais à la main (v1.1.0)

Décidé le 2026-09-27 avec le user : un seul contributeur pour l'instant, donc pas encore d'Action.

```
joueur   /ley contribute  →  code LL2 (sort + vignette seulement, A2)
           ↓ formulaire .github/ISSUE_TEMPLATE/positions.yml (code ; faction facultative, I2 de
             signal-contribution.md : le code porte déjà l'espèce de chaque point)
nous     .\scripts\ll_ingest.ps1 -Issue <n>          (ou -Code / -SavedVariables, voir l'en-tête)
           → data/contrib/<id>.ll, puis LeyLines_Data.lua régénéré, rapport par contribution
toi      relire le diff, 4 portes, commit, release
```

Trois entrées, parce que le premier contributeur est resté en v1.0.0, sans export :
- **code `LL2`** : le cas normal ;
- **code `LL1`** : accepté seulement avec `-Faction` (un point sans espèce ne se devine pas) ;
- **fichier de SavedVariables** d'un joueur : c'est du CODE venu d'un inconnu. Il est filtré avant
  toute évaluation (tables seulement : ni parenthèse, ni `:`, ni `..`, ni mot-clé ; pas de
  bytecode ; 2 Mo au plus), puis évalué dans un environnement vide, sans méthodes de chaîne, sous
  un plafond d'instructions. N'en sort que ce que le jeu a tranché (sort, vignette) ; une vieille
  base qui a capturé côté Horde exige `-Faction`.

Le dédoublonnage de l'outil suit la règle du client (50 yd, `schemaVer` 4) : en yards pour les zones dont
il connaît la taille (`MAP_YARDS` dans `tools/ll_ingest.lua`, relevée en jeu : Zephras Isle
seulement), sinon ~0,01 d'écart de carte. Toute fusion au-delà de la portée du sort (25 yd), ou
sur une zone de taille inconnue, sort en « A RELIRE » : c'est au relecteur de trancher entre la
même fissure et deux voisines. Le client refusionne de toute façon à `mergeRange` en appliquant la
liste.

### Pipeline v2 — l'Action prépare, le mainteneur relit (D6, 2026-10-01)

```
joueur   ticket « Share positions » (étiquette positions)
           ↓ .github/workflows/positions.yml (issues: opened/reopened, ou relance à la main)
Action   .github/scripts/positions.sh, depuis main :
           déjà versé sur main, ou branche déjà poussée ? → rien
           tools/ll_guard.lua : jeton LL2 seul → code canonique, refus ou drapeaux, rapport
           tools/ll_ingest.lua add (le CODE CANONIQUE, jamais le corps du ticket) + build
           luac -p + chargement de la liste ; seuls LeyLines_Data.lua et data/contrib/gh-NNNN.ll
           ont bougé → branche feat/positions-gh-NNNN poussée (+ PR si le dépôt l'autorise)
toi      relire le rapport, portes + tests en local, palier > DATA_VERSION de main, fusion, release
```

Un refus fait échouer le run (rouge dans l'onglet Actions) avec le rapport dans le journal : un
ticket ouvert sans branche ni contribution sur `main` est soit refusé, soit en attente. Le relire en
local, sans rien pousser : `ISSUE=<n> DRY_RUN=1 LUA=… LUAC=… bash .github/scripts/positions.sh`.

**Le palier vieillit.** Une branche reçoit `DATA_VERSION de main + 1` à sa création. Si une
release part sans elle, son palier est déjà distribué, et `ApplyShipped` sauterait ses points chez
tous les joueurs à jour, sans erreur nulle part. À la fusion, un palier qui n'est pas strictement
plus grand que le `DATA_VERSION` de `main` se reverse (`ll_ingest.ps1 -Issue <n>` sur `main`).
**Le fichier généré se régénère après TOUTE fusion qui le touche, conflit ou pas.** Plusieurs
branches dans la même release donnent souvent un conflit sur `LeyLines_Data.lua` ; mais une fusion
qui passe sans conflit n'est pas pour autant juste. Vu le 2026-10-01 en fusionnant `main` dans
`feat/contributeurs` : git a gardé le `LL.THANKS` de la branche et perdu, sans rien dire, les
remerciements des paliers 10 à 15. Donc : fusionner, `ll_ingest.ps1 -Build`, et le diff qui en sort
se commite. Une PR du bot se fusionne de la même façon, en local, jamais par le bouton de GitHub
quand une autre a été fusionnée depuis sa création.

## Renvois

- Skill **leylines-addon** : capture par durée du buff, piège de l'infobulle qui se relisait.
- `docs/verif-registre.md` : les critères [humain] s'y consignent une fois observés, et seulement
  alors.
- `CLAUDE.md` racine : un test de `tests\` qui exerce ce code ne va pas sur `master` avant que la
  fonctionnalité atterrisse sur `main` de LeyLines.

## Plan — 2026-09-27 (volatile, à rayer au fil de l'eau)

- **T0 — v1.1.0.** ~~Publier telle quelle~~ : le test d'aller-retour à 2 comptes du 2026-09-27 a
  reproduit le défaut d'espèce (tornades Horde affichées en « Ley Line » chez le gnome). Le format
  d'échange n'ayant jamais été publié, c'était le seul moment où le changer ne coûtait rien : la
  v1.1.0 embarque donc l'espèce (T1 partiel + T2, branche LeyLines `feat/espece-des-points`).
  Reste avant le tag : refaire l'aller-retour en jeu sur cette branche (base du gnome vidée),
  `CHANGELOG.md` et `CURSEFORGE.md` à jour, `.toc` à la main (`bump_version.ps1` ne connaît que COC).
  Libellé « Elemental Convergence » : FAIT (nom relevé sur le client). Côté sort, rien à changer :
  `/ley learn` sur Horde retient **1270893**, déjà livré en dur.
- **T1** — ~~espèce, anti-doublon et affichage par espèce (A1), A4~~ (v1.1.0) ; reste pour la
  v1.2.0 : ~~`seen`~~ (codé le 2026-09-28, P1 de `signal-contribution.md`), `gone`, couleur
  « à confirmer » et absorption par le lancer (A2). Critères 3b, 10b.
- **T2** — ~~Codec `LL2`, lecture `LL1` gardée ; `/ley export` passe en `LL2`~~ (v1.1.0). Critère 1,
  hors retraits.
- **T3** — ~~`/ley contribute` : filtre (A2)~~ (v1.1.0, code à coller) ; ~~le lien pré-rempli et
  le cas « trop long »~~ (codés le 2026-09-28 par `signal-contribution.md` P1-P2, avec le titre
  pré-rempli ; pas publiés). Critère 3 → le test ; critère 9 vu en jeu (ticket #2, registre). Constat
  du même jour : le formulaire publié n'a que `code`, `faction` et `notes`, donc les paramètres `maps`
  et `version` du § Lien de contribution n'ont pas encore de champ.
- **T4** — ~~`LL.DATA` par espèce, en triplets avec palier~~ (v1.1.0) ; reste `LL.GONE` et les
  retraits dans `ApplyShipped` (A3). Critère 5. Règle de confirmation tranchée (D7, 2026-10-02).
  Découpage proposé, dans cet ordre : (1) client, `LL:DeleteNode` inscrit `db.gone` pour un point
  partageable, `/ley contribute` y ajoute les segments `-` postérieurs à la dernière contribution ;
  (2) `ll_ingest.lua` lit les retraits (aujourd'hui jetés par `FromCode`), applique D7 et écrit
  `LL.GONE` en triplets avec palier ; le garde-fou les montre dans son rapport ; (3) client,
  `ApplyShipped` efface les points `shipped`/`import` voisins d'un retrait livré, jamais un
  relevé du joueur (A3). Chaque étape a ses tests ; (3) se voit au banc.
  **2026-10-02, par D8** : l'étape (3) est CODÉE (`Nodes:ApplyGone`, `tests/test_leylines_gone.lua`)
  et `LL.GONE` s'écrit, nourri pour l'instant par les seules exclusions d'auteur
  (`tools/ll_registre.lua`, `tests/test_ll_registre.lua`) ; branche `feat/registre-contributeurs`
  dans LeyLines et l'outillage, pas au banc. Restent (1) et la lecture des retraits de joueurs
  selon D7 dans (2).
- **T5** — ~~formulaire de ticket~~ (publié sur `main`, étiquette `positions` en place ; premier
  vrai ticket, #1 de wasdconnor, versé à la main le 2026-09-28 et vu en jeu : `gh-0001`, palier 3,
  voir le registre) ; ~~l'Action~~ codée le 2026-10-01 selon D6 (branche `feat/ci-tickets` dans
  LeyLines et dans l'outillage pour `tests/test_ll_guard.lua`), essayée à sec en local sur des
  tickets inventés. ~~Mise sur `main`~~ le 2026-10-01 (LeyLines `77c4426`, outillage `1288e73`) ;
  essai sur GitHub vert (relance à sec sur un ticket fermé : Lua 5.1 installé, `gh` autorisé) ;
  PR autorisées par le user le même jour. Essai de bout en bout le même soir, ticket de test 17
  (une fissure à 2 yd d'un point connu, une tornade inventée) : branche `feat/positions-gh-0017` et
  PR 18 avec le rapport (confirmation, neuf, deux drapeaux justes), aucun lien vers le ticket ; PR
  fermée sans fusion, branche supprimée. **Piège payé avant** : tant que le groupe de concurrence du
  workflow lisait `inputs.issue`, AUCUN événement de ticket ne créait de run (ni run ignoré, ni
  suite de vérification) alors que la relance manuelle marchait ; un workflow témoin minimal
  recevait, lui, les événements. Au niveau du workflow, seulement le contexte `github` (corrigé en
  `ca1cb43`). Reste : un vrai ticket. Aucun champ libre du ticket ne passe par `${{ }}`, seul son
  numéro.
- **T6** — ~~Compilateur `data/contrib/*.ll` → `LeyLines_Data.lua`~~ (v1.1.0, `tools/ll_ingest.lua`
  + `scripts\ll_ingest.ps1`, lancé à la main ; critères 6 partiel, 7 → `tests/test_ll_ingest.lua`) ;
  ~~la PR unique ouverte par l'Action~~ remplacée par une branche par ticket (D6, voir T5).
- **T7** — ~~Releases~~ (v1.1.0, v1.1.1, v1.2.0 publiées le 2026-09-27 ; la v1.2.0 est le
  compartiment d'addons, pas la contribution complète). Reste : la réponse au commentaire CurseForge
  (texte prêt, à poster par le user), et la release qui portera T1/T3/T4/T5 restants.
