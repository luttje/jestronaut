local copy = require "jestronaut/utils/tables".copy

--- @class RunnerOptions
local RUNNER_DEFAULT_OPTIONS = {
    --- Stop running tests after this many tests have failed. `0` or `false` runs all tests, `true` is the same as `1`.
    --- @type number|boolean
    bail = 0,
    -- cache = true,
    -- changedFilesWithAncestor = true,
    -- changedSince = true,
    --- Use the plain reporter, which prints each test file once instead of redrawing the output. Defaults to true
    --- when the CI environment variable is set.
    --- @type boolean?
    ci = nil,
    -- clearCache = true,
    -- clearMocks = true,
    -- collectCoverageFrom = ".",
    --- Use colors in the output. Defaults to false when the NO_COLOR environment variable is set or TERM is "dumb".
    --- Without colors the plain reporter is used, since the default reporter needs ANSI codes to redraw its output.
    --- @type boolean?
    colors = nil,
    -- config = ".",
    -- coverage = true,
    -- coverageDirectory = ".",
    -- coverageProvider = "lua",
    -- debug = true,
    -- detectOpenHandles = true,
    -- env = "lua",
    -- errorOnDeprecated = true,
    --- Lets tests and hooks that take a done callback wait for asynchronous work. Without it, they must call done
    --- before returning. Set one of:
    --- - `tick`: a function that Jestronaut calls repeatedly while waiting, e.g. to run one iteration of your event
    ---   loop (`function() uv.run("once") end` with luv) or to update your timers.
    --- - `external = true`: for applications that run their own loop, like games. Call `jestronaut:tick()` regularly
    ---   (e.g. every frame) to continue the tests, and use the callback of `runTests` to get the results.
    --- Optionally also set `now`, a function returning the current time in seconds, used for timeouts. Defaults to
    --- os.clock, which measures CPU time.
    --- @type { tick?: fun(), external?: boolean, now?: fun(): number }?
    eventLoop = nil,
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
    --- Pass when there are no tests. Otherwise a run without tests fails, since that usually means the test files
    --- weren't loaded.
    --- @type boolean
    passWithNoTests = false,
    -- projects = "", --path1 ... pathN
    -- randomize = true,
    -- reporters = "",
    -- resetMocks = true,
    -- restoreMocks = true,
    --- The directories that contain the tests. Tests are recognized by being in a file in one of these.
    --- @type string[]
    roots = nil,
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
    --- How long tests and hooks that take a done callback may take to call it, in milliseconds. A single test can set
    --- its own timeout with the third argument of `it`/`test`, a hook with the second argument.
    --- @type number
    testTimeout = 5000,
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

--- @param name string
--- @return string?
local function getEnvironmentVariable(name)
    return os.getenv and os.getenv(name) or nil
end

--- Checks the CI environment variable, which most CI services (like GitHub Actions) set.
--- @return boolean
local function isRunningInCI()
    local ci = getEnvironmentVariable("CI")

    return ci ~= nil and ci ~= "" and ci ~= "false" and ci ~= "0"
end

--- Checks NO_COLOR (https://no-color.org) and TERM=dumb.
--- @return boolean
local function supportsColors()
    local noColor = getEnvironmentVariable("NO_COLOR")

    return (noColor == nil or noColor == "") and getEnvironmentVariable("TERM") ~= "dumb"
end

--- @param options RunnerOptions
--- @return RunnerOptions
local function merge(options)
    local mergedOptions = copy(RUNNER_DEFAULT_OPTIONS)

    for key, value in pairs(options) do
        mergedOptions[key] = value
    end

    mergedOptions.bail = normalizeBail(mergedOptions.bail)

    if mergedOptions.ci == nil then
        mergedOptions.ci = isRunningInCI()
    end

    if mergedOptions.colors == nil then
        mergedOptions.colors = supportsColors()
    end

    return mergedOptions
end

return {
    RUNNER_DEFAULT_OPTIONS = RUNNER_DEFAULT_OPTIONS,
    merge = merge
}
