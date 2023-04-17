--- 
--- @param expect Expect
--- @param value any
--- @return boolean
local function toBeGreaterThanOrEqual(expect, value)
  local actual = expect.value

  if not expect:checkEquals(true, actual >= value) then
    error("Expected " .. tostring(actual) .. " to be greater than or equal to " .. tostring(value))
  end

  return true
end

return {
  toBeGreaterThanOrEqual = toBeGreaterThanOrEqual,
  default = toBeGreaterThanOrEqual,
}