local logger_prototype = {}
logger_prototype.log_level_debug = false

local metatable = {
    __index = logger_prototype
}

function GetLogger()
    return setmetatable({}, metatable)
end

function logger_prototype:SetDebug(debug_level)
    self.log_level_debug = debug_level
end

function logger_prototype:log_info(...)
    self:_log("|cff00ffff", ...)
end

function logger_prototype:log_debug(...)
    if not self.log_level_debug then
        self.log_level_debug = false
    end
    if self.log_level_debug == true then
        self:_log("|cff888888", ...)
    end
end

function logger_prototype:log_error(...)
    self:_log("|cffff8888", 'err:', ...)
end

function logger_prototype:_log(color, ...)
    print(color, '[FACEMELTER] ', ...)
end
