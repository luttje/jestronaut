local environmentLib = require "jestronaut.environment"
local expectLib = require "jestronaut.expect"
local mockLib = require "jestronaut.mock"
local setupModuleMocking = mockLib.setupModuleMocking

setupModuleMocking()

--- @class Jestronaut
local JESTRONAUT = {}

function JESTRONAUT:retryTimes(numRetries, options)
  environmentLib.retryTimes(numRetries, options)
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