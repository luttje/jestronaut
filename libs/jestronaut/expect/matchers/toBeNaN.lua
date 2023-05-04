--- 
--- @param expect Expect
--- @param value any
--- @return boolean
local function toBeNaN(expect, value)
  local actual = expect.actual

  if not expect:checkEquals(true, tostring(actual) == tostring((0/0)) 
  or tostring(actual) == tostring(-(0/0))) then
    error("Expected " .. tostring(actual) .. " to be NaN")
  end

  return true
end

return {
  toBeNaN = toBeNaN,
  default = toBeNaN,
}