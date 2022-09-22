FM_CORE = {}
local player_information = CreatePlayer()
local fm_libs = {}
local logger = GetLogger()
logger:SetDebug(false)

local LCG = LibStub("LibCustomGlow-1.0")

function FM_CORE:OnLoad(addon)
    if addon ~= "FaceMelterWotlk" then
        return
    end
    local playerClass = player_information:GetClass()
    if FM_CORE:IsClassSupported(playerClass) ~= true then
        UnregisterEvents()
        logger:log_info('playerClass: ', playerClass,' not supported')
    else
        RegisterEvents()
        player_information:UpdateCharacter()
        logger:log_info('loaded playerClass: ', playerClass,' player name: ', self:GetPlayerName())
        FM_CORE:CreateUI()
    end
end

function FM_CORE:CreateUI()
    self:CreatePlayerCastBar()
end

function FM_CORE:CreatePlayerCastBar()
    local margin, button_size = 2, 40
    local spell_count = fm_libs[player_information:GetClass()]:SpellCount(player_information)
    if not spell_count or spell_count < 1 then
        return
    end

    logger:log_debug("drawing spell count: ", spell_count)
    local displayFrame = CreateFrame("Frame", "ShadbroDisplayFrame", UIParent, "BackdropTemplate")
    displayFrame:SetFrameStrata("BACKGROUND")
    displayFrame:SetWidth(40 * spell_count + 2 * spell_count)
    displayFrame:SetHeight(50)
    displayFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = true,
        tileSize = 32
    })
    displayFrame:SetBackdropColor(0, 0, 0, .4)
    displayFrame:EnableMouse(true)
    displayFrame:SetMovable(true)
    displayFrame:SetClampedToScreen(true)
    displayFrame:SetScript("OnMouseDown", function(self)
        self:StartMoving()
    end)
    displayFrame:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
    end)
    displayFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    displayFrame:SetPoint("CENTER", -200, -200)
    FM_CORE.cast_bar = displayFrame

    for key, value in pairs(fm_libs[player_information:GetClass()]:GetSpells()) do
        self:AddChild(displayFrame, button_size, key - 1 , margin, value)
    end
end

function FM_CORE:AddChild(parentDisplayFrame, size, offset, margin, spell)
    if not FM_CORE.textures then
        FM_CORE.textures = {}
    end
    local spellButton = CreateFrame("Button", nil, parentDisplayFrame, "SecureActionButtonTemplate")
    spellButton:SetWidth(size)
    spellButton:SetHeight(size)
    spellButton:SetPoint("TOPLEFT", offset * size + margin + offset * margin, -margin )

    local spell_id = spell.spell_id
    FM_CORE.textures[spell_id] = spellButton:CreateTexture(nil, "BACKGROUND")
    FM_CORE.textures[spell_id]:SetAllPoints(spellButton)
    FM_CORE.textures[spell_id]:SetTexture(spell.texture)
    FM_CORE.textures[spell_id]:SetDesaturation(.9)
    spellButton:SetNormalTexture(FM_CORE.textures[spell_id])

    spellButton["_PixelGlow"] = spell.spell_id
    spellButton:SetAttribute("type","spell");-- Set type to "macro"
    spellButton:SetAttribute("spell", spell.name);-- Set our macro text

    if not FM_CORE.cooldowns then
        FM_CORE.cooldowns = {}
    end
    FM_CORE.cooldowns[spell_id] = CreateFrame("Cooldown", spell_id, spellButton, "CooldownFrameTemplate")
    FM_CORE.cooldowns[spell_id] = CreateFrame("Cooldown", "myCooldown", spellButton, "CooldownFrameTemplate")
    FM_CORE.cooldowns[spell_id]:SetAllPoints()
    FM_CORE.cooldowns[spell_id]:SetCooldown(0, 0)

    if not FM_CORE.ActionButtons then
        FM_CORE.ActionButtons = {}
    end
    FM_CORE.ActionButtons[spell_id] = spellButton
end

function FM_CORE:SetGlow(spell_id)
    logger:log_debug("set_next: ", spell_id)
    local button = self.ActionButtons[spell_id]
    if not button._PixelGlow then
        return
    end
    local r,color,N,frequency,length,th,xOffset,yOffset,border,key,frameLevel
    frameLevel = 8
    key = spell_id
    LCG.PixelGlow_Start(button, color,N,frequency,length,th,xOffset,yOffset,border,key,frameLevel)
    -- LCG.PixelGlow_Stop(button, spell_id)
end

function FM_CORE:UnsetGlow(spell_id)
    logger:log_debug("unset: ", spell_id)
    local button = self.ActionButtons[spell_id]
    if not button._PixelGlow then
        return
    end
    LCG.PixelGlow_Stop(button, spell_id)
end

function FM_CORE:PushButtonState()
    for _, spell in pairs(fm_libs[player_information:GetClass()]:GetSpells()) do
        if spell.is_next then
            FM_CORE.textures[spell.spell_id]:SetAllPoints()
            FM_CORE.textures[spell.spell_id]:SetDesaturation(.9)
            self:SetGlow(spell.spell_id)
        else
            FM_CORE.textures[spell.spell_id]:SetAllPoints()
            FM_CORE.textures[spell.spell_id]:SetDesaturation(0)
            self:UnsetGlow(spell.spell_id)
        end
    end
end

function FM_CORE:ClearAllButtons()
    for _, spell in pairs(fm_libs[player_information:GetClass()]:GetSpells()) do
        FM_CORE.textures[spell.spell_id]:SetAllPoints()
        FM_CORE.textures[spell.spell_id]:SetDesaturation(.9)
        self:UnsetGlow(spell.spell_id)
    end
end

function FM_CORE:RegisterClassLibrary(class_lib)
    if not class_lib then
        logger:log_error('class_lib invalid')
        return
    end
    fm_libs[class_lib._name] = class_lib
end

function FM_CORE:IsClassSupported(class_name)
    if not class_name or not fm_libs[class_name] then
        return false
    end
    return true
end

function FM_CORE:GetPlayerInformation()
    return player_information
end

function FM_CORE:GetPlayerName()
    return player_information:GetName()
end

function FM_CORE:UpdatePlayerInformation()
    logger:log_info('FM_CORE:UpdatePlayerInformation')
    player_information:CharacterUpdate()
    FM_CORE:HandleTargetChange()
end

function FM_CORE:HandlePlayerAuraUpdate()
    logger:log_debug('FM_CORE:HandlePlayerAuraUpdate')
    player_information:OnAuraChange()
    FM_CORE:HandleTargetChange()
end

function FM_CORE:HandlePlayerTalentUpdate()
    logger:log_debug('FM_CORE: updating player information for talent change')
    player_information:OnSpecChange()
    FM_CORE:HandleTargetChange()
    logger:log_info('spec changed. loaded playerClass: ', player_information:GetClass(),' player name: ', self:GetPlayerName())
end

function FM_CORE:SetInCombat(in_combat)
    player_information:SetInCombat(in_combat)
end

function FM_CORE:HandleTargetChange()
    if not self.target_info then
        self.target_info = CreateTarget()
    end

    self.target_info:OnTargetChange()
    fm_libs[player_information:GetClass()]:ChooseNext(player_information, self.target_info)

    if self.target_info:IsFriendly() or self.target_info:IsNoTarget() then
        FM_CORE:ClearAllButtons()
        return
    end

    FM_CORE:PushButtonState()
end


function FM_CORE:HandleStartCasting(spell_id)
    -- if not self.target_info then
    --     self.target_info = CreateTarget()
    -- end
    -- fm_libs[player_information:GetClass()]:ChooseNext(player_information, self.target_info, spell_id)
    player_information:StartCasting(spell_id)
    logger:log_debug("started_casting: ", spell_id)
end

function FM_CORE:HandleCastComplete(spell_id)
    -- if not self.target_info then
    --     self.target_info = CreateTarget()
    -- end
    -- fm_libs[player_information:GetClass()]:ChooseNext(player_information, self.target_info, spell_id)
    player_information:StopCasting(spell_id)
    -- logger:log_debug("stop_casting")
end

function FM_CORE:PushNext(spell_id)
    -- if not self.target_info then
    --     self.target_info = CreateTarget()
    -- end
    -- fm_libs[player_information:GetClass()]:ChooseNext(player_information, self.target_info, spell_id)
end

function FM_CORE:HandleTargetAuraUpdate()
    FM_CORE:HandleTargetChange()
end

function FM_CORE:SetSelfTarget()
    FM_CORE:ClearAllButtons()
end

function FM_CORE:SetFriendlyTarget()
    FM_CORE:ClearAllButtons()
end

function FM_CORE:SetHostileTarget()
    if not self.target_info then
        self.target_info = CreateTarget()
    end
    fm_libs[player_information:GetClass()]:ChooseNext(player_information, self.target_info)
    FM_CORE:PushButtonState()
end

function FM_CORE:SetNoTarget()
    FM_CORE:ClearAllButtons()
end








