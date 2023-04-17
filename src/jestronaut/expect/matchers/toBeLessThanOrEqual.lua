--- 
--- @param expect Expect
--- @param value any
--- @return boolean
local function toBeLessThanOrEqual(expect, value)
  local actual = expect.value

  if not expect:checkEquals(true, actual <= value) then
    error("Expected " .. tostring(actual) .. " to be less than or equal to " .. tostring(value))
  end

  return true
end

return {
  toBeLessThanOrEqual = toBeLessThanOrEqual,
  default = toBeLessThanOrEqual,
}