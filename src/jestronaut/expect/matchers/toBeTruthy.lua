--- 
--- @param expect Expect
--- @return boolean
local function toBeTruthy(expect)
  if not expect:checkEquals(false, not expect.value) then
    error("Expected " .. tostring(expect.value) .. " to be truthy")
  end

  return true
end

return {
  toBeTruthy = toBeTruthy,
  default = toBeTruthy,
}