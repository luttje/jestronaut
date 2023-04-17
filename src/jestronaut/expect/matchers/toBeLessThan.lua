--- 
--- @param expect Expect
--- @param value any
--- @return boolean
local function toBeLessThan(expect, value)
  local actual = expect.value

  if not (actual < value) then
    error("Expected " .. tostring(actual) .. " to be less than " .. tostring(value))
  end

  return true
end

return {
  toBeLessThan = toBeLessThan,
}