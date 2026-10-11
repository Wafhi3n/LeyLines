-- LeyLines_Toast.lua — ce qui arrive sans geste du joueur passe en toast, pas dans le chat.
--
-- Règle du user du 2026-10-11 (skill publique `chat-output`), née d'un commentaire CurseForge :
-- « Too much chat spam ». Le chat ne répond qu'à un geste du joueur (commande, clic, raccourci) ;
-- un lancer, une vignette, le signal ou le rappel de buff passent en toast.
--
-- Le toast est celui du JEU : la pile des hauts faits et du butin (AlertFrame), « si Blizzard a sa
-- propre API, on doit l'utiliser » (user). Mesurée au TaintLab le 2026-10-11 (outillage,
-- TaintLab_Toast.lua) : nos toasts en combat, puis un toast de recette de Blizzard après le nôtre,
-- sans aucun blocage. L'inscription se fait UNE fois, au PLAYER_LOGIN, hors combat comme à la
-- mesure : le premier toast peut tomber en plein combat (le rappel de buff), et une inscription en
-- combat n'a jamais été essayée. Sans AlertFrame (tests, autre client), un toast ne fait rien : pas
-- de repli dans le chat, ce serait le spam qu'on retire.
local _, LL = ...

local Toast = {}
LL.Toast = Toast

local TITLE          = "Ley Lines"   -- le nom de l'addon, comme le préfixe du chat : pas traduit
local SHOWN, QUEUED  = 2, 6          -- toasts visibles à la fois, en attente derrière

local function SetUp(frame, title, text)
    frame.Title:SetText(title)
    frame.Text:SetText(text)
end

function Toast:Init()
    if self.system or not (AlertFrame and AlertFrame.AddQueuedAlertFrameSubSystem) then return end
    self.system = AlertFrame:AddQueuedAlertFrameSubSystem("LeyLinesToastTemplate", SetUp, SHOWN, QUEUED)
end

-- Rend vrai si le toast s'affiche ou attend son tour dans la file.
function Toast:Show(text)
    if not self.system then return false end
    return self.system:AddAlert(TITLE, text) and true or false
end

-- Le choix d'un appelant qui sert les deux cas (Capture:Store : `/ley add` ou un lancer) : le geste
-- du joueur reçoit sa réponse dans le chat, le reste passe en toast.
function LL:Tell(asked, text)
    if asked then self:Print(text) else Toast:Show(text) end
end
