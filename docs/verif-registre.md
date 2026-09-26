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

## Releves

- 2026-09-26 - jusqu'a 93693eb - Forever, un client - **GO cote HORDE** - rapporte par le user :
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
