--- @param expect Expect
--- @param nthReturned number
--- @param ... any
local function toHaveNthReturnedWith(expect, nthReturned, ...)
  local actual = expect.value

  if not expect:checkEquals(true, actual:hasNthReturnedWith(nthReturned, ...)) then
    error("Expected " .. tostring(actual) .. " to have returned with " .. tostring(...) .. " but it returned with " .. tostring(actual:getLastReturn()))
  end

  return true
end

return {
  toHaveNthReturnedWith = toHaveNthReturnedWith,
  default = toHaveNthReturnedWith,
}