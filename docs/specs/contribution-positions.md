# Contribution des positions (crowdsourcing)

> État : **brouillon** · Rédigée le 2026-09-27 · Décisions D1-D4 prises par le user le 2026-09-27 ·
> Arbitrages A1-A4 **à valider** · Pas encore implémentée
> Cible : WoW: Forever / Camelot (16001) uniquement · Addon : Ley Lines
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
   sort Skyborn), la Horde une **tornade** (Elemental Vergence, sort Skysight) : même mécanisme,
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
- **Code `LL1` reçu** (d'un build antérieur) → encore lu. L'espèce inconnue prend celle du personnage
  qui importe.
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
  Vergence). Même mécanisme, objets différents → **l'espèce est une propriété du point**, jamais
  déduite de celui qui regarde.
- **D5 — 2026-09-27, contrainte technique** : l'addon fabrique un lien, il ne poste pas.

## Arbitrages proposés — à valider par le user

- **A1 — Affichage filtré par faction.** Un personnage Alliance ne voit que les fissures, un
  personnage Horde que les tornades. Les deux restent dans la base du compte. Raison : l'objet de
  l'autre faction ne s'absorbe pas, l'afficher n'ajoute que du bruit.
- **A2 — Une contribution ne porte que ce que le jeu a confirmé** : captures par sort (buff long) et
  par vignette. Les relevés manuels (`/ley add`) restent dans la base du joueur mais ne partent pas
  vers la liste commune. Raison : D2 n'est tenable que si chaque point entrant a été tranché par le
  jeu.
- **A3 — Un retrait livré n'efface jamais un relevé du joueur.** Il n'efface que les points
  `shipped` et `import`. Même logique que `PRECISION` : une donnée reçue comble un trou, elle ne
  corrige pas une vérité locale.
- **A4 — Migration des points existants** : `V` si leur nom contient « vergence », `L` sinon. Avant
  la v1.1.0, la Horde ne capturait rien par sort : le seul cas mal classé serait un `/ley add` fait
  sur un personnage Horde, qui ne part de toute façon pas en contribution (A2).

## Critères d'acceptation

1. [test] Un code `LL2` encodé puis décodé rend les mêmes points, espèces et retraits compris ; un
   code `LL1` se décode encore. → `tests/test_leylines.lua`
2. [test] Un point `L` et un point `V` à 5 yd l'un de l'autre restent DEUX points.
3. [test] La contribution exclut les sources `shipped`, `import`, `restored`, `tooltip` (et `manual`
   si A2 est validé). Elle n'inclut que les observations et les retraits postérieurs à la précédente.
4. [test] Un point confirmé par une fusion de données livrées n'est PAS considéré comme revu : il ne
   repart pas dans la contribution suivante.
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
    minicarte aucune tornade capturée par le personnage Horde (si A1 est validé). Témoin connu-bon :
    la v1.1.0, qui les montre. Observateur : le user, à 2 personnages.
11. [humain] Le ticket de test reçoit un commentaire de l'Action avec le décompte, puis une PR
    modifiant `LeyLines_Data.lua` apparaît. Observateur : le user, sur GitHub.

## Contrat

### Texte d'échange `LL2` (en jeu, et dans le ticket)

```
LL2;<segment>[;<segment>...]
segment := [-]<espèce><uiMapID>=<x>,<y>[,<x>,<y>...]
espèce  := L   fissure / Ley Line (Alliance)
         | V   tornade / Elemental Vergence (Horde)
-       := retrait : « ces points n'existent plus »
x, y    := dix-millièmes de la carte, entiers 0..10000 (inchangé depuis LL1)
```

Exemple : `LL2;L2521=3537,3370,3881,4759;-L2521=5012,4410`. Segments triés, sortie stable.
Le décodeur jette point par point ce qui est douteux, comme `LL1` aujourd'hui.

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

### Base persistée — `schemaVer` 4

| Champ | Sens |
|---|---|
| `node.kind` | `"L"` ou `"V"`. Fixé à la capture d'après le buff obtenu (1259691 → L, 1270893 → V) ou le nom lu sur le client ; à défaut, la faction du personnage. |
| `node.seen` | Dernière observation **confirmée par le jeu** (sort, vignette). Contrairement à `node.last`, une fusion de données livrées ou importées ne le touche pas. |
| `db.gone[map]` | Retraits faits sur place par `/ley del` : `{ x, y, kind, at }`. Pas `/ley clear` ni `/ley clean`, qui sont du ménage et pas une observation. |
| `db.contrib.at` | Date de la dernière contribution générée. |

### Données livrées — `LeyLines_Data.lua`, **généré**

```lua
LL.DATA_VERSION = <n>
LL.DATA = { L = { [uiMapID] = { x1, y1, ... } }, V = { ... } }   -- ajouts
LL.GONE = { L = { [uiMapID] = { x1, y1, ... } }, V = { ... } }   -- retraits (A3)
```

Le fichier cesse d'être écrit à la main : il est produit à partir de `data/contrib/<n° de ticket>.ll`
(une contribution validée par fichier, texte `LL2` + `maps` + date), qui devient la source de
vérité. Les deux points de Zephras Isle deviennent la contribution n° 0. `.pkgmeta` ignore `data`,
`tools` et `.github`.

## Renvois

- Skill **leylines-addon** : capture par durée du buff, piège de l'infobulle qui se relisait.
- `docs/verif-registre.md` : les critères [humain] s'y consignent une fois observés, et seulement
  alors.
- `CLAUDE.md` racine : un test de `tests\` qui exerce ce code ne va pas sur `master` avant que la
  fonctionnalité atterrisse sur `main` de LeyLines.

## Plan — 2026-09-27 (volatile, à rayer au fil de l'eau)

- **T0 — Publier la v1.1.0 telle quelle, indépendamment de cette spec.** Les joueurs Horde ne
  peuvent rien capturer avec la v1.0.0. Avant le tag : un aller-retour `/ley export` → `/ley import`
  à 2 comptes (jamais relevé en jeu), `CHANGELOG.md` et `CURSEFORGE.md` à jour (ni la Horde ni le
  partage n'y figurent), `.toc` à la main (`bump_version.ps1` ne connaît que COC).
- **T1** — Schéma v4 : `kind`, `seen`, `gone`, migration (A4) ; anti-doublon et affichage par espèce
  (A1). Critères 2, 10.
- **T2** — Codec `LL2`, lecture `LL1` gardée ; `/ley export` passe en `LL2`. Critère 1.
- **T3** — `/ley contribute` : filtre (A2), lien, cas « trop long ». Critères 3, 4, 9.
- **T4** — `LL.DATA` / `LL.GONE` par espèce, retraits dans `ApplyShipped` (A3). Critère 5.
- **T5** — Dépôt : formulaire de ticket + Action de validation et de commentaire. Le corps du
  ticket passe par une variable d'environnement, jamais par `${{ }}` dans un `run:`. Critère 11.
- **T6** — Compilateur `data/contrib/*.ll` → `LeyLines_Data.lua`, PR unique. Critères 6, 7.
- **T7** — Release v1.2.0, réponse sur le commentaire CurseForge avec le lien du formulaire.
