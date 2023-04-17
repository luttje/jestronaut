--- Calls the function and expects it to throw an error.
--- @param expect Expect
--- @param customErrorType any
--- @return boolean
local function toThrow(expect, customErrorType)
  local success, err = pcall(expect.value)

  if not expect:checkEquals(false, success) then
    error('Expected the function to throw an error.')
  end

  if not expect:checkEquals(true, customErrorType and customErrorType == err) then
    error('Expected the function to throw an error of type ' .. customErrorType .. ' but it threw an error of type ' .. err)
  end

  return true
end

return {
  toThrow = toThrow,
  default = toThrow,
}