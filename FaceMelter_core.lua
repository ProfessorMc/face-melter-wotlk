FM_CORE = {}
local player_information = CreatePlayer()
local fm_libs = {}
local logger = GetLogger()


function FM_CORE:OnLoad(addon)
    if addon ~= "FaceMelterWotlk" then
        return
    end
    local playerClass = player_information:GetClass()
    if FM_CORE:IsClassSupported(playerClass) ~= true then
        UnregisterEvents()
        logger:log_info('playerClass: ', playerClass,' not supported')
    else
        RegisterEvents()
        player_information:UpdateCharacter()
        logger:log_info('loaded playerClass: ', playerClass,' player name: ', self:GetPlayerName())
    end
end

function FM_CORE:RegisterClassLibrary(class_lib)
    if not class_lib then
        logger:log_error('class_lib invalid')
        return
    end
    fm_libs[class_lib._name] = class_lib
end

function FM_CORE:IsClassSupported(class_name)
    if not class_name or not fm_libs[class_name] then
        return false
    end
    return true
end

function FM_CORE:GetPlayerInformation()
    return player_information
end

function FM_CORE:GetPlayerName()
    return player_information:GetName()
end

function FM_CORE:UpdatePlayerInformation()
    logger:log_info('FM_CORE:UpdatePlayerInformation')
    player_information:CharacterUpdate()
    FM_CORE:HandleTargetChange()
end

function FM_CORE:HandlePlayerAuraUpdate()
    logger:log_debug('FM_CORE:HandlePlayerAuraUpdate')
    player_information:OnAuraChange()
end

function FM_CORE:HandlePlayerTalentUpdate()
    logger:log_debug('FM_CORE: updating player information for talent change')
    player_information:OnSpecChange()
    FM_CORE:HandleTargetChange()
    logger:log_info('spec changed. loaded playerClass: ', player_information:GetClass(),' player name: ', self:GetPlayerName())
end

function FM_CORE:SetInCombat(in_combat)
    player_information:SetInCombat(in_combat)
end

function FM_CORE:HandleTargetChange()
    if not self.target_info then
        self.target_info = CreateTarget()
    end
    fm_libs[player_information:GetClass()]:ChooseNext(player_information, self.target_info)
end


function FM_CORE:HandleStartCasting(spell_id)
    -- if not self.target_info then
    --     self.target_info = CreateTarget()
    -- end
    -- fm_libs[player_information:GetClass()]:ChooseNext(player_information, self.target_info, spell_id)
end

function FM_CORE:HandleCastComplete()
    if not self.target_info then
        self.target_info = CreateTarget()
    end
    fm_libs[player_information:GetClass()]:ChooseNext(player_information, self.target_info, spell_id)
end

function FM_CORE:PushNext(spell_id)
    if not self.target_info then
        self.target_info = CreateTarget()
    end
    fm_libs[player_information:GetClass()]:ChooseNext(player_information, self.target_info, spell_id)
end

function FM_CORE:HandleTargetAuraUpdate()

end

function FM_CORE:SetSelfTarget()

end

function FM_CORE:SetFriendlyTarget()

end

function FM_CORE:SetHostileTarget()
end

function FM_CORE:SetNoTarget()

end








