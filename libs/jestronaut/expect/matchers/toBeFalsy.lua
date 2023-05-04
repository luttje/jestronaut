--- 
--- @param expect Expect
--- @return boolean
local function toBeFalsy(expect)
  if not expect:checkEquals(true, not expect.actual) then
    error("Expected " .. tostring(expect.actual) .. " to be falsy")
  end

  return true
end

return {
  toBeFalsy = toBeFalsy,
  default = toBeFalsy,
}