# Signal « position à partager » sur la minicarte

> État : **validée, pas commencée** · Rédigée le 2026-09-28 · Idée du user (2026-09-28) ; arbitrages
> S1-S5 proposés par l'agent, acceptés par le user le même jour (« oui fait la spec ») ; décision I2
> (faction facultative) prise le même jour après l'essai P0
> Cible : WoW: Forever / Camelot (16001) · Addon : LeyLines · Spec voisine, dont celle-ci dépend :
> `contribution-positions.md` (le code partagé, le formulaire, le lien pré-rempli)

## Le problème

`/ley contribute` ne sert que si le joueur y pense. Au 2026-09-28, un seul joueur extérieur l'a
trouvée (ticket #1, 4 fissures sur Zephras Isle). Au moment où ça compte, quand un joueur vient de
découvrir une fissure que la liste commune n'a pas, rien ne le lui dit. Le chat affiche « Nouvelle
Ley Line enregistrée », et c'est tout : le joueur continue sa route, et la trouvaille reste dans sa
base.

Le même ticket a montré un malentendu : le titre proposé par le formulaire (« Positions from ») fait
croire qu'on envoie une zone à la fois. Le user lui-même l'a cru. Le joueur l'avait complété avec
« Zephras Isle », alors que le code porte toutes ses captures, toutes zones confondues.

## Ce qu'on veut

**Quand le jeu confirme une position que la liste livrée n'a pas** (lancer suivi du buff long, ou
vignette), une icône s'allume dans la barre d'icônes de la minicarte, à côté de la lettre du
courrier. Au même moment, une seule ligne dans le chat dit pourquoi : une position absente de la
liste commune, clique sur l'icône pour la partager.

**Au survol**, l'icône dit combien de positions attendent d'être partagées, et que le clic les
partage.

**Au clic**, la fenêtre de contribution s'ouvre avec le **lien** déjà sélectionné (Ctrl+C). Collé
dans un navigateur, il ouvre le formulaire GitHub **déjà rempli** : le code et un titre qui liste
les zones du code (« Positions: Zephras Isle, Durotar »). Le joueur n'a plus qu'à envoyer : la
faction n'est pas demandée, le code la porte déjà (I2).

**L'icône s'éteint** dès que la fenêtre de contribution s'ouvre, quel que soit le chemin : l'icône,
`/ley contribute` ou le compartiment d'addons. Elle s'éteint aussi toute seule quand une mise à
jour de l'addon livre ces positions. Elle ne se rallume que pour une découverte postérieure.

Le signal **survit** à un `/reload` et à une déconnexion : une découverte faite juste avant de
quitter est encore signalée à la connexion suivante.

**`/ley signal off`** coupe le signal (icône et ligne de chat) ; `/ley signal on` le remet. Il est
actif par défaut. `/ley contribute` marche pareil dans les deux cas, et l'infobulle du compartiment
d'addons donne toujours le nombre de positions à partager.

## Ce qu'on NE fait PAS

- **Savoir si le ticket est parti.** L'addon n'a aucun accès réseau : ouvrir la fenêtre vaut
  « contribué ». Un joueur qui ferme sans rien poster peut tout renvoyer avec `/ley contribute all`.
- **Signaler une position que la liste a déjà.** Confirmer une fissure livrée n'allume rien. Sinon,
  tous ceux qui suivent la liste auraient l'icône allumée en permanence.
- **Signaler un relevé non confirmé.** Un `/ley add` ou une infobulle ne partent pas vers la liste
  (A2 de la spec voisine), donc ils n'allument rien.
- **Signaler un retrait** (`/ley del` d'un point livré). Les retraits livrés (`LL.GONE`) ne
  sont pas encore implémentés. Ce sera à revoir avec eux.
- **Relancer le joueur.** Pas de rappel à intervalle, pas de clignotement, pas de son : une ligne de
  chat à l'allumage, et l'icône qui attend.
- **Un bouton de minicarte à nous.** Le compartiment d'addons reste l'accès permanent ; l'icône
  n'existe que quand il y a quelque chose à dire.
- **Dépendre de COC.** LeyLines recopie la méthode de l'icône, il n'appelle pas COC.
- **Poster à la place du joueur.** Le lien reste une adresse à coller (D5 de la spec voisine).

## Cas particuliers

- **Relevé « à confirmer » (`manual`, `tooltip`) qui passe en confirmé** par un lancer réussi →
  allume : la liste ne l'a pas, et il vient de devenir partageable.
- **Point importé d'un ami** puis confirmé par un lancer → allume si la liste livrée ne l'a pas.
- **Point déjà partagé** (confirmé avant la dernière contribution) et reconfirmé → n'allume pas.
- **Plusieurs découvertes avant le clic** → une seule icône, le nombre monte ; une seule ligne de
  chat, à l'allumage.
- **Vignette de l'autre faction** (l'objet est nommé, l'espèce lue sur le nom) → compte comme les
  autres : elle est partageable, et le code porte son espèce.
- **Joueur à deux factions** → un seul ticket, qui mélange fissures et tornades sans les
  confondre : le code porte l'espèce de chaque point, et le formulaire ne demande plus de faction
  (I2). Un champ unique l'aurait forcé à mentir sur la moitié de ses points.
- **Lien trop long** → même repli que la spec voisine : le code seul, et un lien court sans code.
  Le titre suit le même repli.
- **Mise à jour qui livre ces positions** → le nombre baisse, et l'icône s'éteint à zéro sans clic.
- **En combat** → le clic ouvre une fenêtre à nous, non protégée : autorisé.
- **Barre d'icônes absente** (Blizzard la retire ou la change) → pas d'icône, la ligne de chat reste.
- **COC installé aussi** → deux icônes dans la même barre, chacune à son rang (S4).
- **Signal coupé** → rien ne s'allume, mais le nombre reste calculé : il réapparaît à
  `/ley signal on` si des positions attendent encore.

## Décisions

- **I1 — 2026-09-28, user** : l'idée. Une icône sur la minicarte après la découverte d'une position
  qu'on n'a pas, et au clic une fenêtre avec l'adresse du ticket à créer.
- **I2 — 2026-09-28, user** : la faction voyage **dans le code** (la lettre `L` / `V` de chaque
  segment, depuis la v1.1.0), pas dans un champ du formulaire. Le champ Faction devient
  **facultatif**, réservé au fichier de SavedVariables joint par un joueur resté en v1.0.0 (une
  vieille base ne dit pas son espèce), et le lien ne le remplit pas. Origine : l'essai P0 (liste
  déroulante non pré-remplie, champ obligatoire, donc envoi refusé), puis la question du user
  « pourquoi ne pas mettre cette info dans la chaîne copiée ? ». L'ingestion lit déjà l'espèce dans
  le code ; sans faction déclarée, seule la vérification « point de l'autre faction » disparaît.

## Arbitrages — proposés par l'agent, acceptés par le user le 2026-09-28

- **S1 — L'icône s'éteint à l'ouverture de la fenêtre de contribution.** Raison : l'addon ne peut pas
  savoir si le ticket a été envoyé. Un clic droit « ignorer » ajouterait un geste pour le même effet.
- **S2 — Le signal se coupe** (`/ley signal off`), et il est actif par défaut.
- **S3 — Seule une position absente de la liste livrée allume le signal.** « Absente » = aucun point
  livré de même espèce à moins de `mergeRange` (20 yd). Raison : voir « Ce qu'on NE fait PAS ».
- **S4 — Emplacement : la barre d'icônes de la minicarte** (`MinimapCluster.IndicatorFrame`), avec la
  méthode A mesurée pour COC dans TaintLab le 2026-09-27 et vue en jeu le 2026-09-28 : icône enfant
  de la barre, `layoutIndex`, `Layout()` à chaque bascule. **Rang 4** (1 et 2 sont à Blizzard, 3 à la
  mise à jour de COC). Image : l'icône de l'addon, 22 px.
- **S5 — Le titre du ticket est pré-rempli** avec les zones du code. Raison : le malentendu du ticket
  #1 (voir « Le problème »).

## Critères d'acceptation

1. [test] Un lancer confirmé qui crée une position absente de la liste livrée allume le signal ; un
   lancer sur une position livrée ne l'allume pas.
2. [test] Un point `manual` qui passe en `spell` par un lancer allume le signal.
3. [test] Ouvrir la contribution éteint le signal ; une découverte postérieure le rallume ; une
   position déjà partagée, reconfirmée, ne le rallume pas.
4. [test] Le signal se déduit de la base : après rechargement, il est identique ; une liste livrée
   qui contient la position l'éteint.
5. [test] Signal coupé : aucune icône, aucune ligne de chat ; `/ley contribute` rend le même lien.
6. [test] Le lien porte `template=positions.yml`, le code et le titre, encodés en pourcent, et pas
   de faction (I2) ; aucun caractère du nom de zone ne sort non encodé.
7. [porte] Les quatre portes passent ; chaque chaîne nouvelle est dans les overlays enUS, deDE et
   esES. → `deploy.ps1`
8. [humain] Après un lancer réussi sur une fissure absente de la liste, l'icône apparaît dans la
   barre, lisible, sans toucher la carte, et la ligne de chat s'affiche une fois. Témoin connu-bon :
   l'icône « mise à jour » de COC dans la même barre (registre COC, relevés 14-15). Terrain : la
   fissure (46,26 / 17,78) de Zephras Isle, capturée par le user le 2026-09-27 et absente de la
   liste livrée. Observateur : le user, en jeu.
9. [humain] Clic sur l'icône → la fenêtre montre le lien sélectionné ; collé dans un navigateur
   connecté à GitHub, il ouvre le formulaire avec le code **et** le titre remplis, et « Create »
   passe sans rien choisir. Témoin connu-bon : le lien écrit à la main de l'essai P0, qui a rempli
   les deux. Observateur : le user.
10. [humain] Avec COC et LeyLines allumés ensemble : mode Édition ouvert puis fermé, un combat, et
    aucune « action refusée à cause d'un addon ». Témoin : la même séance, LeyLines désactivé.
    Observateur : le user, `/console taintLog 1`.

## Contrat

- **Base persistée** : `db.signal` (booléen, `true` par défaut), rien d'autre. L'état du signal
  (combien de positions attendent) **n'est pas stocké** : il se déduit de la base (`node.seen`), de
  la date de la dernière contribution (`db.contrib.at`) et de la liste livrée. Ces deux champs sont
  au contrat de la spec voisine ; cette fonctionnalité en a besoin et les implémente si ce n'est pas
  déjà fait. Raison : une seule source de vérité, et l'extinction quand une mise à jour livre le point
  vient sans code dédié.
- **Barre d'icônes** : rang 4, à réserver aussi dans la liste des rangs de
  `CraftingOrderClassic\docs\specs\icone-minicarte.md`, puisque les deux addons partagent la barre.
- **Lien** : celui de la spec voisine (§ Lien de contribution), plus `title`, et **sans**
  `faction` (I2). Le formulaire publié n'a que les champs `code`, `faction` (facultatif depuis I2)
  et `notes` : les paramètres `maps` et `version` prévus là-bas n'ont pas encore de champ où
  arriver. **Mesuré le 2026-09-28** (essai P0, capture du user) : `title` et `code` se
  pré-remplissent, l'étiquette `positions` est posée, mais la liste déroulante `faction=Alliance`
  reste sur « None ». La doc GitHub, qui annonce le contraire, est démentie pour ce cas.

## Renvois

- `contribution-positions.md` : le code `LL2`, le filtre A2, le formulaire, le lien, `seen` et
  `contrib.at`.
- Skill **coc-native-ui** § « Icônes d'état de la minicarte » : la méthode, pourquoi on n'y touche
  pas, la taille, les atlas vérifiés.
- `CraftingOrderClassic_MinimapIndicator.lua` : l'implémentation de référence (98 lignes).
- Mémoire « Ouvrir un menu Menu depuis un addon = plantage » : le clic ouvre NOTRE fenêtre, jamais
  un menu.
- `docs/verif-registre.md` : les critères [humain] s'y consignent une fois observés, et seulement
  alors.

## Plan — 2026-09-28 (volatile, à rayer au fil de l'eau)

- **P0** — ~~Essayer à la main un lien `issues/new?template=positions.yml&title=…&code=…&faction=Alliance`~~
  (2026-09-28 : titre et code remplis, faction NON remplie → I2, formulaire corrigé sur la branche
  LeyLines `fix/formulaire-faction-facultative`).
- **P1** — ~~`node.seen` et `db.contrib.at` (spec voisine, T1/T3) : la contribution ne porte plus que
  ce qui est postérieur à la précédente~~ (codé le 2026-09-28, branche `feat/signal-contribution`
  des dépôts LeyLines et outillage ; `/ley contribute all` renvoie tout ; pas vu en jeu).
  Critère 3 de la spec voisine → `tests/test_leylines_contribute.lua`.
- **P2** — Le lien pré-rempli, avec le titre, et son repli (T3 de la spec voisine).
  Critères 6 et 9.
- **P3** — Le calcul du signal, `/ley signal`, la ligne de chat, l'infobulle du compartiment.
  Critères 1 à 5.
- **P4** — L'icône : recopier la méthode de COC, rang 4, et réserver ce rang dans la spec COC.
  Critères 8 et 10.
