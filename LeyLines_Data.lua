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

LL.DATA_VERSION = 26

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
    [17] = { "chris-rowley83", "evellior", "Noblesun13" },
    [18] = { "chris-rowley83" },
    [19] = { "chris-rowley83", "ohnoezlennydied", "asylumlouie" },
    [20] = { "agilliam7", "axlmcc", "asylumlouie", "cardphan1-ai", "alcaras" },
    [21] = { "cainicide-bot" },
    [22] = { "isaacoolbeans", "ohnoezlennydied", "asylumlouie", "kehtemine" },
    [23] = { "asylumlouie", "zetakirby", "ThirdIrony", "FlooferStabbington" },
    [24] = { "vananyask1", "alcaras", "larsas-cmyk" },
    [25] = { "axlmcc", "asylumlouie", "kehtemine" },
    [26] = { "bobjackson321" },
}

LL.DATA = {
    L = {
        [1413] = {
            0.5421, 0.1208, 20,
            0.4886, 0.3633, 22,
            0.5580, 0.3425, 23,
        },
        [1420] = {
            0.5431, 0.6262, 23,
            0.7661, 0.7155, 23,
            0.7033, 0.6352, 26,
        },
        [1421] = {
            0.6124, 0.7929, 22,
            0.5255, 0.7060, 23,
        },
        [1424] = {
            0.6342, 0.4639, 20,
        },
        [1426] = {
            0.5657, 0.4558, 20,
            0.7682, 0.5180, 24,
        },
        [1429] = {
            0.7546, 0.5205, 9,
            0.8458, 0.7659, 17,
            0.3725, 0.5609, 19,
            0.2791, 0.9470, 25,
        },
        [1431] = {
            0.7246, 0.3056, 17,
            0.1863, 0.5725, 18,
            0.3408, 0.7071, 19,
            0.7841, 0.3553, 25,
        },
        [1432] = {
            0.2828, 0.4212, 16,
        },
        [1433] = {
            0.1275, 0.7270, 9,
            0.3037, 0.5523, 16,
            0.5494, 0.6477, 19,
            0.3095, 0.4606, 19,
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
            0.4595, 0.1986, 25,
        },
        [1437] = {
            0.4626, 0.2517, 18,
            0.5617, 0.6400, 18,
            0.1471, 0.3717, 19,
            0.4029, 0.3855, 21,
            0.5500, 0.2975, 23,
        },
        [1439] = {
            0.5707, 0.2608, 23,
            0.3602, 0.8620, 23,
        },
        [1440] = {
            0.2033, 0.4268, 22,
        },
        [1442] = {
            0.3637, 0.1254, 22,
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
            0.4572, 0.6973, 22,
            0.4981, 0.2856, 24,
        },
        [1434] = {
            0.1334, 0.1510, 11,
        },
        [1436] = {
            0.4200, 0.7490, 10,
            0.3031, 0.8551, 12,
        },
        [1440] = {
            0.0976, 0.2792, 25,
        },
        [1442] = {
            0.7486, 0.9447, 20,
        },
        [2521] = {
            0.4661, 0.3814, 17,
            0.5283, 0.5769, 17,
            0.6829, 0.7495, 17,
            0.5914, 0.7982, 17,
            0.4842, 0.8055, 17,
            0.6485, 0.3788, 17,
            0.6834, 0.6611, 17,
            0.6171, 0.5163, 17,
            0.4838, 0.2041, 20,
            0.4845, 0.5555, 20,
            0.4778, 0.6935, 20,
        },
    },
}
