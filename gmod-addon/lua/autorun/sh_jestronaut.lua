-- Gmod's require doesn't return any values, so we replace require with include while loading jestronaut
-- This is a hacky way to make jestronaut work with Gmod
local function callWithRequireCompat(func)
  local oldRequire = require
  local alreadyRequired = {}

  package.path = package.path or ""

  require = function(path)
    if (alreadyRequired[path] == nil) then
      if (file.Exists(path .. ".lua", "LUA")) then
        alreadyRequired[path] = {include(path .. ".lua")}
      else
        Msg("Could not find file: " .. path)
        return false
      end
    end

    return unpack(alreadyRequired[path])
  end

  local result = func()

  require = oldRequire

  return result
end

local jestronaut = callWithRequireCompat(function()
  local jestronaut = include("jestronaut.lua")

  GmodReporter = include("sh_jestronaut_gmod_reporter.lua").GmodReporter

  return jestronaut
end)

jestronaut.callWithRequireCompat = callWithRequireCompat

jestronaut:withGlobals()
