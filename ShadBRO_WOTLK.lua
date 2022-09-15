local title = ...
local version = GetAddOnMetadata(title, "Version")

-- 
-- Face Melter
-- An addon by Falie, aka Drescan or Aytherine
-- Updated for TBC Classic by sbd74/havoc74
-- Let's squeeze some more DPS out of a broken spec... 
--

sbd:set_debug(true)

local LCG = LibStub("LibCustomGlow-1.0")

-- Our base array
Shadbro = {}
Shadbro.events = {}
Shadbro.textureList = {}
Shadbro.GetNext = function ()
    sbd:log_debug('empty')
end

-- Frame to watch for events
Shadbro.eventFrame = CreateFrame("Frame")
Shadbro.eventFrame:SetScript("OnEvent", function(this, event, ...)
    Shadbro.events[event](...)
end)

-- Define our Event Handlers here
Shadbro.eventFrame:RegisterEvent("ADDON_LOADED")
Shadbro.eventFrame:RegisterEvent("PLAYER_LOGIN")
Shadbro.eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
Shadbro.eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
Shadbro.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
Shadbro.eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
Shadbro.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
Shadbro.eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
Shadbro.lastSpellCast = 1


function Shadbro.events.SPELL_UPDATE_COOLDOWN()
    -- sbd:log_debug('event: SPELL_UPDATE_COOLDOWN')

    -- if not Shadbro.lastSpellCast then
    --     return
    -- end

    -- local name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(61304)
    -- -- sbd:log_debug(name, "_", rank,"_",icon,"_",castTime, "_", minRange, "_", maxRange)

    -- start, duration, enabled, modRate = GetSpellCooldown(61304)
    -- -- sbd:log_debug('event: SPELL_CAST_SUCCESS_GCD', GCD, 'duration:', duration)
    -- start, duration, enabled, modRate = GetSpellCooldown(Shadbro.lastSpellCast)
    -- C_Timer.After(duration, function ()
    --     print("timedone", duration)
    -- end)

    -- Shadbro.lastSpellCast = nil

end

function Shadbro.events.UNIT_SPELLCAST_CHANNEL_STOP(unitTarget, castGUID, spellID)
    sbd:log_debug('event: UNIT_SPELLCAST_CHANNEL_STOP')

end

function Shadbro.events.PLAYER_LOGIN()
    sbd:log_debug('event: PLAYER_LOGIN')

    Shadbro.playerName = UnitName("player")
    Shadbro.spellHaste = GetCombatRatingBonus(20)

end

function Shadbro.events.ADDON_LOADED(addon)
    if addon ~= "ShadBRO" then
        return
    end

    sbd:log_debug('event: ADDON_LOADED')

    local _, playerClass = UnitClass("player")
    if playerClass ~= "PRIEST" then
        return
    end

    if playerClass == "PRIEST" then
        LoadPriestSpells()
    end

    Shadbro:CreateGUI()

    Shadbro.GetNext()
end


function Shadbro.events.COMBAT_LOG_EVENT_UNFILTERED(...)
    --sbd:log_debug('event: COMBAT_LOG_EVENT_UNFILTERED')

    local timestamp, event, _, _, sourceName, _, _, dstGUID, dstName, _, _, spellId, spellName, _, _, _, _, resisted = CombatLogGetCurrentEventInfo()

    if sourceName == Shadbro.playerName and dstName ~= Shadbro.playerName then
        -- sbd:log_debug('event: ', event)
        -- print(CombatLogGetCurrentEventInfo())
        if event == "SPELL_CAST_START" then
            sbd:log_debug('event: SPELL_CAST_START')
        elseif event == "SPELL_DAMAGE" then
            -- spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
            sbd:log_debug('event: SPELL_DAMAGE', ' name: ', spellName, ' dstGUID:', dstGUID)
        elseif event == "SPELL_AURA_APPLIED" then
            -- sbd:log_debug('event: SPELL_AURA_APPLIED', ' name: ', spellName, ' dstGUID:', dstGUID)
            TargetAuraAdd(dstGUID, spellId)
            
            sbd:log_debug('event: SPELL_AURA_APPLIED', ' name: ', spellName, 'spellid', spellId,' dstGUID:', dstGUID, ' expiration:', Shadbro.TargetList[dstGUID].Auras[spellId], 'current: ',GetTime())
            Shadbro.FindNextSpell()
        elseif event == "SPELL_AURA_APPLIED_DOSE" then
            -- sbd:log_debug('event: SPELL_AURA_APPLIED_DOSE', ' name: ', spellName, ' dstGUID:', dstGUID)
        elseif event == "SPELL_AURA_REFRESH" then
            sbd:log_debug('event: SPELL_AURA_REFRESH', ' name: ', spellName, ' dstGUID:', dstGUID)
        elseif event == "SPELL_AURA_REMOVED" then
            -- sbd:log_debug('event: SPELL_AURA_REMOVED', ' name: ', spellName, ' dstGUID:', dstGUID)
            TargetAuraRemove(dstGUID, spellId)
            Shadbro.FindNextSpell()
        elseif event == "SPELL_PERIODIC_DAMAGE" then
            -- sbd:log_debug('event: SPELL_PERIODIC_DAMAGE', ' name: ', spellName, ' dstGUID:', dstGUID)
        elseif event == "SPELL_CAST_SUCCESS" then
            -- sbd:log_debug('event: SPELL_CAST_SUCCESS')
            Shadbro.FindNextSpell()
            Shadbro.lastSpellCast = spellId
        elseif event == "SPELL_MISSED" then -- aww we get reisted, we only care if it's a debuff though
            -- sbd:log_debug('event: SPELL_MISSED', ' resisted: ', resisted)
            Shadbro.FindNextSpell()
        end

    end
end

function Shadbro.events.UNIT_SPELLCAST_SUCCEEDED(unitTarget, castGUID, spellID)
    sbd:log_debug('event: UNIT_SPELLCAST_SUCCEEDED')
end

function Shadbro.events.UNIT_SPELLCAST_FAILED(unitTarget, castGUID, spellID)
    sbd:log_debug('event: UNIT_SPELLCAST_FAILED')
end

function Shadbro.events.PLAYER_TARGET_CHANGED(...)
    sbd:log_debug('event: PLAYER_TARGET_CHANGED')

    -- target changed, set last target, update current target, will be nil if no target
    if UnitName("target") == nil or UnitIsFriend("player", "target") == true or UnitHealth("target") == 0 then
        return
    end
    Shadbro.FindNextSpell()
    Shadbro:PushChanges()
end

Shadbro.TargetList = {}

function TargetAuraAdd(targetGuid, spellId)
    local expirationTime = Shadbro.GetDotExpiration(spellId)
    if not expirationTime then
        return
    end
    if not Shadbro.TargetList[targetGuid] then
        Shadbro.TargetList[targetGuid] = {}
    end

    if not Shadbro.TargetList[targetGuid].Auras then 
        Shadbro.TargetList[targetGuid].Auras = {}
    end

    Shadbro.TargetList[targetGuid].Auras[spellId] = expirationTime
end

function TargetAuraUpdate(targetGuid, spellId)
    if not Shadbro.TargetList[targetGuid] then
        Shadbro.TargetList[targetGuid] = {}
    end

    if not Shadbro.TargetList[targetGuid].Auras then 
        Shadbro.TargetList[targetGuid].Auras = {}
    end

    local expirationTime = Shadbro.GetDotExpiration(spellId)
    if not expirationTime then
        return
    end

    Shadbro.TargetList[targetGuid].Auras[spellId] = expirationTime
end

function TargetAuraRemove(targetGuid, spellId)
    if not Shadbro.TargetList[targetGuid] then
        return
    end
    if not Shadbro.TargetList[targetGuid].Auras or 
        not Shadbro.TargetList[targetGuid].Auras[spellId] then
        return
    end

    sbd:log_debug('event: SPELL_AURA_REMOVED', ' name: ', spellId, ' dstGUID:', targetGuid, 'current: ',GetTime())

end

function TargetAuraIsPresent(targetGuid, spellId)
    sbd:log_debug('event: TargetAuraIsPresent', ' name: ', spellId, ' dstGUID:', targetGuid, 'current: ',GetTime(), ' expiration:')
    if not Shadbro.TargetList[targetGuid] then
        sbd:log_debug('no guid', targetGuid,'C_Timer' ,spellId)
        return false
    end
    if not Shadbro.TargetList[targetGuid].Auras or not Shadbro.TargetList[targetGuid].Auras[spellId] then
        sbd:log_debug('no aura')
        return false
    end

    sbd:log_debug('event: TargetAuraIsPresent', ' name: ', spellId, ' dstGUID:', targetGuid, 'current: ',GetTime(), ' expiration:')
    return Shadbro.TargetList[targetGuid].Auras[spellId] - GetTime() > 0
    -- sbd:log_debug('event: SPELL_AURA_REMOVED', ' name: ', spellId, ' dstGUID:', targetGuid, 'current: ',GetTime())

end

function Shadbro.FindNextSpell()
    print("FindNextSpell")
    Shadbro:PushChanges()
    local targetGuid = UnitGUID("target")
    for Key,Value in pairs(Shadbro.Priority) do --pseudocode
        -- id := Value.SpellId
        if Shadbro.SpellList[Value].IsDot == true then
            -- This one checks if it's a dot and we have an aura ready to go
            if TargetAuraIsPresent(targetGuid, Value) == false then
                sbd:log_debug('NextSpell:', Shadbro.SpellList[Value].Name)
                return
            end

            -- Check to see if regular spell
        end
    end
end

function Shadbro:PushChanges()
    -- Check the status of your dots
    local targetGuid = UnitGUID("target")
    -- Highlight any dots that aren't present
    local Value = Shadbro.SpellList[Spell_priest_shadowWordPain.SpellId]
    if TargetAuraIsPresent(targetGuid, Spell_priest_shadowWordPain.SpellId) == false then
        sbd:log_debug('function: TargetAuraIsPresent false')
        -- LCG.PixelGlow_Start(Shadbro.displayFrame_next)
        local r,color,N,frequency,length,th,xOffset,yOffset,border,key,frameLevel
        frameLevel = 8
        key = "ham"
        LCG.PixelGlow_Start(Shadbro.displayFrame_next, color,N,frequency,length,th,xOffset,yOffset,border,key,frameLevel)
    else
        sbd:log_debug('function: TargetAuraIsPresent true')
        
        local r,color,N,frequency,length,th,xOffset,yOffset,border,key,frameLevel
        frameLevel = 8
        key = "ham"
        LCG.PixelGlow_Stop(Shadbro.displayFrame_next, key)
        -- Shadbro.displayFrame_next:SetText("ham")
    end
    
    
end

function Shadbro:CreateGUI()
    sbd:log_debug('function: CreateGUI')

    local displayFrame = CreateFrame("Frame", "ShadbroDisplayFrame", UIParent, "BackdropTemplate")
    displayFrame:SetFrameStrata("BACKGROUND")
    displayFrame:SetWidth(250)
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
        sbd:log_debug('event: displayFrame: OnMouseDown')

        self:StartMoving()
    end)

    displayFrame:SetScript("OnMouseUp", function(self)
        sbd:log_debug('event: displayFrame: OnMouseUp')

        self:StopMovingOrSizing()
    end)

    displayFrame:SetScript("OnDragStop", function(self)
        sbd:log_debug('event: displayFrame: OnDragStop')
        self:StopMovingOrSizing()
    end)

    displayFrame:SetPoint("CENTER", -200, -200)

    DisplayFrame_next = CreateFrame("Button", nil, ShadbroDisplayFrame, "SecureActionButtonTemplate")
    -- displayFrame_last:SetWidth(40)
    DisplayFrame_next:SetWidth(40)
    DisplayFrame_next:SetHeight(40)
    -- displayFrame_next.flashing = 1;
    DisplayFrame_next:SetPoint("TOPLEFT", 170, -10)
    
    
    
    

    DisplayFrame_next:SetButtonState("Normal")
    local t = DisplayFrame_next:CreateTexture(nil, "BACKGROUND")
    -- t:SetTexture(nil)
    t:SetAllPoints(DisplayFrame_next)
    t:SetTexture(Shadbro.SpellTextures[Spell_priest_shadowWordPain.SpellId])
    -- displayFrame_next.texture = t
    DisplayFrame_next:SetNormalTexture(t)


    t = DisplayFrame_next:CreateTexture(nil, "BACKGROUND")
    -- t:SetTexture(nil)
    t:SetAllPoints(DisplayFrame_next)
    t:SetTexture(Shadbro.SpellTextures[Spell_priest_shadowWordPain.SpellId])
    t:SetDesaturation(.5)
    -- displayFrame_next.texture = t
    -- DisplayFrame_next:SetHighlightTexture("Interface\\Icons\\Spell_shadow_carrionswarm")
    DisplayFrame_next:SetPushedTexture(t)
    -- displayFrame_next:SetToplevel(true)
    -- displayFrame_next:Show()
    -- displayFrame_next.texture = t
    local r,color,N,frequency,length,th,xOffset,yOffset,border,key,frameLevel
    key = "ham"
    DisplayFrame_next["_PixelGlow"] = key
    DisplayFrame_next["_PixelGlow"] = key
    -- LCG.ButtonGlow_Start(DisplayFrame_next)
    -- displayFrame_next:SetNormalTexture(Spell_priest_shadowWordPain.texture)
    -- Shadbro.textureList["next"] = t

    -- local MacroButton=CreateFrame("Button","MyMacroButton",nil,"SecureActionButtonTemplate");
    -- DisplayFrame_next:RegisterForClicks("AnyUp");--   Respond to all buttons
    DisplayFrame_next:SetAttribute("type","action");-- Set type to "macro"
    DisplayFrame_next:SetAttribute("action",Spell_priest_shadowWordPain.ActionButton[1]);-- Set our macro text

    -- DisplayFrame_next:SetScript("OnClick", function(self, button, down)
    --     -- LCG:ButtonGlow_Stop(button)
    --     -- LCG.ButtonGlow_Start(self)
    --     LCG.ButtonGlow_Stop(self)

    -- end)
    Shadbro.displayFrame_next = DisplayFrame_next

    displayFrame:Show()
    -- Shadbro.textureList["next"]:SetTexture(Shadbro.SpellTextures[Spell_priest_shadowWordPain.SpellId])

end

function Shadbro:CreateGUI2()
    sbd:log_debug('function: CreateGUI')

    local displayFrame = CreateFrame("Frame", "ShadbroDisplayFrame", UIParent, "BackdropTemplate")
    displayFrame:SetFrameStrata("BACKGROUND")
    displayFrame:SetWidth(250)
    displayFrame:SetHeight(50)

    displayFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = true,
        tileSize = 32
    })
    local button = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    
    displayFrame:SetBackdropColor(0, 0, 0, .4)
    displayFrame:EnableMouse(true)
    displayFrame:SetMovable(true)
    -- displayFrame:RegisterForDrag("LeftButton")  --causes right buttont to go crazy, go figure
    displayFrame:SetClampedToScreen(true)

    displayFrame:SetScript("OnMouseDown", function(self)
        sbd:log_debug('event: displayFrame: OnMouseDown')

        self:StartMoving()
    end)

    displayFrame:SetScript("OnMouseUp", function(self)
        sbd:log_debug('event: displayFrame: OnMouseUp')

        self:StopMovingOrSizing()
    end)

    displayFrame:SetScript("OnDragStop", function(self)
        sbd:log_debug('event: displayFrame: OnDragStop')
        self:StopMovingOrSizing()
    end)

    displayFrame:SetPoint("CENTER", -200, -200)
    local displayFrame_last = CreateFrame("Frame", "$parent_last", ShadbroDisplayFrame)
    local displayFrame_currentHighlight = CreateFrame("Frame", "$parent_currentHighlight", ShadbroDisplayFrame)
    local displayFrame_current = CreateFrame("Frame", "$parent_current", ShadbroDisplayFrame_currentHighlight)
    -- local displayFrame_next = CreateFrame("Frame", "$parent_next", ShadbroDisplayFrame)
    local displayFrame_next = CreateFrame("Button", nil, ShadbroDisplayFrame, "SecureActionButtonTemplate")

    displayFrame_last:SetWidth(40)
    displayFrame_current:SetWidth(40)
    displayFrame_currentHighlight:SetWidth(80)
    displayFrame_next:SetWidth(40)

    displayFrame_last:SetHeight(40)
    displayFrame_current:SetHeight(40)
    displayFrame_currentHighlight:SetHeight(80)
    displayFrame_next:SetHeight(40)
    displayFrame_next.flashing = 1;
    displayFrame_last:SetPoint("TOPLEFT", 10, -10)
    displayFrame_currentHighlight:SetPoint("TOPLEFT", 85, -5)
    displayFrame_current:SetPoint("TOPLEFT", 5, -5)
    displayFrame_next:SetPoint("TOPLEFT", 170, -10)

    -- highlight = GetHighlightTexture()
    -- displayFrame_next:SetHighlightTexture(Spell_priest_devouringPlague.ActionButton[1])
    -- displayFrame_next:LockHighlight()

    local t = displayFrame_last:CreateTexture(nil, "BACKGROUND")
    t:SetTexture(nil)
    t:SetAllPoints(displayFrame_last)
    t:SetAlpha(.2)
    displayFrame_last.texture = t
    Shadbro.textureList["last"] = t

    t = displayFrame_current:CreateTexture(nil, "BACKGROUND")
    t:SetTexture(nil)
    t:ClearAllPoints()
    t:SetAllPoints(displayFrame_current)
    displayFrame_current.texture = t
    Shadbro.textureList["current"] = t

    t = displayFrame_next:CreateTexture(nil, "BACKGROUND")
    t:SetTexture(Spell_priest_shadowWordPain.texture)
    -- t:SetAllPoints(displayFrame_next)
    t:SetDesaturated(.5)
    -- t:SetAlpha(.5)

    -- -- t:("Interface\\Icons\\Inv_misc_archaeology_amburfly")
    -- -- t:SetHighlightTexture("Interface\\Icons\\Spell_shadow_carrionswarm")
    -- -- t:SetNormalTexture("Interface\\Icons\\Spell_druid_swarm")
    displayFrame_next.texture = t
    displayFrame_next:SetHighlightTexture("Interface\\Icons\\Spell_shadow_carrionswarm")
    displayFrame_next:SetPushedTexture("Interface\\Icons\\Spell_druid_swarm")
    displayFrame_next:SetToplevel(true)

    -- displayFrame_next:SetNormalTexture(Spell_priest_shadowWordPain.texture)
    Shadbro.textureList["next"] = t

    -- t = displayFrame_currentHighlight:CreateTexture(nil, "BACKGROUND")
    -- t:SetTexture(.1, .5, .1)
    -- t:SetAllPoints(displayFrame_currentHighlight)
    -- t:SetAlpha(0)
    -- displayFrame_currentHighlight.texture = t
    -- Shadbro.textureList["highlight"] = t

    -- local MacroButton=CreateFrame("Button","MyMacroButton",nil,"SecureActionButtonTemplate");
    displayFrame_next:RegisterForClicks("AnyUp");--   Respond to all buttons
    displayFrame_next:SetAttribute("type","action");-- Set type to "macro"
    displayFrame_next:SetAttribute("action",Spell_priest_shadowWordPain.ActionButton[1]);-- Set our macro text


    -- C_Timer.After(3, function ()
    --     displayFrame_next:SetEnabled(false)
    --     -- t = displayFrame_next.texture
    --     -- t:SetAllPoints(displayFrame_next)
    --     -- t:SetDesaturated(1)
    --     -- displayFrame_next.texture = t
    --     -- self:SetDesaturated(1)
    -- end)
    -- displayFrame_next:SetScript("OnClick", function(self, button, down)
    --     -- self:SetTexture(Spell_priest_shadowWordPain.texture)
    --     -- t = displayFrame_next.texture
    --     -- t:SetDesaturated(0)
    --     -- displayFrame_next.texture = t
    --     -- self:SetDesaturated(1)
    --     print("clicked")
    -- end)
    -- displayFrame:SetScript("OnUpdate", function(this, elapsed)
    --     -- sbd:log_debug('event: displayFrame: OnUpdate')

    --     Shadbro:OnUpdate(elapsed)
    -- end)

    local cooldownFrame = CreateFrame("Cooldown", "$parent_cooldown", ShadbroDisplayFrame_current)
    cooldownFrame:SetHeight(70)
    cooldownFrame:SetWidth(70)
    cooldownFrame:ClearAllPoints()
    cooldownFrame:SetPoint("CENTER", displayFrame_current, "CENTER", 0, 0)

    Shadbro.displayFrame = displayFrame
    Shadbro.displayFrame_last = displayFrame_last
    Shadbro.displayFrame_current = displayFrame_current
    Shadbro.displayFrame_next = displayFrame_next
    Shadbro.displayFrame_currentHighlight = displayFrame_currentHighlight
    Shadbro.cooldownFrame = cooldownFrame



    -- local gcdbar = CreateFrame('Frame', 'ShadbroDisplayFrameGCDBar', UIParent)
    -- gcdbar:SetFrameStrata('HIGH')

    -- gcdbar:SetScript('OnShow', function()
    --     sbd:log_debug('event: gcdbar: OnShow')

    --     Shadbro.OnShowGCD()
    -- end)

    -- gcdbar:SetScript('OnHide', function()
    --     sbd:log_debug('event: gcdbar: OnHide')

    --     Shadbro.OnHideGCD()
    -- end)

    -- local gcdspark = gcdbar:CreateTexture(nil, 'DIALOG')
    -- Shadbro.gcdstart = 0
    -- Shadbro.gcdduration = 0
    -- gcdbar:ClearAllPoints()
    -- gcdbar:SetHeight(10)
    -- gcdbar:SetWidth(250)
    -- gcdbar:SetPoint("BOTTOM", ShadbroDisplayFrame, "TOP", 0, 0)
    -- gcdspark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    -- gcdspark:SetVertexColor(1, 1, 1)
    -- gcdspark:SetBlendMode('ADD')
    -- gcdspark:SetWidth(25)
    -- gcdspark:SetHeight(10)
    -- Shadbro.gcdbar = gcdbar
    -- Shadbro.gcdspark = gcdspark

    local displayFrame_options = CreateFrame("Frame", "$parent_options", ShadbroDisplayFrame)
    displayFrame_options:SetWidth(70)
    displayFrame_options:SetHeight(30)
    displayFrame_options:SetPoint("BOTTOMLEFT", 0, -0)

    local VEString = displayFrame_options:CreateFontString("Shadbro_VEString", "OVERLAY", "GameFontNormal")
    local SWDString = displayFrame_options:CreateFontString("Shadbro_SWDString", "OVERLAY", "GameFontNormal")
    VEString:SetText("VE")
    SWDString:SetText("SW:D")

    local VECheck = CreateFrame("CheckButton", "$parent_vecb", displayFrame_options, "OptionsCheckButtonTemplate")
    local SWDCheck = CreateFrame("CheckButton", "$parent_swdcb", displayFrame_options, "OptionsCheckButtonTemplate")
    VECheck:SetWidth(14)
    VECheck:SetHeight(14)
    SWDCheck:SetWidth(14)
    SWDCheck:SetHeight(14)

    -- VECheck:SetScript("OnClick", function()
    --     sbd:log_debug('event: VECheck: OnClick')

    --     FaceMelter:ToggleVE()
    -- end)

    -- SWDCheck:SetScript("OnClick", function()
    --     sbd:log_debug('event: SWDCheck: OnClick')

    --     FaceMelter:ToggleDeath()
    -- end)

    VEString:SetPoint("BOTTOMLEFT", 16, 20)
    VECheck:SetPoint("BOTTOMLEFT", 0, 19)
    SWDString:SetPoint("BOTTOMLEFT", 16, 0)
    SWDCheck:SetPoint("BOTTOMLEFT", 0, -1)

    -- VECheck:SetChecked(Shadbro:GetVE())
    -- SWDCheck:SetChecked(Shadbro:GetDeath())

    -- Shadbro.displayFrame_options = displayFrame_options
    -- Shadbro.VECheck = VECheck
    -- Shadbro.SWDCheck = SWDCheck

    -- Shadbro.displayFrame_options:SetAlpha(Shadbro.miniOptionsAlpha)
    displayFrame:Show()
    sbd:log_debug('function: texture', Shadbro.SpellTextures[Spell_priest_shadowWordPain.SpellId])
    Shadbro.textureList["last"]:SetTexture(GetActionTexture(Spell_priest_shadowWordPain.ActionButton[1]))
    
    Shadbro.textureList["current"]:SetTexture(Shadbro.SpellTextures[Spell_priest_shadowWordPain.SpellId])
    Shadbro.textureList["next"]:SetTexture(Shadbro.SpellTextures[Spell_priest_shadowWordPain.SpellId])

end

-- function FaceMelter:CreateOptionFrame()
--     sbd:log_debug('function: CreateOptionFrame')

--     local panel = CreateFrame("FRAME", "FaceMelterOptions")
--     panel.name = "Face Melter Classic"
--     local fstring1 = panel:CreateFontString("FaceMelterOptions_string1", "OVERLAY", "GameFontNormal")
--     local fstring2 = panel:CreateFontString("FaceMelterOptions_string2", "OVERLAY", "GameFontNormal")
--     local fstring3 = panel:CreateFontString("FaceMelterOptions_string3", "OVERLAY", "GameFontNormal")
--     local fstring4 = panel:CreateFontString("FaceMelterOptions_string4", "OVERLAY", "GameFontNormal")
--     local fstring5 = panel:CreateFontString("FaceMelterOptions_string4", "OVERLAY", "GameFontNormal")
--     fstring1:SetText("Lock")
--     fstring2:SetText("Include Vampiric Embrace ")
--     fstring3:SetText("Include Shadow Word: Death ")
--     fstring4:SetText("Health Percent for SW:D Cutoff")
--     fstring5:SetText("GUI Scale")
--     fstring1:SetPoint("TOPLEFT", 10, -10)
--     fstring2:SetPoint("TOPLEFT", 10, -40)
--     fstring3:SetPoint("TOPLEFT", 10, -70)
--     fstring4:SetPoint("TOPLEFT", 10, -100)
--     fstring5:SetPoint("TOPLEFT", 10, -130)

--     local checkbox1 = CreateFrame("CheckButton", "$parent_cb1", panel, "OptionsCheckButtonTemplate")
--     local checkbox2 = CreateFrame("CheckButton", "$parent_cb2", panel, "OptionsCheckButtonTemplate")
--     local checkbox3 = CreateFrame("CheckButton", "$parent_cb3", panel, "OptionsCheckButtonTemplate")
--     checkbox1:SetWidth(18)
--     checkbox1:SetHeight(18)
--     checkbox2:SetWidth(18)
--     checkbox2:SetHeight(18)
--     checkbox3:SetWidth(18)
--     checkbox3:SetHeight(18)

--     checkbox1:SetScript("OnClick", function()
--         sbd:log_debug('checkbox1: event: Onclick')

--         FaceMelter:ToggleLocked()
--     end)

--     checkbox2:SetScript("OnClick", function()
--         sbd:log_debug('checkbox2: event: Onclick')

--         FaceMelter:ToggleVE()
--     end)

--     checkbox3:SetScript("OnClick", function()
--         sbd:log_debug('checkbox3: event: Onclick')

--         FaceMelter:ToggleDeath()
--     end)

--     checkbox1:SetPoint("TOPRIGHT", -10, -10)
--     checkbox2:SetPoint("TOPRIGHT", -10, -40)
--     checkbox3:SetPoint("TOPRIGHT", -10, -70)
--     checkbox1:SetChecked(FaceMelter:GetLocked())
--     checkbox2:SetChecked(FaceMelter:GetVE())
--     checkbox3:SetChecked(FaceMelter:GetDeath())

--     FaceMelter.VECheck2 = checkbox2
--     FaceMelter.SWDCheck2 = checkbox3

--     local slider1 = CreateFrame("Slider", "$parent_sl1", panel, "OptionsSliderTemplate")
--     local slider2 = CreateFrame("Slider", "$parent_sl2", panel, "OptionsSliderTemplate")
--     slider1:SetMinMaxValues(0, 100)
--     slider2:SetMinMaxValues(.5, 1.5)
--     slider1:SetValue(FaceMelter:GetHealthPercent())
--     slider2:SetValue(FaceMelter:GetScale())
--     slider1:SetValueStep(1)
--     slider2:SetValueStep(.05)

--     slider1:SetScript("OnValueChanged", function(self)
--         sbd:log_debug('slider1: event: OnValueChanged')

--         FaceMelter:SetHealthPercent(self:GetValue())
--         getglobal(self:GetName() .. "Text"):SetText(self:GetValue())
--     end)

--     slider2:SetScript("OnValueChanged", function(self)
--         sbd:log_debug('slider2: event: OnValueChanged')

--         FaceMelter:SetScale(self:GetValue())
--         getglobal(self:GetName() .. "Text"):SetText(self:GetValue())
--     end)

--     getglobal(slider1:GetName() .. "Low"):SetText("1")
--     getglobal(slider1:GetName() .. "High"):SetText("100")
--     getglobal(slider1:GetName() .. "Text"):SetText(FaceMelter:GetHealthPercent())
--     getglobal(slider2:GetName() .. "Low"):SetText("0.5")
--     getglobal(slider2:GetName() .. "High"):SetText("1.5")
--     getglobal(slider2:GetName() .. "Text"):SetText(FaceMelter:GetScale())
--     slider1:SetPoint("TOPRIGHT", -10, -100)
--     slider2:SetPoint("TOPRIGHT", -10, -130)

--     local fstring6 = panel:CreateFontString("FaceMelterOptions_string6", "OVERLAY", "GameFontNormal")
--     local fstring7 = panel:CreateFontString("FaceMelterOptions_string7", "OVERLAY", "GameFontNormal")
--     local fstring8 = panel:CreateFontString("FaceMelterOptions_string8", "OVERLAY", "GameFontNormal")
--     local fstring9 = panel:CreateFontString("FaceMelterOptions_string9", "OVERLAY", "GameFontNormal")
--     local fstring10 = panel:CreateFontString("FaceMelterOptions_string10", "OVERLAY", "GameFontNormal")
--     local fstring6a = panel:CreateFontString("FaceMelterOptions_string6a", "OVERLAY", "GameFontNormal")
--     fstring6a:SetText("Priority List: 1 is first, 5 is last.")
--     fstring6:SetText("SW: Pain")
--     fstring7:SetText("Vampiric Touch")
--     fstring8:SetText("Mind Blast")
--     fstring9:SetText("SW: Death")
--     fstring10:SetText("Vampric Embrace")
--     fstring6a:SetPoint("TOPLEFT", 10, -160)
--     fstring6:SetPoint("TOPLEFT", 10, -190)
--     fstring7:SetPoint("TOPLEFT", 10, -220)
--     fstring8:SetPoint("TOPLEFT", 10, -250)
--     fstring9:SetPoint("TOPLEFT", 10, -280)
--     fstring10:SetPoint("TOPLEFT", 10, -310)

--     local slider3 = CreateFrame("Slider", "FaceMelterOptions_sl_SWP", panel, "OptionsSliderTemplate")
--     local slider4 = CreateFrame("Slider", "FaceMelterOptions_sl_VT", panel, "OptionsSliderTemplate")
--     local slider5 = CreateFrame("Slider", "FaceMelterOptions_sl_MB", panel, "OptionsSliderTemplate")
--     local slider6 = CreateFrame("Slider", "FaceMelterOptions_sl_SWD", panel, "OptionsSliderTemplate")
--     local slider7 = CreateFrame("Slider", "FaceMelterOptions_sl_VE", panel, "OptionsSliderTemplate")
--     slider3:SetMinMaxValues(1, 5)
--     slider4:SetMinMaxValues(1, 5)
--     slider5:SetMinMaxValues(1, 5)
--     slider6:SetMinMaxValues(1, 5)
--     slider7:SetMinMaxValues(1, 5)
--     slider3:SetValueStep(1)
--     slider4:SetValueStep(1)
--     slider5:SetValueStep(1)
--     slider6:SetValueStep(1)
--     slider7:SetValueStep(1)
--     slider3:SetValue(FaceMelter:GetPri("SWP"))
--     slider4:SetValue(FaceMelter:GetPri("VT"))
--     slider5:SetValue(FaceMelter:GetPri("MB"))
--     slider6:SetValue(FaceMelter:GetPri("SWD"))
--     slider7:SetValue(FaceMelter:GetPri("VE"))
--     getglobal(slider3:GetName() .. "Low"):SetText("1")
--     getglobal(slider3:GetName() .. "High"):SetText("5")
--     getglobal(slider3:GetName() .. "Text"):SetText(FaceMelter:GetPri("SWP"))
--     getglobal(slider4:GetName() .. "Low"):SetText("1")
--     getglobal(slider4:GetName() .. "High"):SetText("5")
--     getglobal(slider4:GetName() .. "Text"):SetText(FaceMelter:GetPri("VT"))
--     getglobal(slider5:GetName() .. "Low"):SetText("1")
--     getglobal(slider5:GetName() .. "High"):SetText("5")
--     getglobal(slider5:GetName() .. "Text"):SetText(FaceMelter:GetPri("MB"))
--     getglobal(slider6:GetName() .. "Low"):SetText("1")
--     getglobal(slider6:GetName() .. "High"):SetText("5")
--     getglobal(slider6:GetName() .. "Text"):SetText(FaceMelter:GetPri("SWD"))
--     getglobal(slider7:GetName() .. "Low"):SetText("1")
--     getglobal(slider7:GetName() .. "High"):SetText("5")
--     getglobal(slider7:GetName() .. "Text"):SetText(FaceMelter:GetPri("VE"))
--     slider3:SetPoint("TOPRIGHT", -10, -190)
--     slider4:SetPoint("TOPRIGHT", -10, -220)
--     slider5:SetPoint("TOPRIGHT", -10, -250)
--     slider6:SetPoint("TOPRIGHT", -10, -280)
--     slider7:SetPoint("TOPRIGHT", -10, -310)

--     slider3:SetScript("OnValueChanged", function(self)
--         sbd:log_debug('slider3: event: OnValueChanged')

--         FaceMelter:SetPri("SWP", self:GetValue())
--         getglobal(self:GetName() .. "Text"):SetText(self:GetValue())
--     end)

--     slider4:SetScript("OnValueChanged", function(self)
--         sbd:log_debug('slider4: event: OnValueChanged')

--         FaceMelter:SetPri("VT", self:GetValue())
--         getglobal(self:GetName() .. "Text"):SetText(self:GetValue())
--     end)

--     slider5:SetScript("OnValueChanged", function(self)
--         sbd:log_debug('slider5: event: OnValueChanged')

--         FaceMelter:SetPri("MB", self:GetValue())
--         getglobal(self:GetName() .. "Text"):SetText(self:GetValue())
--     end)

--     slider6:SetScript("OnValueChanged", function(self)
--         sbd:log_debug('slider6: event: OnValueChanged')

--         FaceMelter:SetPri("SWD", self:GetValue())
--         getglobal(self:GetName() .. "Text"):SetText(self:GetValue())
--     end)

--     slider7:SetScript("OnValueChanged", function(self)
--         sbd:log_debug('slider7: event: OnValueChanged')

--         FaceMelter:SetPri("VE", self:GetValue())
--         getglobal(self:GetName() .. "Text"):SetText(self:GetValue())
--     end)

--     local fstringMO = panel:CreateFontString("FaceMelterOptions_stringMO", "OVERLAY", "GameFontNormal")
--     fstringMO:SetText("Mini Options Alpha")
--     fstringMO:SetPoint("TOPLEFT", 10, -340)

--     local sliderMO = CreateFrame("Slider", "$parent_sMO", panel, "OptionsSliderTemplate")
--     sliderMO:SetMinMaxValues(0, 1)
--     sliderMO:SetValue(facemelterdb.miniOptionsAlpha)
--     sliderMO:SetValueStep(.05)
--     sliderMO:SetScript("OnValueChanged", function(self)
--         sbd:log_debug('sliderMO: event: OnValueChanged')

--         FaceMelter:SetMiniAlpha(self:GetValue())
--         getglobal(self:GetName() .. "Text"):SetText(self:GetValue())
--     end)
--     getglobal(sliderMO:GetName() .. "Low"):SetText("0")
--     getglobal(sliderMO:GetName() .. "High"):SetText("1")
--     getglobal(sliderMO:GetName() .. "Text"):SetText(facemelterdb.miniOptionsAlpha)
--     sliderMO:SetPoint("TOPRIGHT", -10, -340)

--     InterfaceOptions_AddCategory(panel)
-- end

-- -- function Shadbro.IsDotOnTarget(id)
-- --     for i=1,40 do 
-- --         local name, _, count, _, expirationTime, duration, source, _, _, spellId, canApplyAura, _, _, _, _ = UnitDebuff("target",i)
-- --         -- and spellId == ShadowWordPainId
-- --         if source == "player"  and spellId == id then 
-- --             -- sbd:log_debug("Checking target: ", name, ":",source, ":",spellId, ":",canApplyAura, " duration: ", duration, "expiration: ", expirationTime)
-- --             return true
-- --         end
-- --     end
-- --     return false
-- -- end

function Shadbro.GetDotExpiration(id)
    for i=1,40 do 
        local name, _, count, _, duration, expirationTime, source, _, _, spellId, canApplyAura, _, _, _, _ = UnitDebuff("target",i)
        -- and spellId == ShadowWordPainId
        if source == "player"  and spellId == id then 
            -- sbd:log_debug("Checking target: ", name, ":",source, ":",spellId, ":",canApplyAura, " duration: ", duration, "expiration: ", expirationTime)
            return expirationTime
        end
    end
    return nil
end