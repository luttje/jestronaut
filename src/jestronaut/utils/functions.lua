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

return {
  makeFunctionShim = makeFunctionShim,
}