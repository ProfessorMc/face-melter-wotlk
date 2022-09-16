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
Shadbro             = {}
Shadbro.events      = {}
Shadbro.textureList = {}
Shadbro.targetAuras = {}
Shadbro.playerAuras = {}

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
    if addon ~= "FaceMelterWotlk" then
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
            Shadbro:PushChanges()
        elseif event == "SPELL_DAMAGE" then
            -- spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
            sbd:log_debug('event: SPELL_DAMAGE', ' name: ', spellName, ' dstGUID:', dstGUID)
            Shadbro:PushChanges()
        elseif event == "SPELL_AURA_APPLIED" then
            -- sbd:log_debug('event: SPELL_AURA_APPLIED', ' name: ', spellName, ' dstGUID:', dstGUID)
            TargetAuraAdd(dstGUID, spellId)
            
            sbd:log_debug('event: SPELL_AURA_APPLIED', ' name: ', spellName, 'spellid', spellId,' dstGUID:', dstGUID, ' expiration:', Shadbro.TargetList[dstGUID].Auras[spellId], 'current: ',GetTime())
            Shadbro.FindNextSpell()
        elseif event == "SPELL_AURA_APPLIED_DOSE" then
            -- sbd:log_debug('event: SPELL_AURA_APPLIED_DOSE', ' name: ', spellName, ' dstGUID:', dstGUID)
            Shadbro:PushChanges()
        elseif event == "SPELL_AURA_REFRESH" then
            sbd:log_debug('event: SPELL_AURA_REFRESH', ' name: ', spellName, ' dstGUID:', dstGUID)
            Shadbro:PushChanges()
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
    Shadbro:RefreshPlayerAuras()
    Shadbro:RefreshTargetAuras()
    -- target changed, set last target, update current target, will be nil if no target
    -- if UnitName("target") == nil or UnitIsFriend("player", "target") == true or UnitHealth("target") == 0 then
    --     return
    -- end
    -- Shadbro.FindNextSpell()
    -- Shadbro:PushChanges()
end

Shadbro.TargetList = {}
function Shadbro.ResetTargetAuras()
end

local MAX_PLAYER_AURAS          = 40
Shadbro.playerAura              = {}

local function refreshAura(auraList, target, isHelpful)
    local auraType = "HELPFUL"
    if isHelpful == false then
        auraType = "HARMFUL"
    end
    for i=1, MAX_PLAYER_AURAS do 
        local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura= UnitAura(target,i, auraType)
        if name then
            local playAura              = {}
            playAura.name               = name
            playAura.icon               = icon
            playAura.dispelType         = dispelType
            playAura.duration           = duration
            playAura.count              = count
            playAura.expirationTime     = expirationTime
            playAura.source             = source
            playAura.isStealable        = isStealable
            playAura.canApplyAura       = canApplyAura
            auraList[spellId] = playAura
        else
            break
        end
    end
end

function Shadbro:RefreshPlayerAuras()
    sbd:log_debug('event: PLAYER_TARGET_CHANGED')
    Shadbro.ResetPlayerAuras()

    refreshAura(Shadbro.playerAuras, "player", true)

    -- for Key,Value in pairs(Shadbro.playerAuras) do
    --     if Value then
    --         sbd:log_debug('event: AddedPlaterAura: ', Value.name, ' Count: ', Value.count, ' Expiration: ', Value.expirationTime, ' Source: ', Value.source)
    --     end
    -- end
end

function Shadbro.ResetPlayerAuras()
    Shadbro.playerAura         = {}
end

Shadbro.targetAuras              = {}
function Shadbro:RefreshTargetAuras()
    sbd:log_debug('event: PLAYER_TARGET_CHANGED')
    table.wipe(Shadbro.targetAuras)
    refreshAura(Shadbro.targetAuras, "target", false)
    for Key,Value in pairs(Shadbro.targetAuras) do
        if Value then
            sbd:log_debug('event: AddedPlaterAura: ', Value.name, ' Count: ', Value.count, ' Expiration: ', Value.expirationTime, ' Source: ', Value.source)
        end
    end

end

function Shadbro.ResetTargetAuras()
    Shadbro.targetAuras         = {}
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



function Shadbro.FindNextSpell()
    print("FindNextSpell")
    Shadbro:PushChanges()
    Shadbro.UpdatePlayerAuras()
    local targetGuid = UnitGUID("target")
    for Key,Value in pairs(Shadbro.Priority) do 
        -- id := Value.SpellId
        if Shadbro.SpellList[Value].IsDot == true then
            -- This one checks if it's a dot and we have an aura ready to go
            if TargetAuraIsPresent(targetGuid, Value) == false then
                sbd:log_debug('NextSpell:', Shadbro.SpellList[Value].SpellId)
                return
            end

            -- Check to see if regular spell
        end
    end
end

function TargetAuraIsPresent(targetGuid, auraId)
    print("PlayerAuraIsPresent")
    for i=1,40 do 
        local name, _, count, _, _, _, _, _, _, spellId = UnitAura("target",i,"HARMFUL")
        if name then
            sbd:log_debug('TargetReqSpell:', auraId, ' Count: ', count,  'Spell ID', spellId)
            if spellId == auraId then
                sbd:log_debug('ReqSpellFound:', auraId, ' Count: ', count)
                return true
            end
            
        else
            -- nil, quit looking
            return false
        end
    end
    return false
end


function PlayerAuraIsPresent(auraId)
    print("PlayerAuraIsPresent")
    for i=1,40 do 
        local name, _, count, _, _, _, _, _, _, spellId = UnitBuff("player",i)
        if name then
            sbd:log_debug('ReqSpell:', auraId, ' Count: ', count,  'Spell ID', spellId)
            if spellId == auraId then
                sbd:log_debug('ReqSpellFound:', auraId, ' Count: ', count)
                if count then 
                    return count
                end
                return 1
            end
            
        else
            return 0
        end
    end
end





function Shadbro.UpdatePlayerAuras()
    print("UpdatePlayerAuras")

    local spellBonus = GetSpellBonusDamage(6)
    local count = PlayerAuraIsPresent(Spell_priest_shadowWeaving.AuraId)

    sbd:log_debug('Aura:', Shadbro.SpellList[Spell_priest_shadowWeaving.SpellId], " count: ", count)
    sbd:log_debug('SpellExpectedTick:', (spellBonus + 1575) / 7)

end


local function SetNext(self, spellId)
    if not self._PixelGlow then
        return
    end

    local r,color,N,frequency,length,th,xOffset,yOffset,border,key,frameLevel
    frameLevel = 8
    key = spellId
    LCG.PixelGlow_Start(Shadbro.displayFrame_next, color,N,frequency,length,th,xOffset,yOffset,border,key,frameLevel)

    
end

local NUM_GLYPH_SLOTS = 6

local function UpdateCharacterInfo()
    for i=1,NUM_GLYPH_SLOTS  do
        local enabled, glyphType, glyphTooltipIndex, glyphSpellID, icon = GetGlyphSocketInfo(i)
        if enabled then
            sbd:log_debug('function: UpdateCharacterInfo Slot: ', i, ' Glyph: ', glyphSpellID, 'TT: ', glyphTooltipIndex, 'Type:', GetSpellInfo(glyphSpellID))
        end
    end

end


local function UnsetNext(self, spellId)
    if not self._PixelGlow then
        return
    end

    LCG.PixelGlow_Stop(self, spellId)
end


function TargetAuraDuration(auraId)
    print("PlayerAuraIsPresent")
    for i=1,40 do 
        local name, _, count, _, duration, expirationTime, _, _, _, spellId = UnitAura("target",i,"HARMFUL")
        if name then
            if spellId == auraId then
                local startTime = expirationTime - duration
                sbd:log_debug('function: TargetAuraDuration. StartTime: ', startTime, 'expirationTime', expirationTime)
                return startTime, duration
            end
            
        else
            -- nil, quit looking
            return 0, 0
        end
    end
    return 0, 0
end

function UpdateButton(spellId)
    local startTime, duration = TargetAuraDuration(spellId)
    if duration == 0 then
        Shadbro.cd[spellId]:Clear()
        return
    end
    sbd:log_debug('function: TargetAuraDuration. StartTime: ', startTime, 'expirationTime', duration, ' current ', GetTime())
    Shadbro.cd[spellId]:SetCooldown(startTime, duration)
    GetSpellState(Shadbro.SpellList[spellId])
end

function Shadbro:PushChanges()
    -- Check the status of your dots
    local targetGuid = UnitGUID("target")
    -- Highlight any dots that aren't present
    local Value = Shadbro.SpellList[Spell_priest_shadowWordPain.SpellId]
    if TargetAuraIsPresent(targetGuid, Spell_priest_shadowWordPain.SpellId) == false then
        sbd:log_debug('function: TargetAuraIsPresent false')
        Shadbro.text_ture[Spell_priest_shadowWordPain.SpellId]:SetAllPoints()
        Shadbro.text_ture[Spell_priest_shadowWordPain.SpellId]:SetDesaturation(0)
        SetNext(Shadbro.displayFrame_next, Spell_priest_shadowWordPain.SpellId)
        UpdateCharacterInfo()
        UpdateButton(Spell_priest_shadowWordPain.SpellId)
    else

        -- Shadbro.displayFrame_next:SetFontString(t)
        -- local t = Shadbro.displayFrame_next:CreateTexture(nil, "BACKGROUND")
        Shadbro.text_ture[Spell_priest_shadowWordPain.SpellId]:SetAllPoints()
        Shadbro.text_ture[Spell_priest_shadowWordPain.SpellId]:SetDesaturation(.9)
        

        sbd:log_debug('function: TargetAuraIsPresent true')
        -- local r,color,N,frequency,length,th,xOffset,yOffset,border,key,frameLevel
        -- frameLevel = 8
        -- key = Spell_priest_shadowWordPain.SpellId
        -- LCG.PixelGlow_Stop(Shadbro.displayFrame_next, key)
        UnsetNext(Shadbro.displayFrame_next, Spell_priest_shadowWordPain.SpellId)
        UpdateButton(Spell_priest_shadowWordPain.SpellId)
        -- Shadbro.cd[Spell_priest_shadowWordPain.SpellId]:SetCooldown(0, 0)


    end
end

Shadbro.cd = {}

Shadbro.text_ture = {}

function Shadbro:CreateBar()
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
    displayFrame:Show()

    Shadbro:AddChild(displayFrame, 40, 0, Spell_priest_shadowWordPain.SpellId)
end



function Shadbro:AddChild(parentDisplayFrame, size, offset, spellId)
    local margin = 2

    sbd:log_debug('function: CreateGUI', Shadbro.SpellList[Spell_priest_shadowWordPain.SpellId].Name, "name")

    DisplayFrame_next = CreateFrame("Button", nil, parentDisplayFrame, "SecureActionButtonTemplate")
    DisplayFrame_next:SetWidth(size)
    DisplayFrame_next:SetHeight(size)
    DisplayFrame_next:SetPoint("TOPLEFT", offset * size + margin + offset * margin, -margin )

    Shadbro.text_ture[Spell_priest_shadowWordPain.SpellId] = DisplayFrame_next:CreateTexture(nil, "BACKGROUND")
    -- t:SetTexture(nil)
    Shadbro.text_ture[Spell_priest_shadowWordPain.SpellId]:SetAllPoints(DisplayFrame_next)
    Shadbro.text_ture[Spell_priest_shadowWordPain.SpellId]:SetTexture(Shadbro.SpellTextures[Spell_priest_shadowWordPain.SpellId])
    Shadbro.text_ture[Spell_priest_shadowWordPain.SpellId]:SetDesaturation(.9)
    DisplayFrame_next:SetNormalTexture(Shadbro.text_ture[Spell_priest_shadowWordPain.SpellId])

    -- key = spellId
    DisplayFrame_next["_PixelGlow"] = spellId

    DisplayFrame_next:SetAttribute("type","spell");-- Set type to "macro"

    DisplayFrame_next:SetAttribute("spell", Shadbro.SpellList[Spell_priest_shadowWordPain.SpellId].Name);-- Set our macro text

    local t = DisplayFrame_next:CreateFontString("test", "OVERLAY", "GameTooltipText")
    t:SetPoint("CENTER", 0, 0)
    t:SetText("")
    DisplayFrame_next:SetFontString(t)
    
    Shadbro.cd[Spell_priest_shadowWordPain.SpellId] = CreateFrame("Cooldown", "myCooldown", DisplayFrame_next, "CooldownFrameTemplate")
    Shadbro.cd[Spell_priest_shadowWordPain.SpellId]:SetAllPoints()
    Shadbro.cd[Spell_priest_shadowWordPain.SpellId]:SetCooldown(0, 0)
    
    Shadbro.displayFrame_next = DisplayFrame_next
end

function Shadbro:CreateGUI()
    sbd:log_debug('function: CreateGUI')
Shadbro:CreateBar()
    end
    function Shadbro:CreateGUI3()
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
    DisplayFrame_next:SetWidth(40)
    DisplayFrame_next:SetHeight(40)
    DisplayFrame_next:SetPoint("TOPLEFT", 170, -10)

    DisplayFrame_next:SetButtonState("Normal")
    local t = DisplayFrame_next:CreateTexture(nil, "BACKGROUND")
    -- t:SetTexture(nil)
    t:SetAllPoints(DisplayFrame_next)
    t:SetTexture(Shadbro.SpellTextures[Spell_priest_shadowWordPain.SpellId])
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

    displayFrame_next:RegisterForClicks("AnyUp");--   Respond to all buttons
    displayFrame_next:SetAttribute("type","action");-- Set type to "macro"
    displayFrame_next:SetAttribute("action",Spell_priest_shadowWordPain.ActionButton[1]);-- Set our macro text


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