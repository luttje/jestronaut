--- @param expect Expect
--- @param ... any
local function toHaveBeenCalledWith(expect, ...)
  local actual = expect.value

  if not (actual:wasCalledWith(...)) then
    local tbl = {...}

    if #tbl == 0 then
      error("Expected " .. tostring(actual) .. " to have been called with no arguments but it was called with " .. table.concat(actual:getCallArgs(), ", "))
    else
      local expected = ""
      for key, value in pairs(tbl) do
        if key == #tbl then
          expected = expected .. tostring(value)
        else
          expected = expected .. tostring(value) .. ", "
        end
      end
      error("Expected " .. tostring(actual) .. " to have been called with " .. expected .. " but it was called with " .. table.concat(actual:getCallArgs(), ", "))
    end
  end

  return true
end

return {
  toHaveBeenCalledWith = toHaveBeenCalledWith,
}