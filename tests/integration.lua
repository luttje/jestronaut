-- Integration checks for runner behaviour that can't be tested from inside a single test run, like the run
-- results, bail and test name filtering. Each check does a complete Jestronaut run over a fixture file in
-- tests/fixtures/ and inspects what happened.
--
-- Run from the root of the repository: `lua tests/integration.lua`
package.path = "./libs/?.lua;" .. package.path
require "jestronaut":withGlobals()

local failures = {}

--- A reporter that prints nothing and records which tests passed, failed or were skipped.
local function newRecordingReporter()
    local recorded = { passed = {}, failed = {}, skipped = {}, errors = {}, output = {} }
    local reporter = setmetatable({ recorded = recorded }, {
        __index = function()
            return function() end
        end,
    })

    function reporter:testFinished(describeOrTest, success, ...)
        if describeOrTest.isTest then
            table.insert(success and recorded.passed or recorded.failed, describeOrTest.name)

            if not success then
                recorded.errors[describeOrTest.name] = table.concat({ ... })
            end

            recorded.output[describeOrTest.name] = describeOrTest.output
        end
    end

    -- Record which tests will be skipped from the planned tree, since skipped describes are reported as a whole
    function reporter:startTestSet(rootDescribe)
        local function collect(describeOrTest)
            if describeOrTest.isTest and describeOrTest.toSkip then
                table.insert(recorded.skipped, describeOrTest.name)
            end

            for _, child in ipairs(describeOrTest.children or {}) do
                collect(child)
            end
        end

        collect(rootDescribe)
    end

    return reporter
end

--- Runs the given fixture file with the given options.
--- @param fixture string
--- @param options table
--- @return TestRunResults, table
local function run(fixture, options)
    local reporter = newRecordingReporter()
    local runResults

    options.roots = { "./tests/fixtures/" }
    options.reporter = reporter
    options.exitOnFailure = false

    jestronaut
        :configure(options)
        :registerTests(function()
            dofile("./tests/fixtures/" .. fixture .. ".lua")
        end)
        :runTests(function(results)
            runResults = results
        end)

    return runResults, reporter.recorded
end

local function check(description, actual, expected)
    if type(expected) == "table" then
        table.sort(actual)
        table.sort(expected)
        actual = table.concat(actual, ", ")
        expected = table.concat(expected, ", ")
    end

    if actual ~= expected then
        table.insert(failures,
            description .. "\n    expected: " .. tostring(expected) .. "\n    actual:   " .. tostring(actual))
    end
end

--- Like check, but compares lists in order.
local function checkSequence(description, actual, expected)
    actual = table.concat(actual or {}, "\n      ")
    expected = table.concat(expected, "\n      ")

    if actual ~= expected then
        table.insert(failures,
            description .. "\n    expected:\n      " .. expected .. "\n    actual:\n      " .. actual)
    end
end

-- Run results
do
    local results = run("bail", {})
    check("results.success is false when a test fails", results.success, false)
    check("results.failedCount counts failed tests", results.failedCount, 3)
    check("results.bailed is false without bail", results.bailed, false)

    results = run("names", {})
    check("results.success is true when all tests pass", results.success, true)
    check("results.failedCount is 0 when all tests pass", results.failedCount, 0)
end

-- Bail
do
    local results, recorded = run("bail", {})
    check("bail defaults to running all tests", #recorded.passed + #recorded.failed, 4)

    results, recorded = run("bail", { bail = false })
    check("bail = false runs all tests", #recorded.passed + #recorded.failed, 4)
    check("bail = false doesn't bail", results.bailed, false)

    results, recorded = run("bail", { bail = true })
    check("bail = true stops after the first failure", results.failedCount, 1)
    check("bail = true reports bailed", results.bailed, true)

    results, recorded = run("bail", { bail = 2 })
    check("bail = 2 stops after the second failure", results.failedCount, 2)
    check("bail = 2 ran up to the second failure", #recorded.passed + #recorded.failed, 2)

    results, recorded = run("bail", { bail = "3" })
    check("bail = '3' (as passed by the CLI) stops after the third failure", results.failedCount, 3)
    check("bail = '3' ran all tests up to the third failure", #recorded.passed + #recorded.failed, 4)
end

-- testNamePattern
do
    local _, recorded = run("names", { testNamePattern = "inner" })
    check("testNamePattern matches test names inside nested describes", recorded.passed,
        { "first inner test", "second inner test" })

    _, recorded = run("names", { testNamePattern = "^outer inner first" })
    check("testNamePattern matches the full name including describe names", recorded.passed, { "first inner test" })

    _, recorded = run("names", { testNamePattern = "^outer outer test$" })
    check("testNamePattern can select a single test in a describe", recorded.passed, { "outer test" })
    check("testNamePattern skips the tests that don't match", recorded.skipped,
        { "top-level test", "first inner test", "second inner test" })

    _, recorded = run("names", { testNamePattern = "^top%-level test$" })
    check("testNamePattern can select a top-level test", recorded.passed, { "top-level test" })

    _, recorded = run("names", { testNamePattern = "inner", testPathIgnorePatterns = { "/does-not-exist/" } })
    check("testNamePattern also works together with testPathIgnorePatterns", recorded.passed,
        { "first inner test", "second inner test" })
end

-- Hook order and scoping
do
    run("hooks", {})
    checkSequence("hooks run once per scope, in the same order as Jest", HOOK_LOG, {
        "file beforeAll",
        "file beforeEach", "top", "file afterEach",
        "outer beforeAll",
        "file beforeEach", "outer beforeEach 1", "outer beforeEach 2", "outer test", "outer afterEach",
        "file afterEach",
        "inner beforeAll",
        "file beforeEach", "outer beforeEach 1", "outer beforeEach 2", "inner beforeEach", "inner test",
        "inner afterEach", "outer afterEach", "file afterEach",
        "inner afterAll", "outer afterAll", "file afterAll",
    })

    run("wrapper", {})
    checkSequence("file level hooks only apply to tests in their own file, even when wrapped in a describe",
        WRAPPER_LOG, {
            "wrapper beforeEach", "wrapper test",
            "wrapper beforeEach", "wrapped file beforeEach", "wrapped test",
            "wrapper beforeEach", "wrapped file beforeEach", "deeply wrapped test",
        })
end

-- Failing hooks
do
    local results, recorded = run("hook-errors", {})
    check("a failing beforeAll fails all tests in its scope, a failing beforeEach or afterEach fails its test",
        recorded.failed, {
            "first test in failing beforeAll", "second test in failing beforeAll",
            "test with failing beforeEach", "test with failing afterEach",
        })
    check("tests without failing hooks still pass", recorded.passed, { "test without failing hooks" })
    check("results count tests failed by hooks", results.failedCount, 4)
    checkSequence("tests don't run when their beforeAll or beforeEach failed, afterEach still runs after beforeEach",
        HOOK_ERRORS_LOG, { "afterEach after failing beforeEach" })
end

-- Retries
do
    local _, recorded = run("retries", {})
    check("each test gets its own retries", recorded.passed, { "passes on the third attempt", "passes on the second attempt" })
    check("tests that keep failing fail after their retries", recorded.failed, { "always fails", "fails without retrying" })
    check("a test is attempted once plus the number of retries", RETRY_ATTEMPTS.always, 3)
    check("retryTimes in a describe overrides retryTimes for the file", RETRY_ATTEMPTS.noRetry, 1)
end

-- only
do
    local _, recorded = run("only", {})
    check("only runs the tests marked only (or in a describe marked only) in that file", recorded.passed,
        { "fails on incorrect modifier only to run", "runs because its describe is marked only" })
    check("only skips the other tests in that file", recorded.skipped,
        { "top-level test without only", "skips failing test", "not run" })
end

-- Stack tracebacks
do
    local _, recorded = run("traces", {})
    local direct = recorded.errors["fails directly"] or ""
    local helper = recorded.errors["fails in a helper"] or ""

    check("failures start with the location of the failing expect",
        direct:gsub("\\", "/"):match("^[^\n]*"), "./tests/fixtures/traces.lua:7: expect(received):toBe()")
    check("a traceback that only repeats the location is left out", direct:find("stack traceback", 1, true), nil)
    check("tracebacks show frames outside Jestronaut", helper:find("'assertTwo'", 1, true) ~= nil, true)

    for name, err in pairs(recorded.errors) do
        check(name .. ": tracebacks leave out frames inside Jestronaut", err:find("jestronaut/", 1, true), nil)
        check(name .. ": tracebacks leave out the runner", err:find("xpcall", 1, true), nil)
    end
end

-- Printed output
do
    local printBefore = print
    local _, recorded = run("output", {})

    checkSequence("print output of a test and its hooks is captured", recorded.output["prints"],
        { "from beforeEach", "hello\t42\tnil" })
    checkSequence("print output is captured for failing tests too", recorded.output["prints and fails"],
        { "from beforeEach", "before failing" })
    checkSequence("tests that print nothing get empty output", recorded.output["prints nothing"], { "from beforeEach" })
    check("print is restored after the run", print == printBefore, true)
end

--- Creates an event loop with timers and a fake clock that advances 10 ms on every tick, so waiting takes no real time.
local function newFakeEventLoop()
    local loop = { time = 0, timers = {} }

    function loop.now()
        return loop.time
    end

    function loop.setTimeout(milliseconds, callback)
        table.insert(loop.timers, { at = loop.time + milliseconds / 1000, callback = callback })
    end

    function loop.tick()
        loop.time = loop.time + 0.01

        local due = {}

        for i = #loop.timers, 1, -1 do
            if loop.timers[i].at <= loop.time then
                table.insert(due, 1, table.remove(loop.timers, i))
            end
        end

        for _, timer in ipairs(due) do
            timer.callback()
        end
    end

    return loop
end

-- Asynchronous tests (issue #12)
do
    local canCountParameters = require "jestronaut/environment/async".CAN_COUNT_PARAMETERS

    ASYNC_LOOP = newFakeEventLoop()
    local results, recorded = run("async", { eventLoop = { tick = ASYNC_LOOP.tick, now = ASYNC_LOOP.now } })

    local expectedPassed = {
        "calls done right away", "calls done later", "counts assertions made in callbacks",
        "can be expected to fail", "sees what an async beforeEach set up", "runs concurrent tests",
    }
    local expectedFailed = {
        "passes an error to done", "never calls done", "fails an expect in a callback", "calls done more than once",
    }

    if canCountParameters then
        table.insert(expectedPassed, "detects functions that take done")
    else
        table.insert(expectedFailed, "explains how to mark functions on Lua 5.1")
    end

    check("asynchronous tests pass once they call done", recorded.passed, expectedPassed)
    check("asynchronous tests fail on errors, timeouts and failing expects in callbacks", recorded.failed,
        expectedFailed)
    check("results count asynchronous tests", results.failedCount, #expectedFailed)

    local errors = recorded.errors

    check("an error passed to done is the failure message",
        (errors["passes an error to done"] or ""):find("something went wrong", 1, true) ~= nil, true)
    check("a test that doesn't call done times out after its timeout",
        (errors["never calls done"] or ""):find("Test timed out after 100 ms", 1, true) ~= nil, true)
    check("a failing expect in a callback fails the test with its message",
        (errors["fails an expect in a callback"] or ""):find("Expected: 2", 1, true) ~= nil, true)
    check("calling done twice fails the test",
        (errors["calls done more than once"] or ""):find("called done more than once", 1, true) ~= nil, true)

    if not canCountParameters then
        check("on Lua 5.1 calling done in an unmarked function explains jestronaut:async",
            (errors["explains how to mark functions on Lua 5.1"] or ""):find("jestronaut:async", 1, true) ~= nil, true)
    end

    ASYNC_LOOP = newFakeEventLoop()
    _, recorded = run("async", {})

    check("without an event loop, tests that call done right away pass",
        recorded.passed[1] == "calls done right away" or recorded.passed[2] == "calls done right away", true)
    check("without an event loop, tests that wait for done fail and say why",
        (recorded.errors["calls done later"] or ""):find("no event loop is configured", 1, true) ~= nil, true)
end

-- Asynchronous tests in an application that runs its own loop
do
    local hostOutput = {}
    local printBefore = print

    print = function(...)
        table.insert(hostOutput, table.concat({ ... }, "\t"))
    end

    ASYNC_LOOP = newFakeEventLoop()

    local reporter = newRecordingReporter()
    local runResults
    local tickCount = 0

    jestronaut
        :configure({
            roots = { "./tests/fixtures/" },
            reporter = reporter,
            exitOnFailure = false,
            eventLoop = { external = true, now = ASYNC_LOOP.now },
        })
        :registerTests(function()
            dofile("./tests/fixtures/async-external.lua")
        end)
        :runTests(function(results)
            runResults = results
        end)

    check("runTests returns before tests that wait for the host have finished", runResults, nil)

    while not jestronaut:tick() and tickCount < 1000 do
        print("from the host")
        ASYNC_LOOP.tick()
        tickCount = tickCount + 1
    end

    print = printBefore

    local recorded = reporter.recorded

    check("the run finishes once the host has called tick enough", runResults ~= nil, true)
    check("tests continue when the host calls tick", recorded.passed,
        { "waits for the host to call tick", "runs after the asynchronous tests" })
    check("tests time out while the host calls tick", recorded.failed, { "times out while the host calls tick" })
    checkSequence("output printed by the host while a test waits isn't captured for the test",
        recorded.output["waits for the host to call tick"], { "from the test" })
    check("output printed by the host while a test waits is printed normally", hostOutput[1], "from the host")
end

-- Command line arguments
do
    local cli = require "jestronaut/cli"
    local options, paths = cli.parseArguments({
        "--bail", "--no-colors", "--roots=./a", "--roots=./b", "--testTimeout=100", "--testNamePattern=x", "tests/",
    })

    check("--option without a value is true", options.bail, true)
    check("--no-option is false", options.colors, false)
    check("repeated list options are collected", options.roots, { "./a", "./b" })
    check("number options are numbers", options.testTimeout, 100)
    check("--option=value is the value", options.testNamePattern, "x")
    check("arguments that aren't options are paths", paths, { "tests/" })
end

-- Finding test files and running them from the command line
do
    local hasFileSystem = pcall(require, "lfs") or pcall(require, "luv")

    if not hasFileSystem then
        print("Skipping the checks for finding test files, because LuaFileSystem isn't installed.")
    else
        local cli = require "jestronaut/cli"

        local function runCli(args)
            local reporter = newRecordingReporter()
            local exitCode = cli.run(args, { reporter = reporter })

            return exitCode, reporter.recorded
        end

        local exitCode, recorded = runCli({ "--roots=./tests/fixtures/discovery" })
        check("test files are found by name, skipping other files, hidden directories and lua_modules",
            recorded.passed, { "math adds", "strings concatenate", "deep test" })
        check("the exit code is 0 when all tests pass", exitCode, 0)

        _, recorded = runCli({ "./tests/fixtures/discovery/math_test.lua" })
        check("test files given as paths run on their own", recorded.passed, { "math adds" })

        _, recorded = runCli({ "./tests/fixtures/discovery/nested" })
        check("directories given as paths are searched for test files", recorded.passed, { "deep test" })

        _, recorded = runCli({ "--roots=./tests/fixtures/discovery", "nested" })
        check("other paths only run test files whose path contains them", recorded.passed, { "deep test" })

        _, recorded = runCli({ "--roots=./tests/fixtures/discovery", "--testMatch=helper.lua" })
        check("testMatch changes which files are test files", recorded.passed, { "helper test" })

        exitCode, recorded = runCli({ "--roots=./tests/fixtures/discovery-broken" })
        check("test files that fail to load are reported as a failing test", recorded.failed,
            { "Test suite failed to run" })
        check("other test files still run when one fails to load", recorded.passed, { "works" })
        check("the exit code is 1 when a test fails", exitCode, 1)

        exitCode = runCli({ "--roots=./tests/fixtures/discovery-empty" })
        check("finding no tests fails", exitCode, 1)

        exitCode = runCli({ "--roots=./tests/fixtures/discovery-empty", "--passWithNoTests" })
        check("finding no tests passes with passWithNoTests", exitCode, 0)
    end
end

-- Counts (issue #10)
do
    local expectedCounts = { totalCount = 8, passedCount = 4, failedCount = 1, skippedCount = 2, todoCount = 1 }

    for _, fixture in ipairs({ "counts", "counts-wrapped" }) do
        local results = run(fixture, {})

        for key, expected in pairs(expectedCounts) do
            check(fixture .. ": results." .. key .. " counts tests at any depth", results[key], expected)
        end
    end
end

if #failures > 0 then
    print(#failures .. " integration check(s) failed:\n")

    for _, failure in ipairs(failures) do
        print("  ✗ " .. failure .. "\n")
    end

    os.exit(1)
end

print("All integration checks passed.")
