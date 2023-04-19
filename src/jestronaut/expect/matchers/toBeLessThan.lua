--- 
--- @param expect Expect
--- @param value any
--- @return boolean
local function toBeLessThan(expect, value)
  local actual = expect.actual

  if not expect:checkEquals(true, (actual < value)) then
    error("Expected " .. tostring(actual) .. " to be less than " .. tostring(value))
  end

  return true
end

return {
  toBeLessThan = toBeLessThan,
  default = toBeLessThan,
}