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
    if self:IsClassSupported(playerClass) ~= true then
        UnregisterEvents()
        logger:log_info('playerClass: ', playerClass,' not supported')
    else
        RegisterEvents()
        player_information:UpdateCharacter()
        logger:log_info('loaded playerClass: ', playerClass,' player name: ', self:GetPlayerName())
        self:CreateUI()
    end
end

function FM_CORE:OnSpellsChange()

end

function FM_CORE:CreateUI()
    FM_CORE:ResetPlayerCastBar()
end

function FM_CORE:ResetPlayerCastBar()
    if not self.cast_bar then
        self:CreatePlayerCastBar()
        return
    end

    -- hide the buttons, they will be show again if they are added back
    for _, value in pairs(self.ActionButtons) do
        value:Hide()
    end

    self:CreatePlayerCastBar()
    self:PushButtonState()
end

function FM_CORE:CreatePlayerCastBar()
    logger:log_debug("FM_CORE:CreatePlayerCastBar()")
    local margin, button_size = 2, 40
    local spell_lib = fm_libs[player_information:GetClass()]
    local know_spells, spell_count = player_information:GetKnownSpells(spell_lib)
    logger:log_debug("drawing spell count: ", spell_count)
    if not spell_count or spell_count < 1 then
        if self.cast_bar then
            self.cast_bar:Hide()
        end
        return
    end
    local displayFrame = self.cast_bar
    if not displayFrame then
        logger:log_debug("creating new display frame")
        displayFrame = CreateFrame("Frame", "ShadbroDisplayFrame", UIParent, "BackdropTemplate")
    end

    logger:log_debug("drawing spell count: ", spell_count)
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
    self.cast_bar = displayFrame

    for key, value in pairs(know_spells) do
        self:AddChild(displayFrame, button_size, key - 1 , margin, value)
    end
    self.cast_bar:Show()
end

function FM_CORE:AddChild(parentDisplayFrame, size, offset, margin, spell)
    if not self.textures then
        self.textures = {}
    end

    if not self.ActionButtons then
        self.ActionButtons = {}
    end

    if not self.cooldowns then
        self.cooldowns = {}
    end

    local spell_id = spell.spell_id
    local spellButton = self.ActionButtons[spell_id]
    if not spellButton then
        spellButton = CreateFrame("Button", nil, parentDisplayFrame, "SecureActionButtonTemplate")

        self.textures[spell_id] = spellButton:CreateTexture(nil, "BACKGROUND")
        self.textures[spell_id]:SetAllPoints(spellButton)
        self.textures[spell_id]:SetTexture(spell.texture)
        self.textures[spell_id]:SetDesaturation(.9)
        spellButton:SetNormalTexture(self.textures[spell_id])

        spellButton["_PixelGlow"] = spell.spell_id
        spellButton:SetAttribute("type","spell");-- Set type to "macro"
        spellButton:SetAttribute("spell", spell.name);-- Set our macro text



        self.cooldowns[spell_id] = CreateFrame("Cooldown", spell_id, spellButton, "CooldownFrameTemplate")
        self.cooldowns[spell_id] = CreateFrame("Cooldown", "myCooldown", spellButton, "CooldownFrameTemplate")
        self.cooldowns[spell_id]:SetAllPoints()
        self.cooldowns[spell_id]:SetCooldown(0, 0)

    end
    spellButton:SetParent(parentDisplayFrame)
    spellButton:SetWidth(size)
    spellButton:SetHeight(size)
    spellButton:SetPoint("TOPLEFT", offset * size + margin + offset * margin, -margin )

    -- spellButton:Show()
    self.ActionButtons[spell_id] = spellButton
    self.ActionButtons[spell_id]:Show()
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
        if not self.ActionButtons[spell.spell_id] then

        else
            if spell.is_next then
                self.textures[spell.spell_id]:SetAllPoints()
                self.textures[spell.spell_id]:SetDesaturation(0)
                self:SetGlow(spell.spell_id)
            else
                self.textures[spell.spell_id]:SetAllPoints()
                self.textures[spell.spell_id]:SetDesaturation(.9)
                self:UnsetGlow(spell.spell_id)
            end

            local start, duration = fm_libs[player_information:GetClass()]:GetSpellCooldown(spell.spell_id, self.target_info)
            logger:log_debug("start: ", start, "duration: ", duration, "spell: ", spell.spell_id)
            self.cooldowns[spell.spell_id]:SetCooldown(start, duration)
        end

    end
end

function FM_CORE:ClearAllButtons()
    for _, spell in pairs(fm_libs[player_information:GetClass()]:GetSpells()) do
        self.textures[spell.spell_id]:SetAllPoints()
        self.textures[spell.spell_id]:SetDesaturation(.9)
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
    self:HandleTargetChange()
end

function FM_CORE:HandlePlayerAuraUpdate()
    logger:log_debug('FM_CORE:HandlePlayerAuraUpdate')
    player_information:OnAuraChange()
    self:HandleTargetChange()
end

function FM_CORE:HandlePlayerTalentUpdate()
    logger:log_debug('FM_CORE: updating player information for talent change')
    local spell_lib = fm_libs[player_information:GetClass()]
    player_information:OnSpecChange(spell_lib)
    -- FM_CORE:HandleTargetChange()
    self:ResetPlayerCastBar()
    logger:log_info('spec changed. loaded playerClass: ', player_information:GetClass(),' player name: ', self:GetPlayerName())
end

function FM_CORE:SetInCombat(in_combat)
    player_information:SetInCombat(in_combat)
end

function FM_CORE:SetUpdateCooldown()
    if not self.target_info then
        self.target_info = CreateTarget()
    end
    fm_libs[player_information:GetClass()]:ChooseNext(player_information, self.target_info)
    self:PushButtonState()
end

function FM_CORE:HandleTargetChange()
    if not self.target_info then
        self.target_info = CreateTarget()
    end

    self.target_info:OnTargetChange()
    fm_libs[player_information:GetClass()]:ChooseNext(player_information, self.target_info)

    if self.target_info:IsFriendly() or self.target_info:IsNoTarget() then
        self:ClearAllButtons()
        return
    end

    self:PushButtonState()
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
    if not self.target_info then
        self.target_info = CreateTarget()
    end
    logger:log_debug("update_cooldown: spell_id: ", spell_id)
    -- player_information:StopCasting(spell_id)
    fm_libs[player_information:GetClass()]:ChooseNext(player_information, self.target_info, spell_id)
    self:PushButtonState()
    -- logger:log_debug("stop_casting")
end

function FM_CORE:HandleUpdateCoolldown()
    if not self.target_info then
        self.target_info = CreateTarget()
    end
    logger:log_debug("cast_complete: spell_id: ", spell_id)
    player_information:StopCasting(spell_id)
    fm_libs[player_information:GetClass()]:ChooseNext(player_information, self.target_info, spell_id)
    self:PushButtonState()
    -- logger:log_debug("stop_casting")
end

function FM_CORE:PushNext(spell_id)
    -- if not self.target_info then
    --     self.target_info = CreateTarget()
    -- end
    -- fm_libs[player_information:GetClass()]:ChooseNext(player_information, self.target_info, spell_id)
end

function FM_CORE:HandleTargetAuraUpdate()
    self:HandleTargetChange()
end

function FM_CORE:SetSelfTarget()
    self:ClearAllButtons()
end

function FM_CORE:SetFriendlyTarget()
    self:ClearAllButtons()
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








