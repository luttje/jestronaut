--- 
--- @param expect Expect
--- @return boolean
local function toBeFalsy(expect)
  if not ((not expect.value) == true) then
    error("Expected " .. tostring(expect.value) .. " to be falsy")
  end

  return true
end

return {
  toBeFalsy = toBeFalsy,
}