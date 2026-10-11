-- LeyLines_CaptureCombat.lua — une absorption faite EN COMBAT se confirme à la fin du combat.
--
-- Vu au banc le 2026-10-11 (Anatarion) : « le toast n'apparaît pas en combat », alors qu'un toast
-- forcé en plein combat s'affiche bien. En combat, le jeu refuse à un addon la lecture des auras
-- (« Auras cannot be accessed when secret », fait du 2026-09-20, Capture:ReadAura) : le verdict par
-- la durée du buff ne pouvait pas tomber, et le lancer était perdu sans un mot (en v1.8.1 il
-- écrivait « Buff court », à tort). Capture:ResolveCast le confie maintenant ici, et on le rejuge à
-- PLAYER_REGEN_ENABLED : le buff de 15 min doit avoir été posé à l'instant du lancer (IsFreshLong,
-- avec l'heure du verdict d'origine). La position reste celle du lancer.
-- Un seul lancer en attente : chaque absorption réussie REPOSE le buff, seule la dernière se relit.
local _, LL = ...
local Capture = LL.Capture

function Capture:Later(map, x, y, castAt)
    self.later = { map = map, x = x, y = y, castAt = castAt }
end

-- Encore refusé (un verrou qui dure après le combat) : le lancer repart en attente, pour le
-- combat suivant ; le buff dure 15 min, son heure de pose ne bouge pas d'ici là.
function Capture:ResolveLater()
    local p = self.later
    if not p then return end
    self.later = nil
    self.auraBlockedUntil = nil   -- le combat est fini : la pause d'après un refus n'a plus d'objet
    self:ResolveCast(p.map, p.x, p.y, p.castAt)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function() Capture:ResolveLater() end)
