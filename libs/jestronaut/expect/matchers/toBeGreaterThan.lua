--- 
--- @param expect Expect
--- @param value any
--- @return boolean
local function toBeGreaterThan(expect, value)
  local actual = expect.actual

  if not expect:checkEquals(true, actual > value) then
    error("Expected " .. tostring(actual) .. " to be greater than " .. tostring(value))
  end

  return true
end

return {
  toBeGreaterThan = toBeGreaterThan,
  default = toBeGreaterThan,
}