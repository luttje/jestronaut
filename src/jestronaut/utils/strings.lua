local function split (inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

local function implodePath(path)
  local s = ''
  for _, v in ipairs(path) do
    if type(v) == 'number' then
      s = s .. '[' .. v .. ']'
    else
      s = s .. '.' .. v
    end
  end

  return s:gsub('^.', '')
end

--- Converts any backward slashes to forward slashes, removing duplicates, trailing slashes. Starts the string with ./ if it doesn't already.
local function normalizePath(path)
  local normalizedPath = path:gsub('\\', '/'):gsub('/+', '/'):gsub('/$', '')

  if normalizedPath:sub(1, 2) ~= './' then
    normalizedPath = './' .. normalizedPath
  end

  return normalizedPath
end

return {
  split = split,
  implodePath = implodePath,
  normalizePath = normalizePath,
}