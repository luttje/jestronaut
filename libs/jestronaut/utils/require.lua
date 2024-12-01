local require = require

--- Ensures that any overridden require functions are respected when calling the given callback.
--- This is done by localizing the require (see above) and then making that available
--- globally for the duration of the callback.
--- This is useful for requires that happen after the initial require override period.
--- @param callback fun(...: any): any
--- @vararg any
--- @return any
local function callRespectingRequireOverride(callback, ...)
    local oldRequire = _G.require
    _G.require = require
    local results = { callback(...) }
    _G.require = oldRequire

    return unpack(results)
end

return {
    callRespectingRequireOverride = callRespectingRequireOverride,
}
