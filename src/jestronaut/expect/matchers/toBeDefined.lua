--- @param expect Expect
--- @return boolean
local function toBeDefined(expect)
  if not expect:checkEquals(true, expect.value ~= nil) then
    error("Expected " .. tostring(expect.value) .. " to be defined")
  end

  return true
end

return {
  toBeDefined = toBeDefined,
  default = toBeDefined,
}