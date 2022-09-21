local priest_lib = {}
local logger = GetLogger()


local function elligibleToCast(player_information, spell_id, current_spell_id)
    if spell_id == current_spell_id then
        return
    end

    local is_known = player_information:IsBaseSpellKnown(spell_id)
    if is_known == false then
        return
    end

    local start, gcd_duration, enabled, gcd_modRate = GetSpellCooldown(61304)
    print("Spell GCD cooldown: " .. gcd_duration .. " seconds. mod: ", gcd_modRate, " enabled: ", enabled)
    local start, duration, enabled, modRate = GetSpellCooldown(spell_id)
    if enabled == 0 then
        return true
    elseif ( start > 0 and duration > 0) then
        local cdLeft = start + duration - GetTime()
        print("Spell ".. spell_id .. "cooldown: " .. cdLeft .. " seconds.")
        return
    else
        return true
    end
end

local function debuff_present(target_information, spell_id)
    local debuff_found = target_information:IsAuraPresent(spell_id)
    if debuff_found then
        return true
    end
    return false
end

local aura_shadow_weaving = {
    spell_id     = 15258,
}

local talent_pain_and_suffering = {
    tab = 3,
    idx = 24,
}

local talent_shadow_weaving = {
    tab = 3,
    idx = 1,
}

local glyph_mind_flay = {
    spell_id = 237643,
}

local glyph_shadowWordPain = {
    spell_id = 237643,
}

local spell_vampiricTouch = {
    spell_id     = 34917,
}

-- spell_vampiricTouch: Checks if known and already there
function spell_vampiricTouch:ChooseNext(player_information, target_information, current_spell_id)
    if not elligibleToCast(player_information, self.spell_id, current_spell_id) then
        return false
    end
    return debuff_present(target_information, self.spell_id) == false
end

local spell_devouringPlague = {
    spell_id = 25467,
}
function spell_devouringPlague:ChooseNext(player_information, target_information, current_spell_id)
    if not elligibleToCast(player_information, self.spell_id, current_spell_id) then
        return false
    end
    return debuff_present(target_information, self.spell_id) == false
end


local spell_mindBlast = {
    spell_id = 25375,
}
function spell_mindBlast:ChooseNext(player_information, target_information, current_spell_id)
    if not elligibleToCast(player_information, self.spell_id, current_spell_id) then
        return false
    end
    return debuff_present(target_information, self.spell_id) == false
end

local spell_mindFlay = {
    spell_id = 25387
}
function spell_mindFlay:ChooseNext(player_information, target_information, current_spell_id)
    if not elligibleToCast(player_information, self.spell_id, current_spell_id) then
        return false
    end
    return debuff_present(target_information, self.spell_id) == false
end

local spell_shadowWordPain = {
    spell_id     = 25368,
}
-- spell_shadowWordPain: Is only prio when you don't have debuff up.
-- if you have 5 stacks of shadow weaving, it's okay to apply
-- if you have talent_pain_and_suffering, it will defer to that to re-apply
function spell_shadowWordPain:ChooseNext(player_information, target_information, current_spell_id)
    if not elligibleToCast(player_information, self.spell_id, current_spell_id) then
        return false
    end

    if player_information:IsBaseSpellKnown(self.spell_id) then
        -- is it already there
        if debuff_present(target_information, self.spell_id) == false then
            local ps = player_information:GetTalentInfo(talent_pain_and_suffering.tab, talent_pain_and_suffering.idx)
            if ps.rank == 0 then
                -- we don't have pain and suffering
                -- todo: check if it's expiring soon, if it is, we should re-apply
                return false
            end

            return false
        end

        -- are we talented for shadow weaving
        local sw = player_information:GetTalentInfo(talent_shadow_weaving.tab, talent_shadow_weaving.idx)
        if sw.rank == 0 then
            -- we aren't so we should re-apply every time it falls off
            return true
        end

        -- if it's not there, make sure shadow weaving is up and at 5 counts
        local weaving = player_information:GetAura(aura_shadow_weaving.spell_id)
        if not weaving or not weaving.count then
            return false
        end

        return weaving.count >= 5
    end
    return false
end

local function getPriority()
    local count = 0
    return function ()
        count = count + 1
        return count
    end
end
local priority = getPriority()

function priest_lib:LoadSpell(spell)
    if not self.spells then
        self.spells = {}
    end
    spell.priority = priority()
    local name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spell.spell_id)
    spell.name = name
    spell.texture = GetSpellTexture(spell.spell_id)
    self.spells[spell.priority] = spell
end

function priest_lib:ChooseNext(player_information, target_information, current_spell_id)
    if not player_information then
        return
    end
    for key, value in pairs(self.spells) do
        if value:ChooseNext(player_information, target_information, current_spell_id) then
            print("spell.name: ", value.name)
            return
        end
    end
end

function priest_lib:UpdateSpells(player_information, target_information)
end

function RegisterPriest()
    priest_lib._name = "PRIEST"
    priest_lib:LoadSpell(spell_vampiricTouch)
    priest_lib:LoadSpell(spell_shadowWordPain)
    priest_lib:LoadSpell(spell_devouringPlague)
    priest_lib:LoadSpell(spell_mindBlast)
    priest_lib:LoadSpell(spell_mindFlay)
    FM_CORE:RegisterClassLibrary(priest_lib)
end

RegisterPriest()