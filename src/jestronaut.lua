local environmentLib = require "jestronaut.environment"
local expectLib = require "jestronaut.expect"
local mockLib = require "jestronaut.mock"
local setupModuleMocking = mockLib.setupModuleMocking

setupModuleMocking()

--- @class Jestronaut
local JESTRONAUT = {}

function JESTRONAUT:resetModules()
  -- Hack: https://www.freelists.org/post/luajit/BUG-Assertion-failures-when-unloading-and-reloading-the-ffi-package,1
  -- package.loaded = {} -- Dont do this, breaks everything
end

function JESTRONAUT:isolateModules(fn)
  local originalPackagePreload = package.preload
  local originalPackageLoaded = package.loaded
  package.preload = {}
  package.loaded = {}
  fn()
  package.loaded = originalPackageLoaded
  package.preload = originalPackagePreload
end

function JESTRONAUT:isolateModulesAsync(fn)
  --- @Not implemented (async)
end

function JESTRONAUT:retryTimes(numRetries, options)
  environmentLib.setRetryTimes(numRetries, options)
end

function JESTRONAUT:setTimeout(timeout)
  environmentLib.setTimeout(timeout)
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

package.loaded['@jestronaut_globals'] = JESTRONAUT:getGlobals()

return JESTRONAUT