# Registre de verification en jeu - LeyLines

Meme role que celui de Crafting Order - Classic : dire jusqu'ou l'addon a ete **vu fonctionner**
dans le client, puisque aucune porte automatique ne sait le dire. `scripts/untested.ps1 -Addon
LeyLines` lit la premiere ligne de releve ci-dessous et liste ce qui est venu apres.

Format d'un releve (le plus recent EN TETE) :

```
- AAAA-MM-JJ - jusqu'a <sha> - <banc> - <verdict> - <ce qui a ete observe>
```

Le `<sha>` est le dernier commit reellement present dans le client pendant la seance. On n'ecrit
un releve qu'APRES avoir observe, et on dit ce qui n'a PAS ete observe.

⚠️ **UN REBASE PERIME LE SHA D'UN RELEVE.** Vecu le 2026-09-27 : le releve Horde citait `93693eb`,
le commit d'AVANT la remise a niveau de sa branche. Apres rebase le meme travail s'appelle
`57d3908`, et `93693eb` n'est plus un ancetre de `main` -- `untested.ps1` reannonçait donc comme
JAMAIS EPROUVE un travail qui l'avait ete. Le script ne peut pas le voir : le vieux commit existe
toujours comme objet, sa verification d'existence passe. **Apres tout rebase d'une branche deja
couverte par un releve, avancer son sha** (`git log --oneline` sur la nouvelle branche donne
l'equivalent, le message est identique).

## Releves

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
