# Remerciements : les contributeurs dans l'addon

> État : **codée, pas vue en jeu** (branche `feat/contributeurs`, LeyLines + outillage) ·
> Rédigée le 2026-09-30 · Idée du user (« faudrait pas rajouter la liste des contributeurs dans
> l'addon ? ») ; arbitrages R1-R5 proposés par l'agent, acceptés le même jour (« oui vas y »)
> Cible : WoW: Forever / Camelot (16001) · Addon : LeyLines · Spec voisine, dont celle-ci dépend :
> `contribution-positions.md` (les contributions `data/contrib/*.ll` et la liste générée)

## Le problème

Au 2026-09-30, sept joueurs ont partagé des positions par ticket (v1.2.1 à v1.3.3). Seul le
CHANGELOG les nomme, et un joueur ne lit pas le CHANGELOG en jeu. Celui qui reçoit six fissures
d'un coup ne sait pas d'où elles viennent, et celui qui les a trouvées ne voit son pseudo nulle
part dans l'addon. Or voir son pseudo est la meilleure raison de recommencer.

## Ce qu'on veut

**Quand une mise à jour ajoute des positions**, la ligne de chat qui les annonce est suivie d'une
autre : merci à ceux qui ont apporté ces positions-là, et la commande qui donne tout le monde.

**`/ley credits`** (ou `/ley merci`) liste tous les contributeurs, du premier au dernier.

**Au moment de contribuer**, une ligne dit au joueur que son pseudo rejoindra cette liste.

## Décisions

- **R1 — La liste est GÉNÉRÉE.** `tools/ll_ingest.lua` écrit `LL.THANKS` dans `LeyLines_Data.lua`,
  à partir du `from=` de chaque contribution. Personne ne tient une liste à la main : elle suit les
  tickets versés.
- **R2 — Un pseudo est une entrée non fiable.** Il vient d'un ticket, et il finit dans du Lua
  chargé par chaque client. L'outil ne garde qu'un pseudo fait de lettres, chiffres, tiret et
  souligné, de 39 caractères au plus (ce que GitHub autorise, plus le souligné des pseudos
  CurseForge). Tout autre pseudo est écarté des remerciements et signalé à la génération ; ses
  positions, elles, restent. Le client refiltre à l'affichage.
- **R3 — Toute contribution est remerciée**, même celle qui ne fait que confirmer des points déjà
  livrés : le joueur est allé voir, et c'est ce recoupement qui rend la liste fiable.
- **R4 — La ligne de remerciement ne part que si des positions ont été ajoutées**, et elle nomme
  ceux des paliers que le joueur vient de recevoir. Au-delà de six pseudos, elle dit « et N
  autre(s) » ; `/ley credits` donne tout.
- **R5 — Pas de changement à la fenêtre de contribution.** L'annonce « ton pseudo rejoindra la
  liste » est une ligne de chat : une mise en page de fenêtre ne se vérifie pas sans le jeu.

## Ce qu'on ne fait PAS

- **Pas d'auteur par point** sur la carte ou dans une infobulle : il faudrait un auteur par
  triplet dans `LL.DATA`, pour un gain faible.
- **Pas de page CurseForge à tenir** : chaque note de version remercie déjà.
- **Pas de détection « c'est toi »** : un pseudo GitHub n'est pas un nom de personnage.

## Cas particuliers

- **Un contributeur demande à ne pas figurer** → corriger ou vider le `from=` de sa contribution,
  puis `ll_ingest.ps1 -Build`. Ses positions restent.
- **Deux contributions du même joueur** → un seul pseudo dans la liste, à son premier palier.
- **Installation neuve** → tous les paliers arrivent d'un coup : la ligne nomme les six premiers
  et compte les autres.
- **Mise à jour sans position neuve pour ce joueur** (il les avait déjà) → aucune ligne.

## Format

```lua
LL.THANKS = { [palier] = { "pseudo", ... }, ... }   -- dans LeyLines_Data.lua, avant LL.DATA
```

## Critères d'acceptation

1. [test] La liste générée porte les pseudos par palier, dans l'ordre des contributions.
2. [test] Un pseudo piégé (guillemet, espace, code) ne sort jamais dans le fichier généré.
3. [test] Une contribution qui ne fait que confirmer est remerciée aussi.
4. [test] Après une fusion, seuls les paliers neufs pour ce joueur sont remerciés ; rien si rien.
5. [test] Au-delà de six pseudos, la ligne compte les autres ; `/ley credits` les donne tous.
6. [humain] Sur un compte en retard d'un palier, après la mise à jour : sous « N position(s)
   ajoutée(s) », une ligne remercie les bons pseudos.
7. [humain] `/ley credits` affiche la liste dans le chat, lisible, sans débordement.
8. [humain] `/ley contribute` ouvre la fenêtre comme avant, et une ligne annonce la liste.
