local fm_core_event_frame = CreateFrame("Frame")
local logger = GetLogger()
logger:SetDebug(false)

fm_core_event_frame:SetScript("OnEvent", function(this, event, ...)
    fm_core_event_frame[event](...)
end)

fm_core_event_frame:RegisterEvent("ADDON_LOADED")
function fm_core_event_frame.ADDON_LOADED(addon)
    FM_CORE:OnLoad(addon)
end

function fm_core_event_frame.PLAYER_REGEN_DISABLED()
    FM_CORE:SetInCombat(true)
end

function fm_core_event_frame.UNIT_SPELLCAST_SUCCEEDED(unitTarget, castGUID, spellID)
    logger:log_debug('event: UNIT_SPELLCAST_SUCCEEDED')
end

function fm_core_event_frame.UNIT_SPELLCAST_FAILED(unitTarget, castGUID, spell_id)
    logger:log_debug('event: UNIT_SPELLCAST_FAILED')
    -- FM_CORE:HandleCastComplete(spell_id)
end

function fm_core_event_frame.UNIT_SPELLCAST_INTERRUPTED(unitTarget, castGUID, spell_id)
    logger:log_debug('event: UNIT_SPELLCAST_INTERRUPTED')
    FM_CORE:HandleCastComplete(spell_id)
end

function fm_core_event_frame.UNIT_SPELLCAST_START(unitTarget, castGUID, spell_id)
    logger:log_debug('event: UNIT_SPELLCAST_START')
    FM_CORE:HandleStartCasting(spell_id)
end

function fm_core_event_frame.UNIT_SPELLCAST_STOP(unitTarget, castGUID, spell_id)
    logger:log_debug('event: UNIT_SPELLCAST_SPELLCAST_STOP')
    FM_CORE:HandleCastComplete(spell_id)
end

function fm_core_event_frame.UNIT_SPELLCAST_CHANNEL_START(unitTarget, castGUID, spell_id)
    logger:log_debug('event: UNIT_SPELLCAST_CHANNEL_START')
    FM_CORE:HandleStartCasting(spell_id)
end

function fm_core_event_frame.UNIT_SPELLCAST_CHANNEL_STOP(unitTarget, castGUID, spell_id)
    logger:log_debug('event: UNIT_SPELLCAST_CHANNEL_STOP')
    FM_CORE:HandleCastComplete(spell_id)
end


function fm_core_event_frame.UNIT_SPELLCAST_CHANNEL_UPDATE(unitTarget, castGUID, spell_id)
    logger:log_debug('event: UNIT_CHANNEL_STOP')
    FM_CORE:HandleCastComplete(spell_id)
end


function fm_core_event_frame.PLAYER_REGEN_ENABLED()
    FM_CORE:SetInCombat(false)
end

function fm_core_event_frame.COMBAT_LOG_EVENT_UNFILTERED(...)
    local timestamp, event, _, _, sourceName, _, _, dstGUID, dstName, _, _, spell_id, spellName, _, _, _, _, resisted = CombatLogGetCurrentEventInfo()
    if dstName == FM_CORE:GetPlayerName() then
        -- logger:log_debug('event: fm_core_event_frame.COMBAT_LOG_EVENT_UNFILTERED: ', event, ' name: ', spellName)
        if event == "SPELL_AURA_APPLIED" or 
                event == "SPELL_AURA_APPLIED_DOSE" or
                event == "SPELL_AURA_REFRESH" or 
                event == "SPELL_AURA_REMOVED" then
            FM_CORE:HandlePlayerAuraUpdate()
        end
        -- not sure if we'll use this but it triggers when glyph adds to values like swp dot ticks
        -- if event == "SPELL_PERIODIC_ENERGIZE"  then
        --     logger:log_debug('event: fm_core_event_frame.COMBAT_LOG_EVENT_UNFILTERED: ', event, ' name: ', spellName)
        -- end
    end

    if sourceName == FM_CORE:GetPlayerName() and dstName ~= FM_CORE:GetPlayerName() then
        if event == "SPELL_CAST_START" then
            -- logger:log_debug('event: fm_core_event_frame.COMBAT_LOG_EVENT_UNFILTERED: ', event, ' name: ', spellName)
            -- FM_CORE:HandleStartCasting(spell_id)
        elseif event == "SPELL_DAMAGE" then
        elseif event == "SPELL_AURA_APPLIED" then
            FM_CORE:HandleTargetAuraUpdate()
        elseif event == "SPELL_AURA_APPLIED_DOSE" then
            FM_CORE:HandleTargetAuraUpdate()
        elseif event == "SPELL_AURA_REFRESH" then
            FM_CORE:HandleTargetAuraUpdate()
        elseif event == "SPELL_AURA_REMOVED" then
            FM_CORE:HandleTargetAuraUpdate()
        elseif event == "SPELL_PERIODIC_DAMAGE" then
        elseif event == "SPELL_PERIODIC_DAMAGE" then
        elseif event == "SPELL_CAST_SUCCESS" then
            -- FM_CORE:HandleCastComplete()
        elseif event == "SPELL_MISSED" then
            -- FM_CORE:HandleCastComplete()
        end

    end
end

function fm_core_event_frame.PLAYER_TALENT_UPDATE(...)
    FM_CORE:HandlePlayerTalentUpdate()
end

function fm_core_event_frame.PLAYER_TARGET_CHANGED(...)
    FM_CORE:HandleTargetChange()
end

function RegisterEvents()
    logger:log_debug('event: fm_core_event_frame.RegisterEvents')
    fm_core_event_frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    fm_core_event_frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    fm_core_event_frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    fm_core_event_frame:RegisterEvent("PLAYER_TALENT_UPDATE")
    fm_core_event_frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    fm_core_event_frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    fm_core_event_frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    fm_core_event_frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    fm_core_event_frame:RegisterEvent("UNIT_SPELLCAST_START")
    fm_core_event_frame:RegisterEvent("UNIT_SPELLCAST_STOP")
    fm_core_event_frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    fm_core_event_frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    fm_core_event_frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
end

function UnregisterEvents()
    logger:log_debug('event: fm_core_event_frame.UnregisterEvents')
    fm_core_event_frame:UnregisterAllEvents()
end