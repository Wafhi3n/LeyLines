# Ley Lines

Retient les lignes telluriques (« Ley Line ») croisées en jeu et les repose sur la **minicarte**,
sur la **carte du monde** et dans un petit **bandeau de suivi** — pour que le sort de régénération
Skyborn se lance sur une ligne qu'on retrouve, au lieu d'une ligne qu'on espère.

**Cible : WoW: Forever / Camelot uniquement** (client `_classic_beta_`, Interface 16001, API
mainline). L'addon s'appuie sur `C_Map`, `C_Minimap.GetViewRadius`, `C_VignetteInfo` et
`C_SuperTrack`, qui n'existent pas sous cette forme sur Classic Era.

La base est **locale au compte** : rien ne part sur le réseau, tes personnages se la partagent via
les SavedVariables.

## En jeu

| Commande | Effet |
|---|---|
| `/ley` | état : combien de lignes ici, la plus proche, ce qui est allumé |
| `/ley add` | enregistre une ligne **à ta position** (fais-le en étant posé dessus) |
| `/ley del` | efface la ligne la plus proche (≤ 60 yd) |
| `/ley list` | liste les lignes de la zone avec leurs coordonnées |
| `/ley clean` | efface tous les relevés faits **par infobulle** (les approximatifs) |
| `/ley export` | ouvre une fenêtre avec un code à copier et partager |
| `/ley import` | colle un code reçu et fusionne les positions |
| `/ley clear` | vide la zone (avec confirmation) |
| `/ley hud` / `pins` / `map` | bandeau / minicarte / carte du monde |
| `/ley track` | pose un point de route natif sur la plus proche |
| `/ley warn <min>` | rappel quand il reste N min de buff (défaut 5, `0` = jamais) |
| `/ley learn` | apprend ton sort de ligne tellurique (voir ci-dessous) |
| `/ley name <texte>` | ajoute un nom d'objet à reconnaître |
| `/ley probe` | diagnostic : ce que le client expose vraiment autour de toi |

Deux raccourcis clavier sont disponibles dans *Options → Raccourcis → Ley Lines* (enregistrer ici,
suivre la plus proche).

## Partager ses positions

`/ley export` ouvre une fenêtre avec un code du genre `LL1;2521=3537,3370,3881,4759` : un texte,
à coller où tu veux (ticket GitHub, Discord, message). `/ley import` fait le chemin inverse.

Le format tient en entiers (dix-millièmes de carte, ~0,5 yd) parce qu'un code voyage à la main :
il traverse des copier-coller, des clients qui écrivent « 0,35 » et des retours à la ligne. Un
point aberrant est jeté sans faire échouer le reste du lot.

Une position **reçue** ne déplace jamais un relevé que tu as fait toi-même sur place : elle
comble un trou, elle ne corrige pas ta vérité locale.

`LeyLines_Data.lua` porte les positions **livrées avec l'addon**, fusionnées une seule fois par
palier de `DATA_VERSION`. Si tu en effaces une, elle reste effacée.

## Le rappel de buff

Le buff d'absorption dure 15 minutes. À **5 minutes restantes** (réglable par `/ley warn`), l'addon
annonce le temps qu'il reste, la distance de la faille connue la plus proche, et **pose le point de
route dessus** — le point de route natif du client, pas de TomTom à installer.

Il ne se déclenche qu'une fois par buff, et se réarme dès que tu te recharges. Il tourne même
bandeau masqué : c'est un rappel, pas un affichage.

## Les quatre façons dont une position entre dans la base

Par précision décroissante :

1. **Vignette** — lecture exacte et automatique **si** le client déclarait les failles comme
   vignettes. Mesuré en jeu le 2026-09-20, debout sur une faille : `vignettes autour : 0`, et
   `area POI sur cette carte : 0`. Aucune détection passive n'existe donc sur Forever aujourd'hui
   — l'icône blanche de la minicarte est un blip natif, qu'aucune API ne sait énumérer. Le code
   reste en place : il ne coûte rien et prendrait le relais si la bêta changeait ça.
2. **Sort** — lance ton sort d'absorption, rien à configurer. C'est **le jeu qui tranche** : sur une
   faille le sort donne un buff de 15 minutes, à côté un buff de 15 secondes. L'addon lit la durée
   du buff obtenu et n'enregistre que sur un buff long — aucune estimation de distance, aucun faux
   positif. Un lancer raté te le dit en une ligne et n'écrit rien. C'est la meilleure source.
3. **Manuel** — `/ley add` ou le raccourci, en étant posé dessus.
4. **Infobulle** — **éteinte par défaut** (`/ley tooltip` pour l'allumer). Survoler l'objet suffit,
   mais le relevé vaut la position du **joueur**, mesurée à 40 yd de l'objet en jeu le 2026-09-20 :
   ça pose un point là où il n'y a rien. Marqué approximatif, corrigé par un relevé plus précis.
   Trois verrous l'empêchent de relire NOS propres infobulles de point (drapeau muet pendant la
   fabrication, propriétaire de l'infobulle, souris exigée sur le monde 3D) — sans eux, survoler un
   point de la minicarte enregistrait une ligne à ta position.

## Premier passage conseillé

1. Lance ton sort d'absorption **sur** une faille. Le sort Skyborn (`Energized`, id 1259691) est
   livré avec l'addon, donc ça marche dès le premier lancer : la faille est enregistrée, et jouer
   normalement remplit la carte tout seul. `/ley learn` n'est là que si la bêta change cet id.
2. `/ley probe` debout sur la faille, si quelque chose cloche : la sortie donne la carte et la
   position, le rayon de minicarte lu, les vignettes et area POI autour, le sort et le buff retenus,
   et la dernière infobulle vue avec son propriétaire.

**État mesuré en jeu le 2026-09-20 (Zephras Isle, client enUS)** : cycle complet validé —
`/ley learn` + un lancer sur la faille a retenu le sort **Energized (1259691)**, reconnu son buff
long et enregistré la position. Rayon de minicarte rendu par le client : 233,3 yd, correct tel quel
(aucune correction `/ley scale` nécessaire). Nos points ne sont pas des cadres protégés, donc rien
ne se gèle en combat.
