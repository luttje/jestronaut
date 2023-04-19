--- 
--- @param expect Expect
--- @return boolean
local function toBeTruthy(expect)
  if not expect:checkEquals(false, not expect.actual) then
    error("Expected " .. tostring(expect.actual) .. " to be truthy")
  end

  return true
end

return {
  toBeTruthy = toBeTruthy,
  default = toBeTruthy,
}