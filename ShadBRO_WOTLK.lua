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
-- All lists indexed by spell key.
Shadbro.SpellList       = {}
Shadbro.SpellCastTime   = {}
Shadbro.SpellTextures   = {}
Shadbro.Priority        = {}


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

local is_enabled = true

function Shadbro.events.ADDON_LOADED(addon)
    if addon ~= "FaceMelterWotlk" then
        return
    end

    sbd:log_debug('event: ADDON_LOADED')

    local _, playerClass = UnitClass("player")
    if playerClass ~= "PRIEST" then
        is_enabled = false
        return
    end

    if playerClass == "PRIEST" then
        LoadPriestSpells()
    end

    Shadbro:CreateGUI()
    Shadbro.GetNext()
end


function Shadbro.events.COMBAT_LOG_EVENT_UNFILTERED(...)
    if is_enabled == false then
        return
    end
    local timestamp, event, _, _, sourceName, _, _, dstGUID, dstName, _, _, spellId, spellName, _, _, _, _, resisted = CombatLogGetCurrentEventInfo()
    if dstName == Shadbro.playerName then
        if event == "SPELL_AURA_APPLIED" or 
                event == "SPELL_AURA_APPLIED_DOSE" or
                event == "SPELL_AURA_REFRESH" or 
                event == "SPELL_AURA_REMOVED" then
            sbd:log_debug('event: SPELL_AURA_APPLIED', ' name: ', spellName, ' dstName:', dstName)
            Shadbro:RefreshPlayerAuras()
        end
    end


    if sourceName == Shadbro.playerName and dstName ~= Shadbro.playerName then
        -- sbd:log_debug('event: ', event)
        -- print(CombatLogGetCurrentEventInfo())
        if event == "SPELL_CAST_START" then
            sbd:log_debug('event: SPELL_CAST_START')
            Shadbro:FindNextSpell()
        elseif event == "SPELL_DAMAGE" then
            -- spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
            sbd:log_debug('event: SPELL_DAMAGE', ' name: ', spellName, ' dstGUID:', dstGUID)
            Shadbro:FindNextSpell()
        elseif event == "SPELL_AURA_APPLIED" then
            -- sbd:log_debug('event: SPELL_AURA_APPLIED', ' name: ', spellName, ' dstGUID:', dstGUID)
            -- sbd:log_debug('event: SPELL_AURA_APPLIED', ' name: ', spellName, 'spellid', spellId,' dstGUID:', dstGUID, ' expiration:', Shadbro.TargetList[dstGUID].Auras[spellId], 'current: ',GetTime())
            -- Shadbro:FindNextSpell()
            Shadbro:FindNextSpell()
        elseif event == "SPELL_AURA_APPLIED_DOSE" then
            -- sbd:log_debug('event: SPELL_AURA_APPLIED_DOSE', ' name: ', spellName, ' dstGUID:', dstGUID)
            Shadbro:FindNextSpell()
        elseif event == "SPELL_AURA_REFRESH" then
            sbd:log_debug('event: SPELL_AURA_REFRESH', ' name: ', spellName, ' dstGUID:', dstGUID)
            Shadbro:FindNextSpell()
        elseif event == "SPELL_AURA_REMOVED" then
            -- sbd:log_debug('event: SPELL_AURA_REMOVED', ' name: ', spellName, ' dstGUID:', dstGUID)
            -- TargetAuraRemove(dstGUID, spellId)
            -- Shadbro:PushChanges()
            Shadbro:FindNextSpell()
        elseif event == "SPELL_PERIODIC_DAMAGE" then
            -- sbd:log_debug('event: SPELL_PERIODIC_DAMAGE', ' name: ', spellName, ' dstGUID:', dstGUID)
        elseif event == "SPELL_CAST_SUCCESS" then
            sbd:log_debug('event: SPELL_CAST_SUCCESS', spellId)
            -- Shadbro.lastSpellCast = spellId
            Shadbro:FindNextSpell()
        elseif event == "SPELL_MISSED" then -- aww we get reisted, we only care if it's a debuff though
            -- sbd:log_debug('event: SPELL_MISSED', ' resisted: ', resisted)
            Shadbro:FindNextSpell()
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
    if UnitName("target") == nil or UnitHealth("target") == 0 then
        Shadbro:SetNoTarget()
        return
    end

    Shadbro:RefreshPlayerAuras()
    Shadbro:RefreshTargetAuras()

    if UnitIsFriend("player", "target") == true then
        Shadbro:SetFriendlyTarget()
        return
    end

    Shadbro:SetHostileTarget()
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
    sbd:log_debug('event: RefreshPlayerAuras')
    Shadbro.ResetPlayerAuras()
    refreshAura(Shadbro.playerAuras, "player", true)
end

function Shadbro.ResetPlayerAuras()
    Shadbro.playerAura         = {}
end

Shadbro.targetAuras              = {}
function Shadbro:RefreshTargetAuras()
    sbd:log_debug('event: RefreshTargetAuras')
    table.wipe(Shadbro.targetAuras)
    refreshAura(Shadbro.targetAuras, "target", false)
    for Key,Value in pairs(Shadbro.targetAuras) do
        if Value then
            sbd:log_debug('event: AddedPlaterAura: ', Value.name, ' Count: ', Value.count, ' Expiration: ', Value.expirationTime, ' Source: ', Value.source)
        end
    end

end

function GetSpellsList()
    return Shadbro.SpellList
end

function Shadbro:SetNoTarget()
    sbd:log_debug('event: SetNoTarget', Shadbro.SpellList[Spell_priest_shadowWordPain.SpellId].Name)


    for key, value in pairs(Shadbro.SpellList) do
        sbd:log_debug('event: SetNoTarget', value.Name)
        Shadbro:set_button_cleared(key)
    end
end

function Shadbro:RegisterSpells(spells_list)
    Shadbro.spellsList = spells_list
end

function Shadbro:SetFriendlyTarget()
    sbd:log_debug('event: SetFriendlyTarget')
end

function Shadbro:SetHostileTarget()
    sbd:log_debug('event: SetHostileTarget')
    Shadbro:FindNextSpell()
    Shadbro:PushChanges()
end

local function UnsetNext(self, spellId)
    if not self._PixelGlow then
        return
    end

    LCG.PixelGlow_Stop(self, spellId)
end

function Shadbro:set_button_cleared(spell_id)
    sbd:log_debug('event: set_button_cleared', spell_id)
    if not spell_id then
        return
    end

    if not Shadbro.text_ture[spell_id] then
        return
    end


    Shadbro.text_ture[spell_id]:SetAllPoints()
    Shadbro.text_ture[spell_id]:SetDesaturation(.9)

    UnsetNext(Shadbro.ActionButtons[Spell_priest_shadowWordPain.SpellId], Spell_priest_shadowWordPain.SpellId)
end

function Shadbro:set_button_active(spell_id)
    sbd:log_debug('event: set_button_active')
    if not spell_id then
        return
    end

    if not Shadbro.text_ture[spell_id] then
        return
    end

    Shadbro.text_ture[spell_id]:SetAllPoints()
    Shadbro.text_ture[spell_id]:SetDesaturation(0)
end

function Shadbro:FindNextSpell()
    print("FindNextSpell")
    Shadbro:PushChanges()
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
    -- print("PlayerAuraIsPresent")
    if not Shadbro.lastSpellCast and Shadbro.lastSpellCast == auraId then
        -- sbd:log_debug('ReqSpellFound:', auraId, ' Count: ', count)
        Shadbro.lastSpellCast = nil
        return true
    end

    for i=1,40 do 
        local name, _, count, _, _, _, _, _, _, spellId = UnitAura("target",i,"HARMFUL")
        if name then
            -- sbd:log_debug('TargetReqSpell:', auraId, ' Count: ', count,  'Spell ID', spellId)
            if spellId == auraId then
                -- sbd:log_debug('ReqSpellFound:', auraId, ' Count: ', count)
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
    -- print("PlayerAuraIsPresent")
    for i=1,40 do 
        local name, _, count, _, _, _, _, _, _, spellId = UnitBuff("player",i)
        if name then
            -- sbd:log_debug('ReqSpell:', auraId, ' Count: ', count,  'Spell ID', spellId)
            if spellId == auraId then
                -- sbd:log_debug('ReqSpellFound:', auraId, ' Count: ', count)
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


local function SetNext(self, spellId)
    if not self._PixelGlow then
        return
    end

    local r,color,N,frequency,length,th,xOffset,yOffset,border,key,frameLevel
    frameLevel = 8
    key = spellId
    LCG.PixelGlow_Start(self, color,N,frequency,length,th,xOffset,yOffset,border,key,frameLevel)
end

local NUM_GLYPH_SLOTS = 6

local function UpdateCharacterInfo()
    for i=1,NUM_GLYPH_SLOTS  do
        local enabled, glyphType, glyphTooltipIndex, glyphSpellID, icon = GetGlyphSocketInfo(i)
        if enabled then
            -- sbd:log_debug('function: UpdateCharacterInfo Slot: ', i, ' Glyph: ', glyphSpellID, 'TT: ', glyphTooltipIndex, 'Type:', GetSpellInfo(glyphSpellID))
        end
    end

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
    local targetGuid = UnitGUID("target")
    if TargetAuraIsPresent(targetGuid, Spell_priest_shadowWordPain.SpellId) == false then
        sbd:log_debug('function: TargetAuraIsPresent false')
        Shadbro.text_ture[Spell_priest_shadowWordPain.SpellId]:SetAllPoints()
        Shadbro.text_ture[Spell_priest_shadowWordPain.SpellId]:SetDesaturation(0)
        SetNext(Shadbro.ActionButtons[Spell_priest_shadowWordPain.SpellId], Spell_priest_shadowWordPain.SpellId)
        UpdateCharacterInfo()
        UpdateButton(Spell_priest_shadowWordPain.SpellId)
    else

        -- Shadbro.displayFrame_next:SetFontString(t)
        -- local t = Shadbro.displayFrame_next:CreateTexture(nil, "BACKGROUND")
        Shadbro.text_ture[Spell_priest_shadowWordPain.SpellId]:SetAllPoints()
        Shadbro.text_ture[Spell_priest_shadowWordPain.SpellId]:SetDesaturation(.9)
        sbd:log_debug('function: TargetAuraIsPresent true')
        UnsetNext(Shadbro.ActionButtons[Spell_priest_shadowWordPain.SpellId], Spell_priest_shadowWordPain.SpellId)
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
    displayFrame:SetWidth(40 * 7 + 2 * 7)
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

    Shadbro.ActionButtons = {}
    -- IterateSpells()
    local offset = 0
    for i = 1, 10  do --pseudocode
        if not Shadbro.Priority[i] then
            break
        end
        local spell_id = Shadbro.Priority[i]
        sbd:log_debug('event: displayFrame: makebutton key: ', spell_id)
        if Shadbro.SpellList[spell_id].IsCastable == true then
            Shadbro:AddChild(displayFrame, 40, offset, spell_id)
            offset = offset + 1
        end
    end

    -- Shadbro:AddChild(displayFrame, 40, 0, Spell_priest_shadowWordPain.SpellId)
    Shadbro.ActionBar = displayFrame
    Shadbro.ActionBar:Show()
    
end



function Shadbro:AddChild(parentDisplayFrame, size, offset, spell_id)
    local margin = 2

    sbd:log_debug('function: CreateGUI', Shadbro.SpellList[spell_id].Name, "name")

    local spellButton = CreateFrame("Button", nil, parentDisplayFrame, "SecureActionButtonTemplate")
    spellButton:SetWidth(size)
    spellButton:SetHeight(size)
    spellButton:SetPoint("TOPLEFT", offset * size + margin + offset * margin, -margin )

    Shadbro.text_ture[spell_id] = spellButton:CreateTexture(nil, "BACKGROUND")
    -- t:SetTexture(nil)
    Shadbro.text_ture[spell_id]:SetAllPoints(spellButton)
    Shadbro.text_ture[spell_id]:SetTexture(Shadbro.SpellTextures[spell_id])
    Shadbro.text_ture[spell_id]:SetDesaturation(.9)
    spellButton:SetNormalTexture(Shadbro.text_ture[spell_id])

    -- key = spellId
    spellButton["_PixelGlow"] = spell_id

    spellButton:SetAttribute("type","spell");-- Set type to "macro"

    spellButton:SetAttribute("spell", Shadbro.SpellList[spell_id].Name);-- Set our macro text

    local t = spellButton:CreateFontString("test", "OVERLAY", "GameTooltipText")
    t:SetPoint("CENTER", 0, 0)
    t:SetText("")
    spellButton:SetFontString(t)

    Shadbro.cd[spell_id] = CreateFrame("Cooldown", "myCooldown", spellButton, "CooldownFrameTemplate")
    Shadbro.cd[spell_id]:SetAllPoints()
    Shadbro.cd[spell_id]:SetCooldown(0, 0)
    Shadbro.ActionButtons[spell_id] = spellButton
end

function Shadbro:CreateGUI()
    sbd:log_debug('function: CreateGUI')
    Shadbro:CreateBar()
end
