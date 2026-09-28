# Contribution des positions (crowdsourcing)

> État : **validée, en cours** · Rédigée le 2026-09-27 · Décisions D1-D4 et arbitrages A1-A4
> tranchés par le user le 2026-09-27 (un amendement de A4 essayé puis retiré) · **Publié** : v1.1.0
> (espèce, `LL2`, `/ley contribute`, pipeline v1 à la main, liste générée en triplets), v1.1.1 (nom,
> icône), v1.2.0 (compartiment d'addons : clic gauche = contribute). Reste : lien pré-rempli,
> retraits (`gone`/`LL.GONE`), couleur « à confirmer », GitHub Action
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
   QUI REGARDE, l'anti-doublon fusionne deux points à moins de 20 yd quelle que soit leur nature, et
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

**Côté dépôt.** À l'ouverture du ticket, une GitHub Action le valide et y répond en commentaire
(« 12 points reçus, 3 nouveaux, 1 retrait »). Toutes les contributions validées sont compilées en
`LeyLines_Data.lua` dans **une seule PR**. Tu la relis et tu la merges, puis tu publies une release.

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
  un humain relit la PR, toujours.
- **Pas de preuve automatique de disparition par le buff court.** Un lancer qui rend le buff de 15 s
  à côté d'un point connu est bien un verdict du jeu, mais un point livré peut être décalé de
  quelques yards : on ne peut pas conclure « disparu » de façon sûre. Piste pour plus tard.
- **Pas de carte web publique.** La liste compilée la rendrait possible ; hors périmètre.

## Cas particuliers

- **Relevé manuel à plus de 20 yd de la vraie faille** (au-delà de l'anti-doublon) → le lancer
  réussi ABSORBE le point « à confirmer » de même espèce le plus proche dans un rayon de 60 yd (le
  rayon de `/ley del`) : le point se déplace sur la position du lancer et passe en `spell`. Sans
  ça, le point gris resterait à côté, et `/ley del`, qui prend le plus proche, risquerait d'effacer
  le bon.
- **`/ley del` sur un point `manual` ou `tooltip`** → pas de retrait à contribuer : ce point
  n'était jamais parti vers la liste.
- **Rien de neuf depuis la dernière contribution** → message « rien de neuf à partager », pas de
  lien. `/ley contribute all` renvoie tout ce que le joueur a observé lui-même.
- **Lien trop long** (au-delà d'environ 6000 caractères, GitHub refuse l'adresse) → la fenêtre montre
  le code seul et un lien court sans code : le joueur colle le code dans le champ.
- **Joueur à deux factions** → chaque point porte son espèce ; la contribution les mélange sans les
  confondre.
- **Même contribution envoyée deux fois** → sans effet : les mêmes points se fusionnent, aucun
  doublon.
- **Retrait d'un point jamais livré** → sans effet sur la liste.
- **Deux contributions contradictoires** (l'une ajoute, l'autre retire au même endroit) → la plus
  récente l'emporte, par date du ticket.
- **Ticket édité** → l'Action revalide et met à jour son commentaire.
- **Ticket malveillant.** Le contenu du ticket est une entrée non fiable, et ce qui en sort finit en
  Lua exécuté par chaque client. Le décodeur n'accepte que la grammaire du contrat (chiffres,
  `L`/`V`, séparateurs). Tout le reste est jeté, et aucun caractère du ticket n'est recopié tel quel
  dans le fichier généré.
- **Code sans espèce reçu** (`LL1` d'un build antérieur, ou segment `LL2` sans lettre) → refusé à
  l'import, avec un message qui demande un nouvel export. Le décodeur le lit encore, pour
  l'instantané interne d'une vieille base, restauré en fissures (A4).
- **Client plus ancien qui reçoit un code `LL2`** → « code invalide ». Accepté : il doit mettre à
  jour.
- **Carte dont la taille n'a jamais été transmise** → points gardés, mais le dédoublonnage en yards
  est impossible : l'Action le signale dans son commentaire.

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
   (A3).
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
11. [humain] Le ticket de test reçoit un commentaire de l'Action avec le décompte, puis une PR
    modifiant `LeyLines_Data.lua` apparaît. Observateur : le user, sur GitHub.

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
    &code=<LL2, encodé en pourcent>
    &maps=<uiMapID>:<largeur>x<hauteur>[,...]   tailles en yards, lues par C_Map.GetMapWorldSize
    &version=<LL.VERSION>
```

`maps` existe parce que la CI ne peut pas appeler `C_Map` : sans la taille de la carte, elle ne
peut pas fusionner deux points à 20 yd. C'est le client qui la connaît, c'est donc lui qui la
transmet. Les identifiants `code`, `maps` et `version` sont ceux des champs du formulaire
`.github/ISSUE_TEMPLATE/positions.yml`.

### Base persistée

| Champ | Sens |
|---|---|
| `node.kind` | **Livré en v1.1.0, sans changer `schemaVer`** (posé par `Nodes:Init` à chaque chargement). `"L"` ou `"V"`, **toujours présent** : un point ancien le reçoit au chargement (A4). Fixé à la capture : faction du personnage pour un sort ou un relevé manuel (D4), nom lu pour une infobulle ou une vignette. |
| `node.seen` | **Codé le 2026-09-28** (branche `feat/signal-contribution`, pas publié). Dernière observation **confirmée par le jeu** (sort, vignette). Contrairement à `node.last`, une fusion de données livrées ou importées ne le touche pas. Un point confirmé d'une base plus ancienne reçoit son `last` au chargement. |
| `db.gone[map]` | Retraits faits sur place par `/ley del` d'un point partageable (`spell`, `vignette`, `shipped`, `import`) : `{ x, y, kind, at }`. Pas `/ley clear` ni `/ley clean`, qui sont du ménage et pas une observation. |
| `db.contrib.at` | **Codé le 2026-09-28** (même branche). Date (`time()`) de la dernière contribution générée, posée à l'ouverture de la fenêtre ; une contribution vide (« rien de neuf ») ne la change pas. |
| `db.legacy` | **Livré en v1.1.0.** Copie texte (`{ at, blob }`) d'une base d'avant l'espèce, prise AVANT de lui donner ses espèces et jamais réécrite : si le classement A4 se trompe, rien n'est perdu. |

### Données livrées — `LeyLines_Data.lua`, **généré**

```lua
LL.DATA_VERSION = <n>
LL.DATA = { L = { [uiMapID] = { x, y, palier, ... } }, V = { ... } }   -- ajouts
LL.GONE = { L = { [uiMapID] = { x, y, palier, ... } }, V = { ... } }   -- retraits (A3), v1.2.0
```

**Livré en v1.1.0 : `LL.DATA` en triplets.** Le palier est le `DATA_VERSION` qui a introduit le
point ; `Nodes:ApplyShipped` ne fusionne que les points plus récents que la dernière fusion du
joueur. Avant, chaque livraison recopiait la liste ENTIÈRE : un point effacé exprès revenait à
chaque release de données.

Le fichier n'est plus écrit à la main : `tools/ll_ingest.lua` le produit à partir de
`data/contrib/<id>.ll` (une contribution par fichier : `from`, `date`, `source`, `version`, `code`
en LL2), qui sont la source de vérité. Retirer une contribution = supprimer son fichier et
régénérer. Les deux points de Zephras Isle sont la contribution `seed-zephras` (palier 2).
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

Le dédoublonnage de l'outil est approximatif (écart de carte < 0,003, sans taille de zone) : c'est
le CLIENT qui fusionne exactement, à 20 yd, en appliquant la liste.

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
- **T3** — ~~`/ley contribute` : filtre (A2)~~ (v1.1.0, code à coller) ; reste le lien pré-rempli
  et le cas « trop long ». Critères 3 (hors `seen`), 9. **Repris le 2026-09-28 par
  `signal-contribution.md`** (plan P1-P2), qui y ajoute le titre pré-rempli. Constat
  du même jour : le formulaire publié n'a que `code`, `faction` et `notes`, donc les paramètres `maps`
  et `version` du § Lien de contribution n'ont pas encore de champ.
- **T4** — ~~`LL.DATA` par espèce, en triplets avec palier~~ (v1.1.0) ; reste `LL.GONE` et les
  retraits dans `ApplyShipped` (A3). Critère 5.
- **T5** — ~~formulaire de ticket~~ (publié sur `main`, étiquette `positions` en place ; premier
  vrai ticket, #1 de wasdconnor, versé à la main le 2026-09-28 et vu en jeu : `gh-0001`, palier 3,
  voir le registre) ; reste l'Action de validation et de
  commentaire. Le corps du ticket passe par une variable d'environnement, jamais par `${{ }}` dans
  un `run:`. Critère 11.
- **T6** — ~~Compilateur `data/contrib/*.ll` → `LeyLines_Data.lua`~~ (v1.1.0, `tools/ll_ingest.lua`
  + `scripts\ll_ingest.ps1`, lancé à la main ; critères 6 partiel, 7 → `tests/test_ll_ingest.lua`) ;
  reste la PR unique ouverte par l'Action.
- **T7** — ~~Releases~~ (v1.1.0, v1.1.1, v1.2.0 publiées le 2026-09-27 ; la v1.2.0 est le
  compartiment d'addons, pas la contribution complète). Reste : la réponse au commentaire CurseForge
  (texte prêt, à poster par le user), et la release qui portera T1/T3/T4/T5 restants.
