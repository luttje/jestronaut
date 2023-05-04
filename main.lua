package.path = "./libs/?.lua;" .. package.path -- Try our local version first
require "jestronaut":withGlobals()
local config = {}

for _, arg in ipairs(args) do
  local key, value = arg:match("^%-%-([%w_]+)=(.+)$")

  if value == "true" then
    value = true
  elseif value == "false" then
    value = false
  end

  if key then
    if config[key] then
      if type(config[key]) == "table" then
        table.insert(config[key], value)
      else
        config[key] = {config[key], value}
      end
    else
      config[key] = value
    end
  end
end

if not config.roots or #config.roots == 0 then
  print("No roots set. Please set the roots to your test files. For example: `jestronaut --roots=./tests/`")
  os.exit(1)
end

local tableConfigKeys = {
  roots = true,
  testPathIgnorePatterns = true,
}

for key, value in pairs(config) do
  if tableConfigKeys[key] then
    if type(value) ~= "table" then
      config[key] = {value}
    end
  end
end

jestronaut
  :configure(config)
  :registerTests(function()
    package.path = package.path .. ";./?.lua;./?/init.lua"

    for _, root in pairs(config.roots) do
      require(root:gsub("^%./",""):gsub("/","."):gsub("%.lua",""))
    end
  end)
  :runTests()