--- Replace a function with a callback function that is called after the original function is called, allowing us to spy on the function.
--- @param fn fun(...): any
--- @param callback fun(success: boolean, ...): void
local function makeFunctionShim(fn, callback)
    return function(...)
        local success, result = pcall(fn, ...)

        callback(success, ...)

        if not success then
            error(result, 2)
        end

        return result
    end
end

--- Captures the vararg results of a (x)pcall function call into a table.
--- @param success boolean
--- @vararg any
--- @return boolean, table
local function captureSafeCallInTable(success, ...)
    local output = {}

    for key, value in ipairs({ ... }) do
        output[key] = value
    end

    return success, output
end

return {
    makeFunctionShim = makeFunctionShim,
    captureSafeCallInTable = captureSafeCallInTable,
}
