local environmentLib = require "jestronaut.environment"
local expectLib = require "jestronaut.expect"
local mockLib = require "jestronaut.mock"

--- @class Jestronaut
local JESTRONAUT = {}

function JESTRONAUT:createMockFromModule(moduleName)
  return {
    fn = function()
      --- @Not implemented
    end,
  }; --- @Not implemented
end

function JESTRONAUT:resetModules()
  -- Hack: https://www.freelists.org/post/luajit/BUG-Assertion-failures-when-unloading-and-reloading-the-ffi-package,1
  package.loaded = {}
end

function JESTRONAUT:isolateModules(fn)
  local originalPackagePreload = package.preload
  package.preload = {}
  fn()
  package.preload = originalPackagePreload
end

function JESTRONAUT:isolateModulesAsync(fn)
  --- @Not implemented (async)
end

function JESTRONAUT:getGlobals()
  local globals = {}

  expectLib.exposeTo(globals)
  environmentLib.exposeTo(globals)

  globals.jestronaut = self
  mockLib.exposeTo(globals.jestronaut)

  return globals
end

function JESTRONAUT:withGlobals()
  local globals = self:getGlobals()

  for key, value in pairs(globals) do
    _G[key] = value
  end
end

package.preload['@jestronaut_globals'] = function()
  return JESTRONAUT:getGlobals()
end

return JESTRONAUT