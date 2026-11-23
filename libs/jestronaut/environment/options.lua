local copy = require "jestronaut/utils/tables".copy

--- @class RunnerOptions
local RUNNER_DEFAULT_OPTIONS = {
    --- Stop running tests after this many tests have failed. `0` or `false` runs all tests, `true` is the same as `1`.
    --- @type number|boolean
    bail = 0,
    -- cache = true,
    -- changedFilesWithAncestor = true,
    -- changedSince = true,
    -- ci = false,
    -- clearCache = true,
    -- clearMocks = true,
    -- collectCoverageFrom = ".",
    -- colors = true,
    -- config = ".",
    -- coverage = true,
    -- coverageDirectory = ".",
    -- coverageProvider = "lua",
    -- debug = true,
    -- detectOpenHandles = true,
    -- env = "lua",
    -- errorOnDeprecated = true,
    --- Exit the process with status code 1 when any test fails, so CI can detect failures.
    --- Only has effect where `os.exit` is available. Set to false when embedding Jestronaut in a host application.
    --- @type boolean
    exitOnFailure = true,
    -- expand = true,
    -- filter = "",
    -- findRelatedTests = "", --spaceSeparatedListOfSourceFiles
    -- forceExit = true,
    -- help = true, -- shows help
    -- ignoreProjects = "", --project1 ... projectN
    -- init = true, -- creates a jest config file
    -- injectGlobals = true,
    -- json = true,
    -- lastCommit = true,
    -- listTests = true,
    -- logHeapUsage = true,
    -- maxConcurrency = 1,
    -- maxWorkers = 1,
    -- noStackTrace = true,
    -- notify = true,
    -- onlyChanged = true,
    -- openHandlesTimeout = 1000,
    -- outputFile = "",
    -- passWithNoTests = true,
    -- projects = "", --path1 ... pathN
    -- randomize = true,
    -- reporters = "",
    -- resetMocks = true,
    -- restoreMocks = true,
    -- roots = "",
    -- runInBand = true,
    -- runTestsByPath = true,
    -- seed = 1324,
    -- selectProjects = "", --project1 ... projectN
    -- setupFilesAfterEnv = "", --path1 ... pathN
    -- shard = true,
    -- showConfig = true,
    -- showSeed = true,
    --- Hide what tests print. Printed output is captured per test either way, see `test.output`.
    --- @type boolean
    silent = false,
    -- testEnvironmentOptions = "",
    -- testLocationInResults = true,
    -- testMatch = "",
    --- Only run tests whose full name (surrounding describe names and the test name, joined by spaces) matches
    --- this Lua pattern. Other tests are reported as skipped.
    --- @type string?
    testNamePattern = nil,
    --- @type string[]
    testPathIgnorePatterns = nil,
    -- testPathPattern = "",
    -- testRunner = "",
    -- testSequencer = "",
    -- testTimeout = 5000,
    -- updateSnapshot = true,
    -- useStderr = true,
    -- verbose = true,
    -- version = true,
    -- watch = true,
    -- watchAll = true,
    -- watchman = true,
    -- workerThreads = true,
}

--- Turns the bail option into the number of failed tests after which to stop (0 means never stop).
--- Accepts booleans and numeric strings (as passed on the command line).
--- @param bail number|boolean|string|nil
--- @return number
local function normalizeBail(bail)
    if bail == nil or bail == false then
        return 0
    elseif bail == true then
        return 1
    end

    local count = tonumber(bail)

    if count == nil or count < 0 then
        error("Invalid bail option: " .. tostring(bail) .. ". Expected a non-negative number or a boolean.", 3)
    end

    return count
end

--- @param options RunnerOptions
--- @return RunnerOptions
local function merge(options)
    local mergedOptions = copy(RUNNER_DEFAULT_OPTIONS)

    for key, value in pairs(options) do
        mergedOptions[key] = value
    end

    mergedOptions.bail = normalizeBail(mergedOptions.bail)

    return mergedOptions
end

return {
    RUNNER_DEFAULT_OPTIONS = RUNNER_DEFAULT_OPTIONS,
    merge = merge
}
