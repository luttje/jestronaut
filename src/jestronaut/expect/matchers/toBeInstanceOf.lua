--- 
--- @param expect Expect
--- @param value any
--- @return boolean
local function toBeInstanceOf(expect, value)
  local actual = expect.value

  if type(value) == 'table' then
    if not expect:checkEquals(true, actual.____constructor and actual.____constructor == value.prototype.____constructor) then
      error("Expected " .. tostring(actual) .. " to be an instance of " .. tostring(value))
    end
  elseif not expect:checkEquals(type(actual), value) then
    error("Expected " .. tostring(actual) .. " to be an instance of " .. tostring(value))
  end


  return true
end

return {
  toBeInstanceOf = toBeInstanceOf,
  default = toBeInstanceOf,
}