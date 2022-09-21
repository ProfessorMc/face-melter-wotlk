local logger = {}
logger.log_level_debug = false

function GetLogger()
    return logger
end

function logger:SetDebug()
    self.log_level_debug = true
end

function logger:log_info(...)
    self:_log("|cff00ffff", ...)
end

function logger:log_debug(...)
    if logger.log_level_debug == true then
        self:_log("|cff888888", ...)
    end
end

function logger:log_error(...)
    self:_log("|cffff8888", 'err:', ...)
end

function logger:_log(color, ...)
    print(color, '[FACEMELTER] ', ...)
end
