# Registre de verification en jeu - LeyLines

Meme role que celui de Crafting Order - Classic : dire jusqu'ou l'addon a ete **vu fonctionner**
dans le client, puisque aucune porte automatique ne sait le dire. `scripts/untested.ps1 -Addon
LeyLines` fait l'union de tous les releves ci-dessous et liste ce qu'aucun n'avait dans le client.

Format d'un releve (le plus recent EN TETE) :

```
- AAAA-MM-JJ HH:MM - jusqu'a <sha> - <build> - <verdict> - <ce qui a ete observe>
```

Le `<sha>` est le dernier commit reellement present dans le client pendant la seance. On n'ecrit
un releve qu'APRES avoir observe, et on dit ce qui n'a PAS ete observe.

Depuis le 2026-09-28, le jeu ne recoit que le banc `main-dev` (CLAUDE.md de l'outillage) : le
`<build>` est la signature `## X-Build` du `.toc` deploye, et le repere est le dernier commit de la
BRANCHE eprouvee, pas la fusion `main-dev` (refaite a chaque release, et qui porte les branches des
autres sessions). Plusieurs sessions peuvent ecrire ici en parallele : l'heure plutot qu'un numero
du jour, et le fichier fusionne en `merge=union` (`.gitattributes`) sans conflit.

⚠️ **UN REBASE PERIME LE SHA D'UN RELEVE.** Vecu le 2026-09-27 : le releve Horde citait `93693eb`,
le commit d'AVANT la remise a niveau de sa branche. Apres rebase le meme travail s'appelle
`57d3908`, et `93693eb` n'est plus un ancetre de `main` -- `untested.ps1` reannonçait donc comme
JAMAIS EPROUVE un travail qui l'avait ete. Le script ne peut pas le voir : le vieux commit existe
toujours comme objet, sa verification d'existence passe. **Apres tout rebase d'une branche deja
couverte par un releve, avancer son sha** (`git log --oneline` sur la nouvelle branche donne
l'equivalent, le message est identique).

## Releves

- 2026-10-08 15:07 - jusqu'a 466daba - main-dev@21be437 2026-10-08 14:49 - Forever -
  **GO, sur la parole du user, coche dans l'appli du banc + capture d'ecran de la page** (fiche
  `LeyLines--feat-panneau-options`, 9 gestes sur 9 « Vu, OK », 15:03-15:07, client anglais) -
  branche `feat/panneau-options` : la page « Ley Line / Elemental Convergence Tracker » est dans
  Options > AddOns, deux colonnes, rien ne deborde (capture) ; decocher « Spots on the minimap »
  efface les points et `/ley` dit « Minimap off », `/ley pins on` recoche la case ; curseur du
  rappel sur 10 puis `/ley warn` : 10 ; `/ley warn 30` puis ouvrir la page : curseur au bout, et
  `/ley warn` dit toujours 30 ; infobulles ; « Contribute » ouvre sa fenetre PAR-DESSUS les
  options ; « Restore default settings » + Yes : taille des points revenue a 16 ; `/ley options`
  ouvre la page, `/ley` finit sur la ligne qui la rappelle ; mode Edition puis combat : aucun
  message a l'ecran. Defaut vu sur la capture et corrige ensuite (pas revu en jeu) : la fleche
  « → » du pied de page s'affichait en case vide (police du jeu sans le glyphe), remplacee par
  « > ». PAS observe : `taint.log` (pas ecrit depuis le 2026-10-06 ; avec `taintLog 1` le jeu ne
  note que les actions BLOQUEES, ce qui colle avec « rien de bloque », sans pouvoir l'exclure
  d'un journal qui ne tournait pas) ; le nombre de points avant/apres les defauts (case « avant »
  non cochee) ; les clients allemand et espagnol ; les boutons « Learn my spell », « Erase
  tooltip readings », « Export », « Import », « Reset tracker position ».
- 2026-10-08 14:47 - jusqu'a 6f0ed1f - main-dev@1a17336 2026-10-08 14:18 - Forever -
  **GO, sur la parole du user, coche dans l'appli du banc** (fiche
  `LeyLines--feat-point-de-route-option`, 6 gestes sur 6 « Vu, OK », 14:43-14:47) - branche
  `feat/point-de-route-option`, demande CurseForge du 2026-10-08 : `/ley help` liste `bug` et
  `waypoint` (fusion de la ligne d'aide avec `feat/bouton-ticket` au banc) ; `/ley warn 14`
  avec le buff : ligne de rappel avec la distance et AUCUN point de route ; `/ley waypoint on`
  puis `/ley warn 13` : point de route pose sur la plus proche ; `/ley waypoint off` puis
  `/ley track` : point de route pose quand meme (temoin) ; `/ley waypoint on`, `/reload`, puis la
  bascule affiche « desactive » (l'option allumee a tenu au rechargement). Geste
  « remplace-le-sien » coche OK mais SANS la reponse demandee : on ne sait toujours pas si le
  point de route de l'addon remplace celui du joueur (la phrase du code et du README reste
  « deduit de l'API »). PAS observe : le geste fait sur un client autre qu'anglais.
- 2026-10-04 20:50 - jusqu'a be83e84 - main-dev@4b4f3b7 2026-10-04 20:32 - Forever -
  **GO, capture du chat + « c'est tout bon » du user** - branche `feat/skyborne-seulement`, l'option
  elle-meme : `/ley skyborne` activee, sur un personnage d'une autre race que Skyborne, la ligne
  « Spots hidden on this character (not Skyborne): /ley skyborne to show them everywhere. » s'est
  affichee (LL:WarnHidden), et le user rapporte que l'option « fonctionne pour une race autre que
  skyborn ». PAS observe en detail : le detail par surface (minicarte, carte, bandeau), le
  Skyborne qui garde ses points avec l'option active, la commande qui a affiche la ligne, et le
  recalcul a `SPELLS_CHANGED`.
- 2026-10-04 20:40 - jusqu'a be83e84 - main-dev@4b4f3b7 2026-10-04 20:32 - Forever -
  **GO, captures du chat envoyees par le user** - branche `feat/skyborne-seulement`, le fait que
  le code supposait sans l'avoir lu : `/ley probe` sur deux personnages Skyborne, un par camp
  d'apres le user, a affiche `race : High Order Skyborne / Skyborne / 95 — absorbe oui (temoin :
  race), option skyborne non` (zone Zephras Isle, uiMapID 2521) et `race : Windshaper Skyborne /
  Skyborne / 96 — absorbe oui (temoin : race), option skyborne non` (carte Durotar, uiMapID
  1411). Donc deux races (ids 95 et 96), un seul jeton `Skyborne` : le temoin de race suffit des
  deux cotes, la crainte « cote Horde, aucun temoin » tombe. PAS observe : l'option elle-meme
  (`/ley skyborne` activee : points masques sur un personnage d'une autre race, gardes sur le
  Skyborne, ligne « Spots hidden » de `/ley`), le recalcul a `SPELLS_CHANGED`. Camp de chaque
  capture non verifie par moi.
- 2026-10-02 17:12 - jusqu'a 5e06b5c - main-dev@30f819e 2026-10-02 17:02 - Forever -
  **GO partiel, capture du chat envoyee par le user** - branche `feat/registre-contributeurs`,
  critere 13 de `contribution-positions.md`, cas « point livre » : pres d'une fissure de Zephras
  Isle, les deux `/run` de la fiche (retrait pose a la main sur `LeyLines.GONE`, puis
  `Nodes:ApplyShipped`) ont affiche `shipped 0.458 0.8071` puis `0 1` (0 ajout, 1 retrait), et la
  commande de restitution `rendu shipped`. Aucune erreur rapportee. PAS observe : la disparition
  du point sur la minicarte et la grande carte (non rapportee), le cas « releve au sort qui
  reste » (test headless seulement), la ligne de chat « retiree(s) de la liste commune », qui ne
  sort qu'a une vraie mise a jour.
- 2026-10-02 17:12 - jusqu'a 63af11e - main-dev@30f819e 2026-10-02 17:02 - Forever -
  **GO indirect, meme seance** - branche `feat/positions-gh-0025-0029` (tickets 25, 27, 29,
  palier 17) : le `/run` ci-dessus a rendu 0 ajout, donc `dataVersion` de ce compte etait deja a
  17 : la fusion de la liste au palier 17 s'est faite a la connexion. PAS observe : les lignes de
  chat (« 11 position(s) ajoutee(s) », « Merci a chris-rowley83, evellior, Noblesun13 »), ni les
  points neufs sur place.
- 2026-10-02 09:25 - jusqu'a b46421a - main-dev@2de61e8 2026-10-02 09:12 - Forever, build 70170 -
  **GO, rapporte par le user** - branche `feat/effacer-clic` : un point de la Marche de l'Ouest
  efface par clic droit sur la carte du monde, apres la popup de confirmation. « Sinon tout
  fonctionne » : reponse globale a la liste de controle donnee en session (infobulle des deux
  clics, « Non » qui ne fait rien, point absent apres `/reload`, clic gauche intact), pas point par
  point. L'effacement reste local : aucun retrait n'existe encore dans le code.
- 2026-10-02 09:25 - jusqu'a b837568 - main-dev@2de61e8 2026-10-02 09:12 - Forever, build 70170 -
  **GO, rapporte par le user, meme seance** - branche `fix/carte-zone` : comprise dans le « tout
  fonctionne » (vue continent et vue monde sans point, carte de zone avec), sans retour detaille.
- 2026-10-02 08:55 - jusqu'a 7be39f9 - main-dev@65ea7cc 2026-10-02 08:50 - Forever, build 70170
  (jour de patch) - **GO non-regression, rapporte par le user : « c'est good l'addon est ok »** -
  branche `fix/buff-torche`, deployee avec `fix/rayon-fusion` et `feat/contributeurs` (releves
  suivants), apres une liste de controle donnee en session (connexion sans erreur, ligne de
  remerciement, `/ley credits`, `/ley probe` ne citant que Energized et Elemental Blessing, lancer
  sur une ligne, au bord de la portee, loin de toute ligne). Le user a repondu globalement, pas
  point par point. PAS observe : la torche elle-meme (aucun personnage ne l'a) ; le faux point et
  l'alerte « 5 min » ne sont prouves corriges que par `tests/test_leylines_torche.lua`
  (contre-epreuve : 4 echecs sur l'ancien code).
- 2026-10-02 08:55 - jusqu'a d93e961 - main-dev@65ea7cc 2026-10-02 08:50 - Forever, build 70170 -
  **GO non-regression, meme seance** - branche `fix/rayon-fusion` (rayon de fusion 50 yd, le
  premier point reste). Le lancer au bord de la portee faisait partie de la liste de controle,
  sans retour detaille.
- 2026-10-02 08:55 - jusqu'a f54265b - main-dev@65ea7cc 2026-10-02 08:50 - Forever, build 70170 -
  **GO non-regression, meme seance** - branche `feat/contributeurs` (`/ley credits`, ligne de
  remerciement a la connexion). Contenu exact de la ligne et de la liste non rapporte.
- 2026-09-28 19:35 - jusqu'a 580c4d5 - main-dev@7a783a3 2026-09-28 18:36 - Forever, comptes #4 et
  #1 - **GO sur `/ley signal off` / `on` icone allumee, et sur « une position livree n'allume
  pas »** - rapporte par le user : l'icone allumee, `/ley signal off` la retire, `/ley signal on`
  la ramene. Compte #1 (Gnomi Short) : `/ley del` sur la fissure 46,26 / 17,78 puis lancer
  reussi, et PAS d'icone : la liste livree la contient depuis le palier 4 (`wafhien-zephras`,
  fusionnee dans cette base a 18:02:49, relu sur le disque), donc S3 / critere 1. Le del et le
  lancer eux-memes ne sont PAS relus sur le disque (bases non reecrites depuis 19:23:49 / 19:25:43).
  PAS observe : l'icone qui s'eteint AU MOMENT ou une livraison arrive (critere 4 : le clic de
  17:56:59 l'avait eteinte avant ; prouve par les tests seulement), la ligne de chat a l'allumage.

- 2026-09-28 19:25 - jusqu'a 580c4d5 - main-dev@7a783a3 2026-09-28 18:02 - Forever, compte #4,
  personnage Horde, Tarides - **GO sur le critere 8 de `signal-contribution.md`** (icone allumee
  par un VRAI lancer sur une position absente de la liste) - `/ley signal on` (signal coupe depuis
  la seance precedente), puis `/ley del` sur la tornade 49,80 / 28,58 et Skysight : relu sur le
  disque (base ecrite a 19:25:06), nouveau point `V` 1413 en 49,81 / 28,54, `spell`, `found` =
  `seen` = 19:24:42, posterieur a `contrib.at` (17:58:26) ; la liste livree n'a aucune tornade.
  Rapporte par le user : « le point est revenu et l'icone est la ». `signal = true` sur le disque.
  Au passage (rapporte) : une tornade des Tarides etait ABSENTE a un premier passage dans la
  soiree, puis revenue au meme endroit (cause inconnue : serveur, reapparition apres absorption,
  couche ; laquelle des deux, non precise) ; celle des
  Serres-Rocheuses (74,90 / 94,50) etait la. Consequence notee dans `contribution-positions.md` :
  une absence vue une fois n'est pas un retrait.
  PAS observe : la ligne de chat a l'allumage (question posee, non rapportee), `/ley signal off`
  puis `on` avec l'icone allumee, le survol et le clic sur cette icone-la.

- 2026-09-28 18:05 - jusqu'a d3b4673 - main-dev@7a783a3 2026-09-28 18:02 - Forever, compte #4 -
  **GO sur la fusion de la fissure `wafhien-zephras`** (liste livree palier 4,
  `feat/positions-wafhien-zephras`) - relu sur le disque (base ecrite a 19:25:06) : `dataVersion`
  3 -> 4, point `L` 2521 en 46,26 / 17,78, `shipped`, ajoute a 18:05:17, sans doublon.
  PAS observe : le compte #1, dont c'est la capture (base non reecrite depuis 18:00:31, encore au
  palier 3) ; l'icone de ce compte eteinte PAR la livraison (le clic de 17:56:59 l'avait deja
  eteinte : critere 4 prouve par les tests seulement) ; la carte du monde.

- 2026-09-28 17:58 - jusqu'a 580c4d5 - main-dev@580c4d5 2026-09-28 17:40 - Forever, comptes #4 et
  #1 - **GO sur l'icone de la minicarte et le signal** (P3-P4 de `signal-contribution.md`) -
  compte #4 : `/run LeyLines.db.contrib.at=0 LeyLines:Refresh()` -> icone dans la barre de la
  minicarte, « 3 » au survol, le clic ouvre la fenetre et l'eteint (rapporte ; `contrib.at` =
  17:42:26 relu sur le disque). Relancer apres `/ley del` sur la fissure de `gh-0001` : point
  reenregistre en 53,77 / 66,32 (`found` 17:47:37, disque), a 4 yd du point livre, et AUCUNE icone
  - voulu (S3, critere 1). Compte #1 (Gnomi Short) : icone presente des la connexion, sans ligne
  de chat (capture d'ecran du user) ; sa base porte la fissure 46,26 / 17,78, capturee au sort le
  2026-09-27, jamais partagee, absente de la liste ; clic a 17:56:59 (disque). Ticket #3 cree a
  17:58:42 depuis la contribution du compte #4 de 17:58:26 : titre et code pre-remplis (ferme sans
  versement). Taint : mode Edition et combat, aucune action bloquee (rapporte par le user ;
  `Logs\taint.log` date du 22/09, donc pas de journal pour le corroborer).
  PAS observe : la ligne de chat a l'allumage, `/ley signal off` puis `on` avec l'icone allumee
  (fait avec un compte a 0 : rien a ramener, conforme), les textes deDE / esES.

- 2026-09-28 16:18 - jusqu'a 67d12b4 - main-dev@67d12b4 2026-09-28 16:16 - Forever, compte #4 -
  **GO sur le lien pre-rempli de /ley contribute** (P2 de `docs/specs/signal-contribution.md`,
  critere 9 ; critere 9 de `contribution-positions.md`) - ticket GitHub #2 cree par le user a 16:18
  depuis le lien de la fenetre, relu par `gh issue view 2` : titre « Positions: Zephras Isle, The
  Barrens, Stonetalon Mountains » (3 zones, dans l'ordre du code) et champ Code
  `LL2;L2521=5375,6639;V1413=4980,2858,4848,4629;V1442=7490,9450` remplis par le lien, Faction
  « No response » (« Create » passe sans rien choisir, I2), etiquette `positions`. Le code est
  identique caractere pour caractere a celui de la 1re contribution (13:28, releve ci-dessous).
  Rapporte par le user : le bouton « Code » montre le code seul. Ticket ferme sans versement
  (essai). PAS observe : le repli « lien trop long » (tests seulement), le retour par « Lien », un
  nom de zone accentue dans un vrai titre (client enUS), les textes deDE / esES.

- 2026-09-28 13:41 - jusqu'a b224c0f - main-dev@b224c0f 2026-09-28 13:22 - Forever, compte #4 -
  **GO sur « /ley contribute n'envoie que le neuf »** (P1 de `docs/specs/signal-contribution.md`) -
  code colle par le user a la 1re contribution apres la mise a jour :
  `LL2;L2521=5375,6639;V1413=4980,2858,4848,4629;V1442=7490,9450`. Recoupe sur le disque (base
  ecrite a 13:27) : exactement les 4 points confirmes du compte, les 3 tornades au sort et une
  fissure de `gh-0001` passee de `shipped` a `spell` par un lancer du user (deplacee de ~6 yd, donc
  confirmee sur place) ; aucun des 5 points restes `shipped`. Migration vue : `seen` = `last` sur
  les 4 points confirmes, rien sur les points livres. Rapporte par le user : le 2e
  `/ley contribute` n'ouvre pas de fenetre et affiche « Nothing new since your last
  contribution... » ; `/ley contribute all` fonctionne. Relu sur le disque apres /reload (13:41) :
  `contrib.at` = 1790594887 (13:28), la date survit au rechargement.
  PAS observe : une capture faite APRES la contribution qui repart seule a la suivante, une liste
  livree qui recoupe un point sans le faire repartir (couverts par les tests seulement), le code
  de `all` compare caractere par caractere a celui de la 1re contribution, « Nothing to share »
  sur une base sans capture.

- 2026-09-28 12:38 - jusqu'a 03761ea - main-dev@03761ea 2026-09-28 12:10 - Forever, compte #4,
  personnage Alliance - **GO sur la premiere contribution par ticket** (ticket GitHub #1 de
  wasdconnor, verse par `ll_ingest.ps1 -Issue 1`, liste livree au palier 3) - relu sur le disque
  (base ecrite a 12:12) : `dataVersion` 2 -> 3, les 4 points de `gh-0001` presents sur 2521 en
  `shipped` / `L`, les 2 points de `seed-zephras` sans doublon. Capture d'ecran du user : la carte
  du monde de Zephras Isle montre les 4 nouveaux points aux positions du fichier. Deux d'entre eux
  (52,41 / 66,12 et 53,73 / 66,22) se chevauchent a l'ecran, pris d'abord pour un doublon : mesure
  en jeu `LeyLines.Geo:Distance` = 73,5 yd (carte 2521 = 5562,5 x 3708,3 yd), et vu sur place par
  le user : deux fissures reelles, une devant la grotte, une au-dessus. Lecon : sur la carte du
  monde, deux icones collees ne sont PAS un doublon ; la distance se mesure avec `Geo:Distance`.
  PAS observe : le message « 4 position(s) added from the shipped data » (non rapporte), le cote
  Horde (points `L` masques par A1), la minicarte, un lancer sur un des nouveaux points.

- 2026-09-27 - jusqu'a fb59d2f - Forever, compte #4 (Horde), client redemarre - **GO sur le
  compartiment d'addons** - captures du user : LeyLines figure dans le compartiment avec son icone.
  Sur Forever ce n'est PAS sur la minicarte : c'est le petit bouton « 2 » dans la barre en haut a
  droite, pres de l'horloge (`AddonCompartmentFrame` affiche, visible, strata LOW ; `IsTestBuild()`
  vrai sur la beta). Survol = infobulle de 4 lignes, « 3 elemental convergence(s) known in
  total. » ; rapporte par le user : clic gauche (contribution) et clic droit (bandeau) fonctionnent.
  Inscription par le .toc confirmee : 2 addons inscrits, metadonnee lue, etat d'activation 2 (All).
  PAS observe : un personnage active pour lui seul (etat 1), que Blizzard n'inscrit pas ; le clic
  gauche sans aucune capture (« Nothing to share »).

- 2026-09-27 - jusqu'a 7c22f03 - Forever, compte #1 (Joa), client redemarre - **GO sur le nom et
  l'icone** - capture d'ecran du user : la liste des addons affiche l'icone (TGA 64x64,
  `## IconTexture`) devant « Ley Line / Elemental Convergence Tracker », nette, au format des
  icones des autres addons. L'icone est un montage de deux icones du jeu fait par le user : il a
  choisi de la livrer telle quelle pour l'instant (repli possible : pointer une icone du client
  par son chemin, sans rien livrer).
  PAS observe : l'en-tete des raccourcis clavier et l'infobulle du bandeau sous le nouveau nom,
  le titre francais (client enUS).

- 2026-09-27 - jusqu'a d612768 - Forever, compte #1 (Joa-Joa, Alliance), base au format v1.0.0
  EXACT installee a la main (2 captures au sort dont une sans nom, 1 releve manuel, `auras` sans
  buff Horde) - **GO sur la conversion v1.0.0 -> v1.1.0 et sur /ley contribute** - rapporte par le
  user : « 1 position(s) added from the shipped data », puis `/ley contribute` =
  `LL2;L2521=3539,3372,5200,6100,4626,1778` : les 2 captures au sort + une capture faite pendant
  la seance, SANS le releve manuel. Relu sur le disque apres /reload : schemaVer 2 -> 3,
  dataVersion 2, `vergence` ajoute aux noms, copie `db.legacy` prise au 1er chargement (LL2 sans
  espece, les 3 points d'origine), tous les points en `L`, aucun perdu, la capture sans nom NON
  deplacee par le point livre voisin (hits 3 -> 4).
  PAS observe : la vieille base qui a capture cote Horde (buff 1270893 dans `auras`), couverte
  seulement par les tests ; aucune erreur Lua rapportee, sans releve explicite de BugGrabber.

- 2026-09-27 - jusqu'a 420b093 - Forever, 2 comptes sur le meme PC (#4 Horde, #1 Joa-Joa,
  personnage Alliance neuf), un client a la fois - **GO sur l'espece des points** - sur #4, apres
  rattachement a la main des 2 tornades SANS nom d'une base de developpement (`/run`, kind = V) :
  relu sur le disque, chaque point porte son espece et l'export vaut
  `LL2;L2521=3537,3370,3881,4759;V1413=4978,2879,4848,4629;V1442=7490,9450`. Base de Joa videe
  (fichier `LeyLinesDB = nil` a 16:25), puis import de ce code : rapporte par le user, « ca a l'air
  corrige » -- plus de « Ley Line » Horde dans les Tarides. Vu plus tot dans la meme seance : la
  tornade NOMMEE (V) disparait de la carte d'un personnage Alliance, et la carte du monde se
  rafraichit bien en changeant de zone (3 points puis 2, positions recoupees avec la base).
  Lecon de la seance : l'espece « inconnue, visible des deux factions » (8ba37a6) a ete vue en jeu
  reproduire le defaut, d'ou 420b093.
  PAS observe : le decompte de l'import cote Joa (base pas encore reecrite), le refus d'un code
  sans espece, les messages cote Horde (« no elemental convergence here »), `/ley list` et
  `/ley clear` par espece, la minicarte.

- 2026-09-27 - jusqu'a cb5f83b - Forever, 2 comptes sur le meme PC (#1 Alliance, #4 Horde), un
  client a la fois, code passe par le presse-papiers - **GO sur l'import, defaut d'espece
  REPRODUIT** - fichiers en jeu identiques au depot (compares octet a octet, fins de ligne mises a
  part). Import sur #4 d'un code contenant Zephras Isle (celui du gnome, selon le user) : relu sur
  le disque, les 2 points deja connus ont ete reconnus sans doublon, leur source est passee de
  `shipped` a `import`. Import sur #1 (gnome) du code de #4, rapporte par le user : il a cree des
  « Ley Line » dans les Tarides -- ce sont les tornades Horde, affichees sous le nom Alliance parce
  qu'un point ne porte pas son espece (voir `docs/specs/contribution-positions.md`). Rapporte
  aussi : `/ley learn` cote Horde retient 1270893, deja livre en dur.
  PAS observe : le message de decompte, la persistance cote #1 apres reconnexion (fichier de #1
  non reecrit au moment du releve).

- 2026-09-26 - jusqu'a 57d3908 - Forever, un client - **GO cote HORDE** - rapporte par le user :
  « ley line fonctionne cote horde ». Les vergences elementaires sont donc reconnues et capturees
  sur un personnage Horde, ce qui ne marchait pas du tout avant ce commit.
  PERIMETRE, ce qui n'a PAS ete departage par cette observation : on ne sait pas si le sort a ete
  reconnu par son **id** (1270893, pose en dur) ou rattrape par le **repli sur le nom**
  (`spellNames` / `Capture:LearnByName`) - les deux chemins finissent par une capture, et rien a
  l'ecran ne les distingue. Le libelle « Vergence elementaire » et la migration de schema v2 -> v3
  n'ont pas ete rapportes non plus. Pour departager le repli : `/ley` apres capture, ou relire
  `db.spells` dans la SavedVariable.
  ⚠️ L'avertissement « tes releves ne survivront pas » est encore INCONDITIONNEL dans ce build
  (`warnedNoSave`, LeyLines_Capture.lua) alors que les SavedVariables de Forever refonctionnent
  depuis le 2026-09-25 : s'il s'est affiche pendant la seance, c'est ce defaut, pas un symptome.

- 2026-09-20 - jusqu'a 8bc7a36 - Forever, un client - **GO sur le cycle de capture** - la capture
  par duree du buff `Energized` a ete vue fonctionner en jeu ce jour-la (v1.0.0).
  ATTENTION : **releve conservateur, reconstitue**. Sept commits ont suivi le meme jour (sort
  Skyborn en dur, correctif de lecture d'aura, export/import de positions, filet anti-perte de la
  base, sonde de chargement) et la seance ne les a pas departages un par un. Ils sont donc
  presumes NON eprouves : si la memoire dit le contraire, avancer le marqueur d'un cran, c'est
  une ligne a changer.
