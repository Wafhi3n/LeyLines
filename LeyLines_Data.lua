-- LeyLines_Data.lua — positions LIVRÉES avec l'addon.
--
-- Pourquoi un fichier séparé de la base du joueur : ces points sont fusionnés UNE fois dans sa
-- base (au palier `DATA_VERSION`), puis ils lui appartiennent. S'il en efface un, il reste effacé
-- — on ne le lui remet pas au prochain /reload. Un nouveau lot se livre en incrémentant
-- DATA_VERSION, et seul le delta est repris.
--
-- Leur précision est volontairement basse (voir PRECISION dans LeyLines_Nodes.lua) : un relevé
-- fait par le joueur lui-même, sort à l'appui, ne doit JAMAIS être déplacé par une donnée livrée.
--
-- Format : [uiMapID] = { x1, y1, x2, y2, ... } en coordonnées de carte (0..1). Liste plate parce
-- qu'elle grossira, et qu'une table par point coûterait dix fois la place pour rien.
--
-- Source des points : exports de joueurs (`/ley export`), recopiés ici tels quels.
local _, LL = ...

LL.DATA_VERSION = 1

LL.DATA = {
    -- Zephras Isle — relevés au sort (buff long) le 2026-09-20.
    [2521] = {
        0.3537, 0.3370,
        0.3881, 0.4759,
    },
}
