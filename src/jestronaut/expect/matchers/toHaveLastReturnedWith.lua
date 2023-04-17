--- @param expect Expect
--- @param ... any
local function toHaveLastReturnedWith(expect, ...)
  local actual = expect.value

  if not expect:checkEquals(true, actual:hasLastReturnedWith(...)) then
    error("Expected " .. tostring(actual) .. " to have last returned with " .. tostring(...) .. " but it returned with " .. tostring(actual:getLastReturn()))
  end

  return true
end

return {
  toHaveLastReturnedWith = toHaveLastReturnedWith,
  default = toHaveLastReturnedWith,
}