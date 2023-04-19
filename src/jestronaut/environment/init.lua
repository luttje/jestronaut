local makeIndexableFunction = require "jestronaut.utils.metatables".makeIndexableFunction
local describeLib = require "jestronaut.environment.describe"
local stateLib = require "jestronaut.environment.state"
local testLib = require "jestronaut.environment.test"
local eachLib = require "jestronaut.each"

local fileTestTimeouts = {}

-- Setup the root describe
describeLib.describe("root", function() end)

-- Set the default timeout interval (in milliseconds) for all tests and before/after hooks in the test file. This only affects the test file from which this function is called. The default timeout interval is 5 seconds if this method is not called.
local function setTimeout(timeout)
  local file = debug.getinfo(2, "S").source:sub(2)
  fileTestTimeouts[file] = timeout
end

--- Exposes the environment functions to the global environment.
--- @param targetEnvironment table
local function exposeTo(targetEnvironment)
  targetEnvironment.afterAll = stateLib.afterAll
  targetEnvironment.afterEach = stateLib.afterEach

  targetEnvironment.beforeAll = stateLib.beforeAll
  targetEnvironment.beforeEach = stateLib.beforeEach

  targetEnvironment.describe = makeIndexableFunction(function(blockName, blockFn) return describeLib.describe(blockName, blockFn) end)

  targetEnvironment.describe.only = makeIndexableFunction(function(mainDescribe, blockName, blockFn) return describeLib.describeOnly(mainDescribe, blockName, blockFn) end)
  targetEnvironment.describe.skip = makeIndexableFunction(function(mainDescribe, blockName, blockFn) return describeLib.describeSkip(mainDescribe, blockName, blockFn) end)

  eachLib.bindTo(targetEnvironment.describe)
  eachLib.bindTo(targetEnvironment.describe.only, targetEnvironment.describe)
  eachLib.bindTo(targetEnvironment.describe.skip, targetEnvironment.describe)

  -- Refactored so both test and it can be used
  local aliases = {'test', 'it'}

  for _, alias in ipairs(aliases) do
    targetEnvironment[alias] = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.test(blockName, blockFn, timeout) end)
    targetEnvironment[alias].concurrent = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testConcurrent(blockName, blockFn, timeout) end)
    targetEnvironment[alias].concurrent.only = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testConcurrentOnly(blockName, blockFn, timeout) end)
    targetEnvironment[alias].concurrent.skip = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testConcurrentSkip(blockName, blockFn, timeout) end)
    targetEnvironment[alias].failing = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testFailing(blockName, blockFn, timeout) end)
    targetEnvironment[alias].failing.only = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testFailingOnly(blockName, blockFn, timeout) end)
    targetEnvironment[alias].failing.skip = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testFailingSkip(blockName, blockFn, timeout) end)
    targetEnvironment[alias].only = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testOnly(blockName, blockFn, timeout) end)
    targetEnvironment[alias].skip = makeIndexableFunction(function(blockName, blockFn, timeout) return testLib.testSkip(blockName, blockFn, timeout) end)
    targetEnvironment[alias].todo = function(blockName) return testLib.testTodo(blockName) end

    eachLib.bindTo(targetEnvironment[alias])
    eachLib.bindTo(targetEnvironment[alias].concurrent, targetEnvironment[alias])
    eachLib.bindTo(targetEnvironment[alias].concurrent.only, targetEnvironment[alias])
    eachLib.bindTo(targetEnvironment[alias].concurrent.skip, targetEnvironment[alias])
    eachLib.bindTo(targetEnvironment[alias].failing, targetEnvironment[alias])
    eachLib.bindTo(targetEnvironment[alias].failing.only, targetEnvironment[alias])
    eachLib.bindTo(targetEnvironment[alias].failing.skip, targetEnvironment[alias])
    eachLib.bindTo(targetEnvironment[alias].only, targetEnvironment[alias])
    eachLib.bindTo(targetEnvironment[alias].skip, targetEnvironment[alias])
  end
end

return {
  setTimeout = setTimeout,
  exposeTo = exposeTo,

  retryTimes = stateLib.retryTimes,
  setTestRoot = stateLib.setTestRoot,
}