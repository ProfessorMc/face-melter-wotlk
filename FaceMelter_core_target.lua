local MAX_TARGET_AURAS = 40
local target_prototype = {}

local metatable = {
    __index = target_prototype
}

function CreateTarget()
    return setmetatable({}, metatable)
end

function target_prototype:OnTargetChange()
    if UnitName("target") == nil or UnitHealth("target") == 0 then
        self:SetNoTarget()
        return
    end

    if UnitIsFriend("player", "target") == true then
        self:SetFriendlyTarget()
        return
    end
    self.target_type = "hostile"
    self:UpdateAuras()
end

function target_prototype:SetNoTarget()
    self.aura_list = {}
    self.target_type = "none"
end

function target_prototype:SetFriendlyTarget()
    self.aura_list = {}
    self.is_friendly = "friendly"
end

function target_prototype:IsSelf()
    if not self.target_type then
        target_prototype:OnTargetChange()
    end
    return self.target_type == "player"
end

function target_prototype:IsNoTarget()
    if not self.target_type then
        target_prototype:OnTargetChange()
    end
    return self.target_type == "none"
end

function target_prototype:IsHostile()
    if not self.target_type then
        target_prototype:OnTargetChange()
    end
    return self.target_type == "hostile"
end

function target_prototype:IsFriendly()
    if not self.target_type then
        target_prototype:OnTargetChange()
    end
    return self.target_type == "friendly" or target_prototype:IsSelf()
end

function target_prototype:IsAuraPresent(spell_id)
    if not self.aura_list then
        self:UpdateAuras()
    end
    self:UpdateAuras()
    if not self.aura_list[spell_id] then
        -- print("NotFound", spell_id)
        return false
    end
    -- print("Found", spell_id)
    return self.aura_list[spell_id]
end

function target_prototype:GetDebuffDuration(spell_id)
    if not self.aura_list then
        self:UpdateAuras()
    end
    self:UpdateAuras()
    if not self.aura_list[spell_id] then
        -- print("NotFound", spell_id)
        return 0, 0
    end
    
    local start_time = self.aura_list[spell_id].expirationTime - self.aura_list[spell_id].duration
    if self.aura_list[spell_id].expirationTime < GetTime() then
        -- print("Expired", spell_id)
        return 0, 0
    end

    -- print("Set", spell_id)
    return start_time, self.aura_list[spell_id].duration
end



function target_prototype:OnAuraChange()
    self:UpdateAuras()
end

function target_prototype:UpdateAuras()
    local auraType = "HELPFUL"
    -- if isHelpful == false then
        
    -- end
    auraType = "HARMFUL"
    self.aura_list = {}
    for i=1, MAX_TARGET_AURAS do
        local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura= UnitAura("TARGET",i, auraType)
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
            self.aura_list[spellId] = playAura
            -- print('adding aura: ', playAura.name, ' id: ', spellId)
        else
            break
        end
    end
end