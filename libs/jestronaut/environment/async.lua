--- Marks functions wrapped with jestronaut:async.
local ASYNC_FUNCTION_META = {}

--- Whether debug.getinfo reports the number of parameters a function has (Lua 5.2+ and LuaJIT, not Lua 5.1).
local CAN_COUNT_PARAMETERS = (function()
    local info = debug.getinfo(function(_) end, "u")

    return info ~= nil and info.nparams == 1
end)()

--- Marks a test or hook function as asynchronous: it receives a `done` callback and the test only finishes once that
--- is called. On Lua 5.2+ and LuaJIT this is detected automatically for functions that take a parameter, on Lua 5.1
--- functions have to be marked with this.
--- @param fn fun(done: fun(err?: any))
--- @return table
local function markAsync(fn)
    if type(fn) ~= "function" then
        error("jestronaut:async expects a function, got " .. type(fn), 3)
    end

    return setmetatable({ fn = fn }, ASYNC_FUNCTION_META)
end

--- Checks whether a test or hook function is marked with jestronaut:async.
--- @param fn any
--- @return boolean
local function isMarkedAsync(fn)
    return getmetatable(fn) == ASYNC_FUNCTION_META
end

--- Gets the function to call for a test or hook, and whether it takes a done callback.
--- @param fnOrAsync function|table
--- @return function, boolean
local function getFunction(fnOrAsync)
    if isMarkedAsync(fnOrAsync) then
        return fnOrAsync.fn, true
    end

    if type(fnOrAsync) == "function" and CAN_COUNT_PARAMETERS then
        return fnOrAsync, debug.getinfo(fnOrAsync, "u").nparams > 0
    end

    return fnOrAsync, false
end

--- Passed instead of a done callback to test functions that aren't asynchronous on Lua 5.1, where a function(done)
--- can't be detected. Calling it explains how to mark the function.
local function doneOnLua51()
    error("This test or hook calls done, but on Lua 5.1 asynchronous functions can't be detected. " ..
        "Wrap the function with jestronaut:async(function(done) ... end).", 2)
end

return {
    CAN_COUNT_PARAMETERS = CAN_COUNT_PARAMETERS,
    markAsync = markAsync,
    isMarkedAsync = isMarkedAsync,
    getFunction = getFunction,
    doneOnLua51 = doneOnLua51,
}
