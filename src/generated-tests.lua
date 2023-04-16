require "jestronaut":withGlobals()

package.path = package.path .. ";./src/generated-tests/?.lua"

--[[
  These functions and tables are used in the examples, but are not defined.
]]
module = {}

function bestLaCroixFlavor()
  return "grapefruit"
end

-- generated-tests\JestObjectAPI\jest\mock.lua:64
jestronaut:mock(
  "moduleName",
  function()
    return jestronaut:fn(function() return 42 end)
  end
)

-- generated-tests\JestObjectAPI\jest\requireActual.lua:9
package.preload['../myModule'] = function(...)
  local ____exports = {}
  ____exports.getRandom = function() return 42 end
  return ____exports
end

-- generated-tests\JestObjectAPI\jest\requireActual.lua:17
package.preload['myModule'] = package.preload['../myModule']

-- generated-tests\JestObjectAPI\jest\resetModules.lua:22
package.preload['sum'] = function(...)
  local ____exports = {}
  ____exports.sum = function(a, b) return a + b end
  return ____exports
end

-- generated-tests\ExpectAPI\expect\addSnapshotSerializer.lua:7
package.preload['my-serializer-module'] = function(...)
  local ____exports = {}
  ____exports.default = {
    -- TODO: Implement example
  }
  return ____exports
end

-- generated-tests\ExpectAPI\expect\extend.lua:293
package.preload['toBeWithinRange'] = function()
  return {
    toBeWithinRange = function(actual, floor, ceiling)
      if type(actual) ~= "number" or type(floor) ~= "number" or type(ceiling) ~= "number" then
          error(
              __TS__New(Error, "These must be of type number!"),
              0
          )
      end
      local pass = actual >= floor and actual <= ceiling
      if pass then
          return {
              message = function() return (("expected " .. tostring(self.utils:printReceived(actual))) .. " not to be within range ") .. tostring(self.utils:printExpected((tostring(floor) .. " - ") .. tostring(ceiling))) end,
              pass = true
          }
      else
          return {
              message = function() return (("expected " .. tostring(self.utils:printReceived(actual))) .. " to be within range ") .. tostring(self.utils:printExpected((tostring(floor) .. " - ") .. tostring(ceiling))) end,
              pass = false
          }
      end
    end
  }
end

-- generated-tests\GlobalAPI\afterAll.lua:7
function makeGlobalDatabase()
  return {
    insert = jestronaut:fn(),
  }
end

-- generated-tests\JestObjectAPI\jest\replaceProperty.lua:22
package.preload['utils'] = function()
  local ____exports = {}
  ____exports.isLocalhost = function(self)
      return process.env.HOSTNAME == "localhost"
  end
  return ____exports
end

-- generated-tests\JestObjectAPI\jest\spyOn.lua:19
package.preload['audio'] = function()
  local ____exports = {}
  ____exports.volume = 0
  return ____exports
end

-- generated-tests\JestObjectAPI\jest\spyOn.lua:19
package.preload['video'] = function()
  local ____exports = {}
  ____exports.play = function() return true end
  return ____exports
end

require "generated-tests.all"