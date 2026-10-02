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
--
-- LL.THANKS : [palier] = pseudos de ceux dont la contribution est arrivée à ce palier, remerciés en
-- jeu (LeyLines_Thanks.lua). Un pseudo n'y entre que fait de lettres, chiffres, tiret et souligné.
local _, LL = ...

LL.DATA_VERSION = 17

LL.THANKS = {
    [2] = { "Wafhien" },
    [3] = { "wasdconnor" },
    [4] = { "Wafhien" },
    [5] = { "fatalsmick" },
    [6] = { "fatalsmick" },
    [7] = { "kmcdougall81" },
    [8] = { "sionnabhan" },
    [9] = { "DustyHands-hub", "neumannrainer-dev", "kkatee" },
    [10] = { "sionnabhan" },
    [11] = { "sionnabhan" },
    [12] = { "sionnabhan" },
    [13] = { "sionnabhan" },
    [14] = { "sionnabhan" },
    [15] = { "matias-norman" },
    [16] = { "neumannrainer-dev", "FooBarWow" },
    [17] = { "evellior" },
}

LL.DATA = {
    L = {
        [1415] = {
            0.4107, 0.8008, 17,
        },
        [1429] = {
            0.7546, 0.5205, 9,
            0.8458, 0.7659, 17,
        },
        [1432] = {
            0.2828, 0.4212, 16,
        },
        [1433] = {
            0.1275, 0.7270, 9,
            0.3037, 0.5523, 16,
        },
        [1434] = {
            0.1342, 0.1510, 17,
        },
        [1436] = {
            0.3495, 0.7322, 9,
            0.5973, 0.3150, 9,
            0.5107, 0.6752, 9,
            0.5111, 0.2169, 15,
            0.4655, 0.5895, 16,
        },
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
            0.3383, 0.5538, 9,
            0.5050, 0.3338, 16,
            0.4831, 0.5849, 16,
        },
    },
    V = {
        [1411] = {
            0.4513, 0.1574, 10,
            0.5316, 0.1611, 14,
        },
        [1413] = {
            0.5483, 0.3474, 8,
            0.4479, 0.5496, 13,
        },
        [1434] = {
            0.1334, 0.1510, 11,
        },
        [1436] = {
            0.4200, 0.7490, 10,
            0.3031, 0.8551, 12,
        },
    },
}
