--- 
--- @param expect Expect
--- @param value any
--- @return boolean
local function toBeGreaterThan(expect, value)
  local actual = expect.value

  if not (actual > value) then
    error("Expected " .. tostring(actual) .. " to be greater than " .. tostring(value))
  end

  return true
end

return {
  toBeGreaterThan = toBeGreaterThan,
  default = toBeGreaterThan,
}