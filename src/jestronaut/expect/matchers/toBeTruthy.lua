--- 
--- @param expect Expect
--- @return boolean
local function toBeTruthy(expect)
  if not ((not expect.value) == false) then
    error("Expected " .. tostring(expect.value) .. " to be truthy")
  end

  return true
end

return {
  toBeTruthy = toBeTruthy,
}