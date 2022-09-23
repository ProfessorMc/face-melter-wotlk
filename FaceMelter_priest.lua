local priest_lib = {}
local logger = GetLogger()
logger:SetDebug(false)

local function elligibleToCast(player_information, spell_id, current_spell_id)
    if spell_id == current_spell_id then
        return
    end

    local is_known = player_information:IsBaseSpellKnown(spell_id)
    if is_known == false then
        return
    end

    priest_lib:UpdateSetSpellCooldown(spell_id)
    -- local priest_lib:GetSpellCooldown()
    local start, gcd_duration, enabled, gcd_modRate = GetSpellCooldown(61304)
    -- print("Spell GCD cooldown: " .. gcd_duration .. " seconds. mod: ", gcd_modRate, " enabled: ", enabled)
    local start, duration, enabled, modRate = GetSpellCooldown(spell_id)
    if enabled == 0 then
        return true
    elseif ( start > 0 and duration > 0) then
        local cdLeft = start + duration - GetTime()
        logger:log_debug("spell_id", spell_id, "cdLeft", cdLeft, cdLeft < gcd_duration)
        -- local myTimer = C_Timer.NewTimer(cdLeft, function() print("CD_RESET", FM_CORE:SetUpdateCooldown()) end)

        return cdLeft < gcd_duration
    else
        logger:log_debug("spell_id", spell_id, " start ",  start, " duration ",duration, " enabled ",enabled, " modRate ", modRate)
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

local function get_debuff_cd(target_information, spell_id)
    return target_information:GetDebuffDuration(spell_id)
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

local spell_vampiricEmpbrace = {
    spell_id     = 15286,
}

function spell_vampiricEmpbrace:ChooseNext(player_information, target_information, current_spell_id)
    if not elligibleToCast(player_information, self.spell_id, current_spell_id) then
        return false
    end
    local weaving = player_information:GetAura(aura_shadow_weaving.spell_id)
    return debuff_present(target_information, self.spell_id) == false
end

local spell_shadowWordDeath = {
    spell_id     = 32996,
}

function spell_shadowWordDeath:ChooseNext(player_information, target_information, current_spell_id)
    -- if not elligibleToCast(player_information, self.spell_id, current_spell_id) then
    --     return false
    -- end
    return false
end

local spell_smite = {
    spell_id     = 585,
}

function spell_smite:ChooseNext(player_information, target_information, current_spell_id)
    if not elligibleToCast(player_information, self.spell_id, current_spell_id) then
        return false
    end
    return true
end


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
        -- logger:log_debug("spell_mindFlay Inelligible to cast")
        return false
    end

    -- logger:log_debug("spell_mindFlay self.spell_id to cast")
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
        logger:log_debug("SWP Inelligible to cast")
        return false
    end

    if debuff_present(target_information, self.spell_id) then
        local ps = player_information:GetTalentInfo(talent_pain_and_suffering.tab, talent_pain_and_suffering.idx)
        if ps.rank == 0 then
            -- we don't have pain and suffering
            -- todo: check if it's expiring soon, if it is, we should re-apply
            logger:log_debug("SWP no ps to cast")
            return false
        end
        logger:log_debug("SWP w// ps to cast")
        return false
    end
    -- are we talented for shadow weaving
    local sw = player_information:GetTalentInfo(talent_shadow_weaving.tab, talent_shadow_weaving.idx)
    if sw.rank == 0 then
        -- we aren't so we should re-apply every time it falls off
        logger:log_debug("SWP no weaving talent to cast")
        return true
    end

    -- if it's not there, make sure shadow weaving is up and at 5 counts
    local weaving = player_information:GetAura(aura_shadow_weaving.spell_id)
    if not weaving or not weaving.count then
        logger:log_debug("SWP no weaving to cast")
        return false
    end
    logger:log_debug("SWP weaving to cast")
    return weaving.count >= 5
end

local function getPriority()
    local count = 0
    return function ()
        count = count + 1
        return count
    end
end
local priority = getPriority()

function priest_lib:GetSpells()
    return self.spells
end

function priest_lib:UpdateSetSpellCooldown(spell_id)
    if not self.spells_cd then
        self.spells_cd = {}
    end

    if not self.spells_cd then
        self.spells_cd = {}
    end

    local _, gcd_duration, _, _ = GetSpellCooldown(61304)

    local current_cd = self.spells_cd[spell_id]
    if not current_cd then
        local new_cd = {}
        new_cd.start, new_cd.duration, new_cd.enabled, new_cd.modRate = GetSpellCooldown(spell_id)
        current_cd = new_cd
    end

    if (current_cd.start > 0 and current_cd.duration > 0) then
        -- self.spells_cd[spell_id] = current_cd
         -- see if there is enough time for us to care about it
        local cdLeft = current_cd.start + current_cd.duration - GetTime()
        if cdLeft > gcd_duration then
            C_Timer.After(cdLeft, function()
                self.spells_cd[spell_id].pending_timer = false
                FM_CORE:SetUpdateCooldown()
            end)
            self.spells_cd[spell_id] = current_cd
        elseif cdLeft > 0 then
            self.spells_cd[spell_id] = current_cd
        else
            self.spells_cd[spell_id] = nil
            return
        end

    else
        -- it's expired, reset it
        self.spells_cd[spell_id] = nil
        return
    end

    self.spells_cd[spell_id] = current_cd
end

function priest_lib:GetSpellCooldown(spell_id, target_information)
    logger:log_debug("priest_lib:GetSpellCooldown")
    priest_lib:UpdateSetSpellCooldown(spell_id)
    local player_cd = self.spells_cd[spell_id]
    local player_start, player_duration = 0, 0
    if not player_cd then
    else
        player_start, player_duration = player_cd.start, player_cd.duration
    end
    logger:log_debug("defer to player_cd: ", player_start, "end: ", player_duration)
    if not target_information then
    else
        local start, duration = get_debuff_cd(target_information, spell_id)
        if start > 0 and duration > 0 then
            if start + duration > player_start + player_duration then
                logger:log_debug("end_chose debuff priest_lib:GetSpellCooldown")
                return start, duration
            end
        else
            logger:log_debug("defer to player_cd: ", player_start, "end: ", player_duration)
        end
    end
    logger:log_debug("end_chose  player_cd: ", player_start, "end: ", player_duration)
    return player_start, player_duration
end

function priest_lib:GetSpellById(spell_id)
    return self.spells
end

function priest_lib:LoadSpell(spell)
    if not self.spells then
        self.spells = {}
    end
    spell.priority = priority()
    local name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spell.spell_id)
    spell.name = name
    spell.is_next = false
    spell.texture = GetSpellTexture(spell.spell_id)
    self.spells[spell.priority] = spell
end

function priest_lib:ChooseNext(player_information, target_information, current_spell_id)
    if not player_information then
        return
    end
    local next_chosen = false
    for key, value in pairs(self.spells) do
        if next_chosen then
            value.is_next = false
            logger:log_debug("Skipped: ", value.name)
        elseif value:ChooseNext(player_information, target_information, current_spell_id) then
            value.is_next = true
            next_chosen = true
            logger:log_debug("Chose: ", value.name)
        else
            value.is_next = false
            logger:log_debug("NoChose: ", value.name)
        end
    end
end

-- function priest_lib:get_cooldown(spell, player_information, target_information)
--     if not spell:get_cooldown() then
--         return 0, 0
--     end
--     return spell:get_cooldown()
-- end

-- function priest_lib:UpdateSpells(player_information, target_information)
--     if not player_information then
--         return
--     end
--     local next_chosen = false
--     for key, value in pairs(self.spells) do
--         if next_chosen then
--             value.is_next = false
--         elseif value:ChooseNext(player_information, target_information) then
--             value.is_next = true
--             next_chosen = true
--         else
--             value.is_next = false
--         end
--     end

-- end

function priest_lib:SpellCount(player_information)
    if not player_information then
        print("player_information is nit")
    end
    local count = 0
    for key, value in pairs(self.spells) do
        if value.enabled == false then
            -- print("spell is disabled")
        else
            local is_known = player_information:IsBaseSpellKnown(value.spell_id)
            -- print("spell is checked")
            if is_known then
                -- print("spell is known")
                count = count + 1
            end
        end
    end
    return count
end


function RegisterPriest()
    priest_lib._name = "PRIEST"
    priest_lib:LoadSpell(spell_shadowWordPain)
    priest_lib:LoadSpell(spell_vampiricTouch)
    priest_lib:LoadSpell(spell_devouringPlague)  
    priest_lib:LoadSpell(spell_mindBlast)
    -- priest_lib:LoadSpell(spell_shadowWordDeath)
    -- priest_lib:LoadSpell(spell_vampiricEmpbrace)
    priest_lib:LoadSpell(spell_mindFlay)
    
    -- priest_lib:LoadSpell(spell_smite)
    FM_CORE:RegisterClassLibrary(priest_lib)
end

RegisterPriest()