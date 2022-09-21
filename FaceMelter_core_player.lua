local MAX_PLAYER_AURAS = 40
local NUM_GLYPH_SLOTS  = 6
local player_prototype = {}

local GetGlyph = GetGlyphSocketInfo

local metatable = {
    __index = player_prototype
}

function CreatePlayer()
    return setmetatable({}, metatable)
end

function player_prototype:GetName()
    if not self.name then
        self.name = UnitName("player")
    end
    return self.name
end

function player_prototype:GetClass()
    if not self.class then
        _, self.class = UnitClass("player")
    end
    return self.class
end

function player_prototype:IsSpecChange()
    if not self.spec then
        self.spec = GetActiveSpecGroup()
        return true
    end

    local current_spec = self.spec
    self.spec = GetActiveSpecGroup()
    return self.spec == current_spec
end

function player_prototype:OnSpecChange()
    self:UpdateCharacter()
end

function player_prototype:UpdateCharacter()
    self.known_spells = {}
    player_prototype:UpdatePlayerGlyphs()
    player_prototype:UpdateTalents()
end

function player_prototype:OnAuraChange()
    self:UpdateAuras()
end

function player_prototype:UpdateTalents()
    self.current_talents = {}
    for i = 1, GetNumTalentTabs() do
        self.current_talents[i] = {}
        for j = 1, GetNumTalents(i) do
            local name, iconTexture, tier, column, rank, maxRank, _, _ = GetTalentInfo(i, j)
            local talent_info              = {}
            talent_info.name = name
            talent_info.rank = rank
            self.current_talents[i][j] = talent_info
            -- print("Talent: ", name , "Tab: ", i, "Idx:", j)
        end
    end
end

function player_prototype:GetTalentInfo(tab, idx)
    if not self.current_talents then
        player_prototype:UpdateTalents()
    end
    return self.current_talents[tab][idx]
end

function player_prototype:UpdateAuras()
    local auraType = "HELPFUL"
    if isHelpful == false then
        auraType = "HARMFUL"
    end
    self.aura_list = {}
    for i=1, MAX_PLAYER_AURAS do
        local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura= UnitAura("PLAYER",i, auraType)
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

function player_prototype:GetAura(aura_id)
    if not self.aura_list then
        self:UpdateAuras()
    end

    if not self.aura_list[aura_id] then
        -- print('aura not found id: ', aura_id)
        return
    end

    if GetTime() < self.aura_list[aura_id].expirationTime then
        print('aura found id: ', aura_id)
        return self.aura_list[aura_id]
    end
    -- print('aura expired id: ', aura_id, 'time: ', GetTime(), 'exp: ',  self.aura_list[aura_id].expirationTime)
end

function player_prototype:SetInCombat(in_combat)
    self.in_combat = in_combat
end

function player_prototype:IsInCombat()
    if not self.IsInCombat then
        return false
    end
    return self.in_combat
end

function player_prototype:IsGlyphKnown(glyph_id)
    if not self.known_glyphs then
        self:UpdatePlayerGlyphs()
    end
    if not self.known_glyphs[glyph_id] then
        return false
    end
    return true
end

function player_prototype:UpdatePlayerGlyphs()
    if not self.known_glyphs then
        self.known_glyphs = {}
    end

    for i=1,NUM_GLYPH_SLOTS  do
        local enabled, glyphType, glyphTooltipIndex, glyphSpellID, icon = GetGlyph(i)
        if enabled then
            print("glyph_id: ", glyphSpellID, "idx: ", glyphTooltipIndex)
            print(GetGlyphLink(i))
            -- print(GetTalentInfo(i, i))
            self.known_glyphs[glyphSpellID] = glyphTooltipIndex
        end
    end
end

function player_prototype:IsBaseSpellKnown(spell_id)
    if not self.known_spells then
        self.known_spells = {}
    end
    if not self.known_spells[spell_id] then
        local base_spell_id = FindBaseSpellByID(spell_id)
        self.known_spells[spell_id] = IsSpellKnown(base_spell_id)
    end
    return self.known_spells[spell_id]
end

function player_prototype:GetSpellCooldown(spell_id)
    local base_spell_id = FindBaseSpellByID(spell_id)
    return GetSpellCooldown(base_spell_id)
end