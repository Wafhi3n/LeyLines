-- LeyLines_Data.lua — positions LIVRÉES avec l'addon, communes à tous les joueurs.
--
-- ATTENTION : FICHIER GÉNÉRÉ par tools/ll_ingest.lua (scripts\ll_ingest.ps1 -Build) à partir des
-- contributions data/contrib/*.ll. NE PAS L'ÉDITER À LA MAIN : la génération suivante écraserait
-- la modification. Pour retirer un point, corriger ou supprimer sa contribution, puis régénérer.
--
-- Format : [espèce][uiMapID] = { x, y, palier, ... } — coordonnées de carte (0..1) ; palier =
-- DATA_VERSION qui a introduit le point : Nodes:ApplyShipped ne fusionne que ceux qu'un joueur n'a
-- pas encore reçus, pour qu'un point qu'il a effacé ne revienne pas. Espèce : L = fissure
-- (Alliance), V = tornade (Horde). Un point par ligne, pour que la relecture d'une PR se fasse
-- ligne à ligne.
local _, LL = ...

LL.DATA_VERSION = 7

LL.DATA = {
    L = {
        [2521] = {
            0.3537, 0.3370, 2,
            0.3881, 0.4759, 2,
            0.5373, 0.6622, 3,
            0.5241, 0.6612, 3,
            0.6398, 0.7429, 3,
            0.5878, 0.3361, 3,
            0.4626, 0.1778, 4,
            0.4580, 0.8071, 5,
            0.6906, 0.6193, 6,
            0.6398, 0.4620, 7,
        },
    },
    V = {
    },
}
