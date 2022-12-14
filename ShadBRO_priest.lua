-- /dump GetSpellInfo(15286)
-- /dump IsUsableSpell(15286)
-- /dump IsSpellKnown(15286)
ShadowWordPainId = 25368 --"Shadow Word: Pain"
Spell_priest_shadowWordPain = {
    SpellId     = 25368,
    Enabled     = true,
    IsKnown     = false,
    IsDot       = true,
    IsCastable  = true,
    Priority    = 5
}

Spell_priest_vampiricTouch = {
    SpellId     = 34917,
    Enabled     = true,
    IsKnown     = false,
    IsDot       = true,
    IsCastable  = true,
    texture     = {},
    Priority    = 1
}

Spell_priest_devouringPlague = {
    SpellId = 25467,
    Enabled  = true,
    IsKnown = false,
    IsDot   = true,
    IsCastable  = true,
    texture  = {},
    Priority = 2
}

Spell_priest_vampiricEmpbrace = {
    SpellId = 15286,
    Enabled  = true,
    IsKnown = false,
    IsDot   = true,
    IsCastable  = true,
    texture     = {},
    Priority = 6
}

Spell_priest_mindBlast = {
    SpellId = 25375,
    Enabled  = true,
    IsKnown = false,
    IsDot   = true,
    IsCastable  = true,
    texture  = {},
    Priority = 3
}

Spell_priest_shadowWordDeath = {
    SpellId = 32996,
    Enabled  = true,
    IsKnown = false,
    IsDot   = true,
    IsCastable  = true,
    texture  = {},
    Priority = 7
}

Spell_priest_mindFlay = {
    SpellId = 25387,
    Enabled  = true,
    IsKnown = false,
    IsDot   = true,
    IsCastable  = true,
    texture  = {},
    Priority = 4
}

Spell_priest_shadowWeaving = {
    SpellId  = 15332,
    AuraId   = 15258,
    Enabled  = true,
    IsKnown  = false,
    IsDot    = false,
    IsAura   = true,
    IsCastable  = false,
    texture  = {},
    Priority = 10
}




function LoadPriestSpells()
    LoadSpell(Spell_priest_shadowWordPain)
    LoadSpell(Spell_priest_vampiricTouch)
    LoadSpell(Spell_priest_devouringPlague)
    LoadSpell(Spell_priest_vampiricEmpbrace)
    LoadSpell(Spell_priest_shadowWeaving)
    LoadSpell(Spell_priest_mindFlay)
    LoadSpell(Spell_priest_shadowWordDeath)
    LoadSpell(Spell_priest_mindBlast)
end

function LoadSpell(Spell)
    local name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(Spell.SpellId)
    Spell.Name  = name
    Spell.IsKnown                          = IsSpellKnown(Spell_priest_shadowWordPain.SpellId)
    Shadbro.SpellTextures[Spell.SpellId]   = GetSpellTexture(Spell.SpellId)
    Shadbro.SpellList[Spell.SpellId]       = Spell
    Shadbro.Priority[Spell.Priority]       = Spell.SpellId
    -- Spell.ActionButton = C_ActionBar.FindSpellActionButtons(Spell.SpellId)
    -- if Spell.ActionButton then
    --     sbd:log_debug('Value:', Shadbro.SpellList[Spell.SpellId].Name, "Action Button: ", Spell.ActionButton[1])
    -- end
end

function DecideTicks()
-- /dump GetSpellInfo(15332)
-- /dump GetSpellSubtext(15332)
end

function IterateSpells()
    for key,value in pairs(Shadbro.spellsList) do --pseudocode
        sbd:log_debug(Shadbro.spellsNames[key], " Cast Time: ", Shadbro.castTime[key])
    end
end

function GetSpellState(self)
    if not self or not self:GetState() then
        return
    end
    self:GetState()
end

local STATE_UNKNOWN = "STATE_UNKNOWN"
local STATE_DISABLED = "STATE_DISABLED"


function Spell_priest_shadowWordPain:GetState()
    sbd:log_debug("GetState: ", Spell_priest_shadowWordPain.Name)
end

function UpdateTargetDots()
    local painFound = IsOnTarget(spell_priest_swp)
    if painFound ~= true then
        sbd:log_debug("Shadow Word: Pain")
    end
    C_Timer.After(1, UpdateTargetDots)
end


function IsOnTarget(id)
    for i=1,40 do 
        local name, _, count, _, _, _, source, _, _, spellId, canApplyAura, _, _, _, _ = UnitDebuff("target",i)
        -- and spellId == ShadowWordPainId
        if source == "player"  and spellId == id then 
            sbd:log_debug("Checking target: ", name, ":",source, ":",spellId, ":",canApplyAura)
            return true
        end
    end
    -- AuraUtil.ForEachAura("player", "HELPFUL", nil, foo)
    return false
end