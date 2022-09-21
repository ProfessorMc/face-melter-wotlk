local fm_core_event_frame = CreateFrame("Frame")
local logger = GetLogger()
logger:SetDebug()

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

function fm_core_event_frame.PLAYER_REGEN_ENABLED()
    FM_CORE:SetInCombat(false)
end

function fm_core_event_frame.COMBAT_LOG_EVENT_UNFILTERED(...)
    local timestamp, event, _, _, sourceName, _, _, dstGUID, dstName, _, _, spell_id, spellName, _, _, _, _, resisted = CombatLogGetCurrentEventInfo()
    if dstName == FM_CORE:GetPlayerName() then
        logger:log_debug('event: fm_core_event_frame.COMBAT_LOG_EVENT_UNFILTERED: ', event)
        if event == "SPELL_AURA_APPLIED" or 
                event == "SPELL_AURA_APPLIED_DOSE" or
                event == "SPELL_AURA_REFRESH" or 
                event == "SPELL_AURA_REMOVED" then
            FM_CORE:HandlePlayerAuraUpdate()
        end
    end

    if sourceName == FM_CORE:GetPlayerName() and dstName ~= FM_CORE:GetPlayerName() then
        if event == "SPELL_CAST_START" then
            FM_CORE:HandleStartCasting(spell_id)
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
        elseif event == "SPELL_CAST_SUCCESS" then
            FM_CORE:HandleCastComplete()
        elseif event == "SPELL_MISSED" then
            FM_CORE:HandleCastComplete()
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
end

function UnregisterEvents()
    logger:log_debug('event: fm_core_event_frame.UnregisterEvents')
    fm_core_event_frame:UnregisterAllEvents()
end