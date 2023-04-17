require "jestronaut":withGlobals()

package.path = package.path .. ";./src/generated-tests/?.lua"

-- Preloads the provided module into the package.loaded table
function generatedTestPreLoad(moduleName, moduleBuilder)
  local module = moduleBuilder(moduleName)
  package.loaded[moduleName] = module
  package.loaded[moduleName:gsub("_js$", "")] = module
end

--[[
  These functions and tables are used in the examples, but are not defined.
]]
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
package.loaded['../myModule'] = {
  getRandom = function() return 42 end
}

-- generated-tests\JestObjectAPI\jest\requireActual.lua:17
package.loaded['myModule'] = package.loaded['../myModule']

-- generated-tests\JestObjectAPI\jest\resetModules.lua:22
package.loaded['sum'] = {
  sum = function(a, b) return a + b end
}

-- generated-tests\ExpectAPI\expect\addSnapshotSerializer.lua:7
package.loaded['my-serializer-module'] = {
  default = {
    -- TODO: Implement example
  }
}

-- generated-tests\ExpectAPI\expect\extend.lua:293
package.loaded['toBeWithinRange'] = {
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

-- generated-tests\GlobalAPI\afterAll.lua:7
function makeGlobalDatabase()
  return {
    insert = jestronaut:fn(),
  }
end

-- generated-tests\JestObjectAPI\jest\replaceProperty.lua:22
package.loaded['utils'] = {
  isLocalhost = function(self)
      return process.env.HOSTNAME == "localhost"
  end
}

-- generated-tests\JestObjectAPI\jest\spyOn.lua:19
package.loaded['audio'] ={
  volume = 0
}

-- generated-tests\JestObjectAPI\jest\spyOn.lua:19
package.loaded['video'] = {
  play = function() return true end
}

-- generated-tests\GlobalAPI\test.lua:13
function inchesOfRain()
  return 0
end

-- generated-tests\GlobalAPI\test\only.lua:19
function inchesOfSnow()
  return 0
end

local luaLib = require("lualib_bundle")
CustomError = luaLib.__TS__Class()
CustomError.name = "CustomError"

Number = 'number'

require "generated-tests.all"