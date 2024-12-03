local optionsLib = require "jestronaut/environment/options"
local describeLib = require "jestronaut/environment/describe"
local environmentLib = require "jestronaut/environment"
local coverageLib = require "jestronaut/coverage"
local expectLib = require "jestronaut/expect"
local mockLib = require "jestronaut/mock"
local setupModuleMocking = mockLib.setupModuleMocking

setupModuleMocking()

--- @class Jestronaut
local JESTRONAUT = {
    runnerOptions = {},
}

--- @param runnerOptions RunnerOptions
--- @return Jestronaut
function JESTRONAUT:configure(runnerOptions)
    environmentLib.resetEnvironment()

    -- Setup the root describe
    describeLib.describe("root", function() end)

    runnerOptions = optionsLib.merge(runnerOptions)

    self.runnerOptions = runnerOptions

    if not runnerOptions.roots then
        error(
        "No roots found in config. Provide at least one root that points to a directory where tests will be run from.")
    end

    environmentLib.setRoots(runnerOptions.roots)

    if runnerOptions.coverage == true then
        coverageLib.setupCoverage(runnerOptions.roots, runnerOptions.coverageDirectory, runnerOptions.coverageProvider)
    end

    return self
end

--- Registers the tests. This is done by calling the given function.
--- @param testRegistrar function
--- @return Jestronaut
function JESTRONAUT:registerTests(testRegistrar)
    if not self.runnerOptions then
        error(
        "No options found. You must setup jestronaut (with jestronaut:configure(options)) before registering tests.")
    end

    environmentLib.registerTests(testRegistrar)

    return self
end

--- Runs the tests.
--- @return Jestronaut
function JESTRONAUT:runTests()
    if not self.runnerOptions then
        error("No options found. You must setup jestronaut (with jestronaut:configure(options)) before running tests.")
    end

    environmentLib.runTests(self.runnerOptions)

    return self
end

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
