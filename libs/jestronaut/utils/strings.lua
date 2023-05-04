--- Splits a string into a table of strings at the given seperator (defaults to any whitespace)
--- @param str string
--- @param seperator string
--- @return table
local function split(str, seperator)
  local pattern
  
  if seperator == '' then
    pattern = '.'
  else
    if seperator == nil then
      seperator = "%s"
    end

    pattern = "([^"..seperator.."]+)"
  end

  local t = {}
  
  for str in string.gmatch(str, pattern) do
    table.insert(t, str)
  end

  return t
end

--- Implodes a path table into a string.
--- @param path table
--- @return string
local function implodePath(path)
  local pathAsString = ''

  for _, v in ipairs(path) do
    if type(v) ~= 'string' then
      pathAsString = pathAsString .. '[' .. tostring(v) .. ']'
    else
      pathAsString = pathAsString .. '.' .. v
    end
  end

  pathAsString = pathAsString:gsub('^%.', '')
  return pathAsString
end

--- Converts any backward slashes to forward slashes, removing duplicates, trailing slashes. Starts the string with ./ if it doesn't already.
--- @param path string
--- @return string
local function normalizePath(path)
  local normalizedPath = path:gsub('\\', '/'):gsub('/+', '/'):gsub('/$', '')

  if normalizedPath:sub(1, 2) ~= './' then
    normalizedPath = './' .. normalizedPath
  end

  return normalizedPath
end

--- Prefixes each line in a string with a prefix.
--- @param string string
--- @param prefix string
--- @return string
local function prefixLines(string, prefix)
  local lines = split(string, "\n")
  local prefixedLines = {}

  for _, line in ipairs(lines) do
    table.insert(prefixedLines, prefix .. line)
  end

  return table.concat(prefixedLines, "\n")
end

return {
  split = split,
  implodePath = implodePath,
  normalizePath = normalizePath,
  prefixLines = prefixLines,
}