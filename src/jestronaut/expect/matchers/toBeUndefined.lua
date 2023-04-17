--- @param expect Expect
--- @return boolean
local function toBeUndefined(expect)
  if not expect:checkEquals(true, expect.value == nil) then
    error("Expected " .. tostring(expect.value) .. " to be undefined")
  end

  return true
end

return {
  toBeUndefined = toBeUndefined,
  default = toBeUndefined,
}