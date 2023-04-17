--- Calls the function and expects it to throw an error.
--- @param expect Expect
--- @param customErrorType any
--- @return boolean
local function toThrow(expect, customErrorType)
  local success, err = pcall(expect.value)

  if success then
    error('Expected the function to throw an error.')
  end

  if customErrorType and customErrorType ~= err then
    error('Expected the function to throw an error of type ' .. customErrorType .. ' but it threw an error of type ' .. err)
  end

  return true
end

return {
  toThrow = toThrow,
}