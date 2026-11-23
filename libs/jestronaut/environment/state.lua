local unpack = table.unpack or unpack

local callRespectingRequireOverride = require "jestronaut/utils/require".callRespectingRequireOverride
local extendMetaTableIndex = require "jestronaut/utils/metatables".extendMetaTableIndex
local asyncLib = require "jestronaut/environment/async"
local stringsLib = require "jestronaut/utils/strings"
local formatLib = require "jestronaut/utils/format"

local rootFilePaths

--- The test that is currently running. Nil while tests are being registered.
--- @type DescribeOrTest?
local currentDescribeOrTest = nil

--- The describe that tests, describes and hooks are currently being registered in.
--- @type DescribeOrTest?
local currentParent = nil

--- Number of tests that failed so far during the current run, used to decide when to bail.
local totalFailedTestCount = 0

--- Errors of beforeAll hooks that failed during the current run, by hook entry.
local failedBeforeAllHooks = {}

--- The options of the current run.
--- @type RunnerOptions?
local activeRunnerOptions = nil

--- The run that is waiting for the host to call tick, when the eventLoop option has `external` set.
local activeRun = nil

--- True while the runner's coroutine is yielded to wait for the host.
local isWaitingForHost = false

--- The print functions to switch between while a test runs: `capture` stores output for the test, `previous` is the
--- print from before the test.
local activePrintCapture = nil

--- Thrown (and caught by runTests) to stop the run when the bail threshold is reached.
local BAIL_SIGNAL_META = {
    __tostring = function(self)
        return self.message
    end,
}

local HOOK_KINDS = { "beforeAll", "beforeEach", "afterAll", "afterEach" }

local function getCurrentDescribeOrTest()
    return currentDescribeOrTest
end

local function resetEnvironment()
    currentDescribeOrTest = nil
    rootFilePaths = nil
    currentParent = nil
end

--- Sets where Jestronaut should look for tests. This is used to determine the test file path.
--- @param roots string[]
local function setRoots(roots)
    for i, root in ipairs(roots) do
        roots[i] = stringsLib.normalizePath(root)
    end

    rootFilePaths = roots
end

--- Path parts that only occur in paths of Jestronaut's own files, however its modules were loaded. Garry's Mod for
--- example loads them with include, so they don't appear in package.loaded.
local LIBRARY_PATH_PARTS = {
    "/jestronaut.lua",
    "/jestronaut/environment/", "/jestronaut/expect/", "/jestronaut/mock/", "/jestronaut/utils/",
    "/jestronaut/cli.lua", "/jestronaut/coverage.lua", "/jestronaut/discovery.lua", "/jestronaut/each.lua",
    "/jestronaut/environment.lua", "/jestronaut/expect.lua", "/jestronaut/faketimers.lua", "/jestronaut/mock.lua",
    "/jestronaut/plainreporter.lua", "/jestronaut/reporter.lua",
}

--- Gets the path parts that identify Jestronaut's own files: those of LIBRARY_PATH_PARTS, and the path endings of
--- all loaded Jestronaut modules, like "/jestronaut/utils/functions.lua".
--- @return string[]
local function getLibraryPathSuffixes()
    local suffixes = {}

    for _, part in ipairs(LIBRARY_PATH_PARTS) do
        table.insert(suffixes, part)
    end

    for moduleName in pairs(package.loaded) do
        if type(moduleName) == "string" and (moduleName == "jestronaut" or moduleName:sub(1, 11) == "jestronaut/") then
            table.insert(suffixes, "/" .. moduleName .. ".lua")
            table.insert(suffixes, "/" .. moduleName .. "/init.lua")
        end
    end

    return suffixes
end

--- Checks whether a path (or a line of a stack traceback) points into Jestronaut's own files.
--- @param path string
--- @param libraryPathSuffixes? string[]
--- @return boolean
local function isLibraryPath(path, libraryPathSuffixes)
    -- Start the path with a slash, so relative paths like "jestronaut/utils/functions.lua" match too
    path = "/" .. path:gsub("\\", "/"):gsub("^%s+", "")

    for _, suffix in ipairs(libraryPathSuffixes or getLibraryPathSuffixes()) do
        if path:find(suffix, 1, true) then
            return true
        end
    end

    return false
end

--- Gets the file path and line number of the test: the first frame in the stack trace that is inside one of the roots,
--- skipping Jestronaut's own files (which can be inside a root too, e.g. in a project's lua_modules).
--- @return string, number
local function getTestFilePath()
    local filePath, lineNumber
    local libraryPathSuffixes = getLibraryPathSuffixes()
    local i = 1

    while true do
        local info = debug.getinfo(i, "Sl")

        if (not info) then
            error(
            "Could not find the test file path. Please make sure options.roots is set to the directories where your tests are located.")
            break
        end

        local path = stringsLib.normalizePath(info.source:sub(1, 1) == "@" and info.source:sub(2) or info.source)

        if rootFilePaths ~= nil and isLibraryPath(path, libraryPathSuffixes) then
            -- Jestronaut's own files are never test files
        elseif rootFilePaths ~= nil then
            local found = false

            -- Check if the file path contains the root file path. If it does, then we've found the test
            for _, rootFilePath in ipairs(rootFilePaths) do
                if path:sub(1, rootFilePath:len()) == rootFilePath then
                    filePath = path
                    lineNumber = info.currentline
                    found = true
                    break
                end
            end

            if found then
                break
            end
        else
            filePath = path
            lineNumber = info.currentline
            break
        end

        i = i + 1
    end

    return filePath, lineNumber
end

--- Checks whether a line of a stack traceback is a frame inside Jestronaut itself or a C function.
--- @param line string
--- @param libraryPathSuffixes string[]
--- @return boolean
local function isLibraryFrame(line, libraryPathSuffixes)
    if line:find("^%s*%[C%]") or line:find("tail call", 1, true) then
        return true
    end

    return isLibraryPath(line, libraryPathSuffixes)
end

--- Removes frames from the stack traceback that are inside Jestronaut, or that called the test (everything from the
--- runner's xpcall onwards). The traceback is left out completely when it would only repeat the location that
--- already starts the error message.
--- @param traceback string
--- @return string
local function trimTraceback(traceback)
    local message, frames = traceback:match("^(.-)\nstack traceback:\n(.*)$")

    if not message then
        return traceback
    end

    local libraryPathSuffixes = getLibraryPathSuffixes()
    local kept = {}

    for line in (frames .. "\n"):gmatch("(.-)\n") do
        if line:find("in function 'xpcall'", 1, true) then
            break
        end

        if not isLibraryFrame(line, libraryPathSuffixes) then
            table.insert(kept, line)
        end
    end

    local hasLocation = message:find("^[^\n]-:%d+:") ~= nil

    if #kept == 0 or (#kept == 1 and hasLocation) then
        return message
    end

    return message .. "\nstack traceback:\n" .. table.concat(kept, "\n")
end

--- Error handler for xpcall that adds a stack trace to the error.
--- @param err any
--- @return string
local function traceErrorHandler(err)
    -- debug.traceback returns non-string errors (e.g. error({ code = 1 })) untouched, which reporters can't print
    if type(err) ~= "string" then
        err = "(error object is a " .. type(err) .. " value: " .. tostring(err) .. ")"
    end

    return trimTraceback(debug.traceback(err, 2))
end

--[[
    Scopes

    Hooks (beforeAll, beforeEach, afterAll, afterEach) and retry settings belong to the describe they are registered
    in. When registered at the top of a test file, they belong to whatever describe that file was required in (usually
    the root describe). Like in Jest, such file level registrations only apply to tests in that same file. Otherwise
    wrapping `require` calls in a describe would let the hooks of one file leak into the tests of others.
--]]

--- Gets the describe that hooks and settings registered right now belong to, and the file they are registered from.
--- @param kind string The name of the function being called, for error messages.
--- @return DescribeOrTest, string
local function getRegistrationScope(kind)
    if currentDescribeOrTest then
        error(kind .. " cannot be called inside a test. Call it at the top of a test file or inside a describe block.", 4)
    end

    if not currentParent then
        error(kind .. " must be called while registering tests (in the function passed to jestronaut:registerTests).", 4)
    end

    local filePath = getTestFilePath()

    return currentParent, filePath
end

--- Creates an entry that remembers where something was registered, so we can check which tests it applies to.
--- @param kind string
--- @return table
local function newScopedEntry(kind)
    local scope, filePath = getRegistrationScope(kind)

    return {
        kind = kind,
        scope = scope,
        filePath = filePath,
        isFileScoped = filePath ~= scope.filePath,
    }, scope
end

--- Checks whether the given describe is an ancestor of the given (registered, not copied for run) test.
--- @param describe DescribeOrTest
--- @param test DescribeOrTest
--- @return boolean
local function isAncestor(describe, test)
    local parent = test.parent

    while parent do
        if parent == describe then
            return true
        end

        parent = parent.parent
    end

    return false
end

--- Checks whether a scoped entry (hook or retry setting) applies to the given (registered) test.
--- @param entry table
--- @param test DescribeOrTest
--- @return boolean
local function appliesTo(entry, test)
    if entry.isFileScoped and entry.filePath ~= test.filePath then
        return false
    end

    return isAncestor(entry.scope, test)
end

--- Registers a hook in the current scope.
--- @param kind string
--- @param fn function|table A function, or one wrapped with jestronaut:async.
--- @param timeout? number How long to wait for done to be called, in milliseconds.
local function registerHook(kind, fn, timeout)
    if type(fn) ~= "function" and not asyncLib.isMarkedAsync(fn) then
        error(kind .. " expects a function, got " .. type(fn), 3)
    end

    local entry, scope = newScopedEntry(kind)
    entry.fn = fn
    entry.timeout = timeout

    if not rawget(scope, "hooks") then
        scope.hooks = { beforeAll = {}, beforeEach = {}, afterAll = {}, afterEach = {} }
    end

    table.insert(scope.hooks[kind], entry)
end

local function afterAll(fn, timeout)
    registerHook("afterAll", fn, timeout)
end

local function afterEach(fn, timeout)
    registerHook("afterEach", fn, timeout)
end

local function beforeAll(fn, timeout)
    registerHook("beforeAll", fn, timeout)
end

local function beforeEach(fn, timeout)
    registerHook("beforeEach", fn, timeout)
end

--- Sets how many times failing tests in the current scope (file or describe) are retried.
--- Settings in a describe take precedence over those of surrounding describes and the file.
--- @param numRetries number
--- @param options? { logErrorsBeforeRetry?: boolean }
local function retryTimes(numRetries, options)
    if type(numRetries) ~= "number" or numRetries < 0 then
        error("retryTimes expects a non-negative number of retries, got " .. tostring(numRetries), 3)
    end

    local entry, scope = newScopedEntry("retryTimes")
    entry.times = numRetries
    entry.options = options or {}

    if not rawget(scope, "retrySettings") then
        scope.retrySettings = {}
    end

    table.insert(scope.retrySettings, entry)
end

--- Finds the retry settings of the nearest scope that applies to the given (registered) test.
--- @param test DescribeOrTest
--- @return table?
local function findRetrySettings(test)
    local parent = test.parent

    while parent do
        local found

        for _, entry in ipairs(rawget(parent, "retrySettings") or {}) do
            if appliesTo(entry, test) then
                found = entry -- The last registered setting in a scope wins
            end
        end

        if found then
            return found
        end

        parent = parent.parent
    end
end

local function incrementAssertionCount()
    if not currentDescribeOrTest then
        error("Cannot increase the assertion count outside of a test or describe block", 2)
    end

    currentDescribeOrTest.assertionCount = currentDescribeOrTest.assertionCount + 1
end

local function getAssertionCount()
    if not currentDescribeOrTest then
        error("Cannot get the assertion count outside of a test or describe block", 2)
    end

    return currentDescribeOrTest.assertionCount
end

local function setExpectAssertion()
    if not currentDescribeOrTest then
        error("Cannot set the expect assertion outside of a test or describe block", 2)
    end

    currentDescribeOrTest.expectAssertion = true
end

local function getExpectedAssertionCount()
    if not currentDescribeOrTest then
        error("Cannot get the expected assertion count outside of a test or describe block", 2)
    end

    return currentDescribeOrTest.expectedAssertionCount
end

local function setExpectedAssertionCount(count)
    if not currentDescribeOrTest then
        error("Cannot set the expected assertion count outside of a test or describe block", 2)
    end

    currentDescribeOrTest.expectedAssertionCount = count
end

--- @class DescribeOrTest
local DESCRIBE_OR_TEST_META = {
    indentationLevel = 0,
    name = "",
    fn = function() end,
    isOnlyToRun = false,
    toSkip = false,

    assertionCount = 0,
    parent = nil,
    childCount = 0,
    grandChildrenCount = 0,

    --- @type DescribeOrTest[]
    children = nil
}

DESCRIBE_OR_TEST_META.__index = DESCRIBE_OR_TEST_META

--- Adds a child describe or test.
--- @param child DescribeOrTest
function DESCRIBE_OR_TEST_META:addChild(child)
    self.childCount = self.childCount + 1

    self.children[self.childCount] = child
    self.childrenLookup[child.name] = self.childCount

    child.parent = self

    if self.parent then
        self.parent.grandChildrenCount = self.parent.grandChildrenCount + 1
    end
end

--- Sets print to the function that captures the output of the running test, or back to what it was.
--- @param isCapturing boolean
local function setPrintCapture(isCapturing)
    if activePrintCapture then
        print = isCapturing and activePrintCapture.capture or activePrintCapture.previous
    end
end

--- Waits until `isDone` returns true, using the event loop from the runner options:
--- - with `eventLoop.tick`, tick is called repeatedly. Errors raised by it (e.g. by a failing expect in a callback)
---   end the wait with that error.
--- - with `eventLoop.external`, the runner's coroutine yields until the host calls jestronaut:tick() again.
--- Returns false and an error message when the timeout passes first, or when no event loop is configured.
--- @param isDone fun(): boolean
--- @param timeout number In milliseconds.
--- @param description string What is being waited for, e.g. "Test", for error messages.
--- @return boolean, string?
local function waitUntil(isDone, timeout, description)
    if isDone() then
        return true
    end

    local eventLoop = activeRunnerOptions and activeRunnerOptions.eventLoop

    if type(eventLoop) ~= "table" or not (eventLoop.tick or eventLoop.external) then
        return false, description .. " didn't call done before returning, and no event loop is configured to wait " ..
            "for it. Set the eventLoop option to let Jestronaut wait."
    end

    local now = eventLoop.now or os.clock
    local deadline = now() + timeout / 1000

    while not isDone() do
        if now() >= deadline then
            return false, description .. " timed out after " .. timeout .. " ms while waiting for done to be called"
        end

        if eventLoop.tick then
            local success, err = xpcall(eventLoop.tick, traceErrorHandler)

            if not success then
                return false, err
            end
        else
            setPrintCapture(false)
            isWaitingForHost = true
            coroutine.yield()
            isWaitingForHost = false
            setPrintCapture(true)
        end
    end

    return true
end

--- Formats the value a test or hook passed to done.
--- @param err any
--- @return string
local function formatDoneError(err)
    if type(err) == "string" then
        return err
    elseif type(err) == "table" and err.message ~= nil then
        return tostring(err.message)
    end

    return "done was called with " .. formatLib.format(err)
end

--- Calls a test or hook function. When it takes a done callback (see jestronaut/environment/async), waits for done
--- to be called, failing when it isn't within the timeout or when it receives an error.
--- @param fnOrAsync function|table
--- @param timeout number In milliseconds.
--- @param description string e.g. "Test" or "beforeEach hook", for error messages.
--- @return boolean, string?
local function callFunction(fnOrAsync, timeout, description)
    local fn, isAsync = asyncLib.getFunction(fnOrAsync)

    if not isAsync then
        if asyncLib.CAN_COUNT_PARAMETERS then
            return xpcall(fn, traceErrorHandler)
        end

        return xpcall(function()
            fn(asyncLib.doneOnLua51)
        end, traceErrorHandler)
    end

    local doneCallCount = 0
    local doneError

    local function done(err)
        doneCallCount = doneCallCount + 1

        if doneCallCount == 1 then
            doneError = err
        end
    end

    local success, err = xpcall(function()
        fn(done)
    end, traceErrorHandler)

    if not success then
        return false, err
    end

    local isFinished, waitError = waitUntil(function()
        return doneCallCount > 0
    end, timeout, description)

    if not isFinished then
        return false, waitError
    elseif doneError ~= nil then
        return false, formatDoneError(doneError)
    elseif doneCallCount > 1 then
        return false, description .. " called done more than once"
    end

    return true
end

--- Runs a single hook, returning false and an error message if it failed.
--- @param entry table
--- @return boolean, string?
local function runHook(entry)
    local timeout = entry.timeout or activeRunnerOptions.testTimeout
    local success, err = callFunction(entry.fn, timeout, entry.kind .. " hook")

    if not success then
        return false, entry.kind .. " hook failed: " .. tostring(err)
    end

    return true
end

--- Runs one attempt of a test: its beforeEach hooks, the test itself and its afterEach hooks.
--- Returns whether the attempt succeeded and the errors if it didn't.
--- @return boolean, table
function DESCRIBE_OR_TEST_META:runAttempt()
    currentDescribeOrTest = self

    self.assertionCount = 0
    self.expectedAssertionCount = nil
    self.expectAssertion = nil

    local success, errors = true, {}

    local function addError(err)
        if success then
            success = false
            errors = { err }
        else
            table.insert(errors, "\n" .. tostring(err))
        end
    end

    -- When a beforeAll hook for this test failed, the test fails without running
    for _, entry in ipairs(self.beforeAllHooks) do
        if failedBeforeAllHooks[entry] then
            addError(failedBeforeAllHooks[entry])
            break
        end
    end

    local beforeAllFailed = not success

    if success then
        for _, entry in ipairs(self.beforeEachHooks) do
            local hookSuccess, err = runHook(entry)

            if not hookSuccess then
                addError(err)
                break
            end
        end
    end

    if success then
        local timeout = rawget(self, "timeout") or activeRunnerOptions.testTimeout
        local testSuccess, err = callFunction(self.fn, timeout, "Test")

        if not testSuccess then
            success = false
            errors = { err }
        end
    end

    -- Like Jest, afterEach hooks also run when the test or a beforeEach hook failed
    if not beforeAllFailed then
        for _, entry in ipairs(self.afterEachHooks) do
            local hookSuccess, err = runHook(entry)

            if not hookSuccess then
                addError(err)
            end
        end
    end

    if success then
        if self.expectedAssertionCount ~= nil and self.expectedAssertionCount ~= self.assertionCount then
            addError("Expected " .. self.expectedAssertionCount .. " assertions, but " .. self.assertionCount ..
                " were run")
        elseif self.expectAssertion and self.assertionCount == 0 then
            addError("Expected at least one assertion to be run, but none were run")
        end
    end

    if self.expectFail == true then
        if success then
            success = false
            errors = { "Error! Expected test to fail, but it succeeded." }
        else
            success = true
            errors = {}
        end
    end

    currentDescribeOrTest = nil

    return success, errors
end

--- Runs the test, including retries and the beforeAll and afterAll hooks that start or end at this test.
--- Returns the amount of failed tests (0 or 1).
--- @param reporter Reporter
--- @param runnerOptions RunnerOptions
--- @return number
function DESCRIBE_OR_TEST_META:runTest(reporter, runnerOptions)
    currentDescribeOrTest = self

    -- Capture what the test and its hooks print, so reporters can show it without it interfering with their output
    local output = {}

    activePrintCapture = {
        previous = print,
        capture = function(...)
            local parts = {}

            for i = 1, select("#", ...) do
                parts[i] = tostring((select(i, ...)))
            end

            table.insert(output, table.concat(parts, "\t"))
        end,
    }

    setPrintCapture(true)

    for _, entry in ipairs(self.beforeAllHooksToRun) do
        local success, err = runHook(entry)

        if not success then
            failedBeforeAllHooks[entry] = err
        end
    end

    local retrySettings = self.retrySettings
    local retriesRemaining = retrySettings and retrySettings.times or 0
    local success, errors

    while true do
        success, errors = self:runAttempt()

        if success or retriesRemaining <= 0 then
            break
        end

        retriesRemaining = retriesRemaining - 1

        if retrySettings.options.logErrorsBeforeRetry then
            reporter:testFinished(self, false, unpack(errors))
        end

        reporter:testRetrying(self, retriesRemaining + 1)
    end

    currentDescribeOrTest = self

    for _, entry in ipairs(self.afterAllHooksToRun) do
        local hookSuccess, err = runHook(entry)

        if not hookSuccess then
            if success then
                success = false
                errors = { err }
            else
                table.insert(errors, "\n" .. tostring(err))
            end
        end
    end

    currentDescribeOrTest = nil
    setPrintCapture(false)
    activePrintCapture = nil

    self.output = output
    self.success = success
    self.isRunning = false
    self.hasRun = true
    self.errors = (not success) and errors or nil

    reporter:testFinished(self, success, unpack(errors))

    if success then
        return 0
    end

    totalFailedTestCount = totalFailedTestCount + 1

    if runnerOptions.bail > 0 and totalFailedTestCount >= runnerOptions.bail then
        error(setmetatable({
            message = "Bail after " .. totalFailedTestCount .. " failed " ..
                (totalFailedTestCount == 1 and "test" or "tests") .. " with error: \n" .. tostring(errors[1]),
        }, BAIL_SIGNAL_META))
    end

    return 1
end

--- Runs the describe or test and returns the amount of failed tests.
--- @param reporter Reporter
--- @param runnerOptions RunnerOptions
--- @return number
function DESCRIBE_OR_TEST_META:run(reporter, runnerOptions)
    if self.toSkip then
        reporter:testSkipped(self)

        return 0
    end

    if (runnerOptions.slowDown) then -- For debugging terminal output
        local endTime = os.clock() + runnerOptions.slowDown * 0.001

        -- Start a loop to freeze for the specified amount of milliseconds
        while os.clock() < endTime do end
    end

    reporter:testStarting(self)
    self.isRunning = true

    if self.isTest then
        return self:runTest(reporter, runnerOptions)
    end

    local failedTestCount = 0

    for _, child in ipairs(self.children) do
        failedTestCount = failedTestCount + child:run(reporter, runnerOptions)
    end

    self.isRunning = false
    self.hasRun = true
    self.success = failedTestCount == 0

    reporter:testFinished(self, self.success)

    return failedTestCount
end

--- @class DescribeOrTestForRun : DescribeOrTest
--- @field registered DescribeOrTest The describe or test as it was registered.
local DESCRIBE_OR_TEST_FOR_RUN_META = {
    isDescribeOrTestForRun = true,
}

extendMetaTableIndex(DESCRIBE_OR_TEST_FOR_RUN_META, DESCRIBE_OR_TEST_META)

function DESCRIBE_OR_TEST_FOR_RUN_META:addChild(describeOrTest)
    self.children[#self.children + 1] = describeOrTest
end

--- @class FileForRun
local FILE_FOR_RUN = {
    isFileForRun = true,

    filePath = "",

    --- @type DescribeOrTestForRun[]
    describesOrTests = nil,

    hasRun = false,
    success = false,
    isRunning = false,
    isSkipped = false,
    skippedCount = 0,
    failedCount = 0,
}

FILE_FOR_RUN.__index = FILE_FOR_RUN

--- Gets the name of a (registered) describe or test prefixed with the names of its parent describes, separated by
--- spaces. The root describe (which has no parent) is left out.
--- @param describeOrTest DescribeOrTest
--- @return string
local function getFullName(describeOrTest)
    local names = { describeOrTest.name }
    local parent = describeOrTest.parent

    while parent and parent.parent do
        table.insert(names, 1, parent.name)
        parent = parent.parent
    end

    return table.concat(names, " ")
end

--- Checks whether the (registered) describe or test, or any describe around it, has the given field set.
--- @param describeOrTest DescribeOrTest
--- @param field string
--- @return boolean
local function hasFlagInSelfOrAncestors(describeOrTest, field)
    local current = describeOrTest

    while current do
        if current[field] then
            return true
        end

        current = current.parent
    end

    return false
end

--- Checks whether the file path matches any of the patterns. Patterns that start and end with a slash are treated
--- as Lua patterns, all others are matched as plain text.
--- @param filePath string
--- @param patterns string[]?
--- @return boolean
local function isPathIgnored(filePath, patterns)
    for _, pattern in ipairs(patterns or {}) do
        local plain = not pattern:find("^/.*/$")
        pattern = plain and pattern or pattern:sub(2, -2)

        if filePath:find(pattern, nil, plain) then
            return true
        end
    end

    return false
end

--- Creates a copy of the registered tree for running, so run state doesn't end up in the registrations.
--- @param describeOrTest DescribeOrTest
--- @param parentForRun DescribeOrTestForRun?
--- @return DescribeOrTestForRun
local function copyForRun(describeOrTest, parentForRun)
    local copy = {}

    for key, value in pairs(describeOrTest) do
        copy[key] = value
    end

    copy.registered = describeOrTest
    copy.parent = parentForRun
    copy.indentationLevel = describeOrTest.indentationLevel
    copy.isTest = describeOrTest.isTest
    copy.isDescribe = describeOrTest.isDescribe

    setmetatable(copy, DESCRIBE_OR_TEST_FOR_RUN_META)

    if describeOrTest.isDescribe then
        copy.children = {}

        for _, child in ipairs(describeOrTest.children) do
            copy:addChild(copyForRun(child, copy))
        end
    end

    return copy
end

--- Collects all tests in the tree, in the order they will run.
--- @param describeOrTest DescribeOrTestForRun
--- @param tests? DescribeOrTestForRun[]
--- @return DescribeOrTestForRun[]
local function collectTests(describeOrTest, tests)
    tests = tests or {}

    if describeOrTest.isTest then
        table.insert(tests, describeOrTest)
    elseif describeOrTest.children then
        for _, child in ipairs(describeOrTest.children) do
            collectTests(child, tests)
        end
    end

    return tests
end

--- Marks describes as skipped when none of the tests inside them will run. Returns whether anything inside runs.
--- @param describeOrTest DescribeOrTestForRun
--- @return boolean
local function markSkippedDescribes(describeOrTest)
    if describeOrTest.isTest then
        return not describeOrTest.toSkip
    end

    local anyRuns = false

    for _, child in ipairs(describeOrTest.children) do
        if markSkippedDescribes(child) then
            anyRuns = true
        end
    end

    describeOrTest.toSkip = not anyRuns

    return anyRuns
end

--- Decides which tests will be skipped, based on skip/todo/only and the runner options.
--- @param tests DescribeOrTestForRun[]
--- @param runnerOptions RunnerOptions
local function decideSkippedTests(tests, runnerOptions)
    -- Like Jest, `only` works per file: when a file has tests or describes marked `only`, the others in it are skipped
    local filesWithOnly = {}

    for _, test in ipairs(tests) do
        local current = test.registered

        while current do
            if current.isOnlyToRun then
                filesWithOnly[current.filePath] = true
            end

            current = current.parent
        end
    end

    for _, test in ipairs(tests) do
        local registered = test.registered
        local toSkip = hasFlagInSelfOrAncestors(registered, "toSkip")
            or isPathIgnored(test.filePath, runnerOptions.testPathIgnorePatterns)

        -- Like Jest, only tests are filtered by name, matching against the full name (including the names of
        -- surrounding describe blocks).
        if not toSkip and runnerOptions.testNamePattern then
            toSkip = not getFullName(registered):find(runnerOptions.testNamePattern)
        end

        if not toSkip and filesWithOnly[test.filePath] then
            toSkip = not hasFlagInSelfOrAncestors(registered, "isOnlyToRun")
        end

        test.toSkip = toSkip
    end
end

--- Works out for each test which hooks and retry settings apply to it, and which beforeAll and afterAll hooks
--- should run before and after it. Only tests that will actually run are considered, so beforeAll and afterAll run
--- around the first and last test in their scope that runs, and not at all if none run.
--- @param testSetRoot DescribeOrTestForRun
--- @param tests DescribeOrTestForRun[]
local function planHooks(testSetRoot, tests)
    local runnableTests = {}

    for _, test in ipairs(tests) do
        test.beforeAllHooks = {}
        test.beforeAllHooksToRun = {}
        test.afterAllHooksToRun = {}
        test.beforeEachHooks = {}
        test.afterEachHooks = {}
        test.retrySettings = findRetrySettings(test.registered)

        if not test.toSkip then
            table.insert(runnableTests, test)
        end
    end

    -- Visit describes outer to inner, so hooks of outer describes end up first
    local describesInOrder = {}

    local function collectDescribes(describeOrTest, depth)
        if describeOrTest.isDescribe then
            table.insert(describesInOrder, { describe = describeOrTest.registered, depth = depth })

            for _, child in ipairs(describeOrTest.children) do
                collectDescribes(child, depth + 1)
            end
        end
    end

    collectDescribes(testSetRoot, 0)

    local afterAllCandidates = {}
    local order = 0

    for _, describeInfo in ipairs(describesInOrder) do
        local hooks = rawget(describeInfo.describe, "hooks")

        if hooks then
            for _, entry in ipairs(hooks.beforeAll) do
                local isFirst = true

                for _, test in ipairs(runnableTests) do
                    if appliesTo(entry, test.registered) then
                        table.insert(test.beforeAllHooks, entry)

                        if isFirst then
                            table.insert(test.beforeAllHooksToRun, entry)
                            isFirst = false
                        end
                    end
                end
            end

            for _, entry in ipairs(hooks.afterAll) do
                local lastTest

                for _, test in ipairs(runnableTests) do
                    if appliesTo(entry, test.registered) then
                        lastTest = test
                    end
                end

                if lastTest then
                    order = order + 1
                    table.insert(afterAllCandidates, {
                        test = lastTest, entry = entry, depth = describeInfo.depth, order = order,
                    })
                end
            end
        end
    end

    -- afterAll hooks of inner describes run before those of outer describes
    table.sort(afterAllCandidates, function(a, b)
        if a.depth ~= b.depth then
            return a.depth > b.depth
        end

        return a.order < b.order
    end)

    for _, candidate in ipairs(afterAllCandidates) do
        table.insert(candidate.test.afterAllHooksToRun, candidate.entry)
    end

    -- beforeEach hooks run outer to inner, afterEach hooks inner to outer
    for _, test in ipairs(runnableTests) do
        local ancestors = {}
        local parent = test.registered.parent

        while parent do
            table.insert(ancestors, 1, parent)
            parent = parent.parent
        end

        for _, ancestor in ipairs(ancestors) do
            local hooks = rawget(ancestor, "hooks")

            if hooks then
                for _, entry in ipairs(hooks.beforeEach) do
                    if appliesTo(entry, test.registered) then
                        table.insert(test.beforeEachHooks, entry)
                    end
                end
            end
        end

        for i = #ancestors, 1, -1 do
            local hooks = rawget(ancestors[i], "hooks")

            if hooks then
                for _, entry in ipairs(hooks.afterEach) do
                    if appliesTo(entry, test.registered) then
                        table.insert(test.afterEachHooks, entry)
                    end
                end
            end
        end
    end
end

--- Groups the top level describes and tests by the file they were registered in, for reporters.
--- @param testSetRoot DescribeOrTestForRun
--- @return FileForRun[]
local function groupByFilePath(testSetRoot)
    local describesByFilePath = {}
    local filesByPath = {}

    for _, child in ipairs(testSetRoot.children) do
        local file = filesByPath[child.filePath]

        if not file then
            file = setmetatable({
                filePath = child.filePath,
                describesOrTests = {},
                isSkipped = true,
            }, FILE_FOR_RUN)

            filesByPath[child.filePath] = file
            table.insert(describesByFilePath, file)
        end

        if not child.toSkip then
            file.isSkipped = false
        end

        table.insert(file.describesOrTests, child)
    end

    return describesByFilePath
end

--- Prepares the registered tests for running.
--- @param rootDescribe DescribeOrTest
--- @param runnerOptions RunnerOptions
--- @return DescribeOrTestForRun, FileForRun[], DescribeOrTestForRun[]
local function prepareRun(rootDescribe, runnerOptions)
    local testSetRoot = copyForRun(rootDescribe)
    local tests = collectTests(testSetRoot)

    decideSkippedTests(tests, runnerOptions)
    markSkippedDescribes(testSetRoot)
    planHooks(testSetRoot, tests)

    return testSetRoot, groupByFilePath(testSetRoot), tests
end

--- Counts the outcome of the tests.
--- @param tests DescribeOrTestForRun[]
--- @return table
local function countTests(tests)
    local counts = { total = #tests, passed = 0, failed = 0, skipped = 0, todo = 0 }

    for _, test in ipairs(tests) do
        if test.isTodo then
            counts.todo = counts.todo + 1
        elseif test.toSkip then
            counts.skipped = counts.skipped + 1
        elseif test.hasRun then
            if test.success then
                counts.passed = counts.passed + 1
            else
                counts.failed = counts.failed + 1
            end
        end
    end

    return counts
end

--- Registers a Describe or Test to be run.
--- Must be called once befrore all others with a Describe to set as root.
--- @param describeOrTest DescribeOrTest
local function registerDescribeOrTest(describeOrTest)
    if currentDescribeOrTest then
        error("Cannot register a describe or test while a test is running. Register it at the top of a test file or "
            .. "inside a describe block.", 4)
    end

    -- Tests created by Jestronaut itself, like for test files that failed to load, already have a file path
    if rawget(describeOrTest, "filePath") == nil then
        local filePath, lineNumber = getTestFilePath()

        describeOrTest.filePath = filePath
        describeOrTest.lineNumber = lineNumber
    end

    if not currentParent then
        currentParent = describeOrTest
    else
        currentParent:addChild(describeOrTest)
    end

    describeOrTest.indentationLevel = currentParent and currentParent.indentationLevel + 1 or 0

    if describeOrTest.isDescribe then
        local oldParent = currentParent
        currentParent = describeOrTest

        -- Restore the parent when the describe raises an error, so tests registered afterwards don't end up in it
        local success, err = pcall(describeOrTest.fn)

        currentParent = oldParent

        if not success then
            error(err, 0)
        end
    end

    return describeOrTest
end

--- Registers the tests
--- @param testRegistrar function
local function registerTests(testRegistrar)
    if not rootFilePaths then
        error(
        "No root directory paths have been set. Configure options.roots using jestronaut:config(options) before registering tests.")
    end

    testRegistrar()
end

--- @class TestRunResults
--- @field success boolean # True if no test failed and the run did not bail.
--- @field bailed boolean # True if the run stopped early because of the `bail` option.
--- @field totalCount number # All tests, including skipped and todo tests.
--- @field passedCount number
--- @field failedCount number
--- @field skippedCount number # Skipped tests, not including todo tests.
--- @field todoCount number
--- @field duration number # In seconds.

--- Runs all registered tests and calls onFinished with the results. When the tests finish without waiting for the
--- host, the results are also returned. Otherwise the run continues each time `tick` is called.
--- @param runnerOptions RunnerOptions
--- @param onFinished? fun(results: TestRunResults)
--- @return TestRunResults?
local function runTests(runnerOptions, onFinished)
    -- Pass modified require's on through
    local reporter = callRespectingRequireOverride(function()
        if runnerOptions.reporter then
            return runnerOptions.reporter
        elseif runnerOptions.ci or not runnerOptions.colors then
            return require "jestronaut/plainreporter".newPlainReporter()
        end

        return require "jestronaut/reporter".newDefaultReporter()
    end)

    reporter.isVerbose = runnerOptions.verbose
    reporter.isColorDisabled = not runnerOptions.colors
    reporter.isSilent = runnerOptions.silent

    -- currentParent is the root describe at this point
    local testSetRoot, describesByFilePath, tests = prepareRun(currentParent, runnerOptions)
    local initialCounts = countTests(tests)

    -- Reporters use these to show the totals
    testSetRoot.totalTestCount = initialCounts.total
    testSetRoot.todoCount = initialCounts.todo

    reporter:startTestSet(testSetRoot, describesByFilePath)

    totalFailedTestCount = 0
    failedBeforeAllHooks = {}
    activeRunnerOptions = runnerOptions

    local eventLoop = type(runnerOptions.eventLoop) == "table" and runnerOptions.eventLoop or {}
    local now = eventLoop.now or os.clock
    local startTime = now()

    -- The run happens in a coroutine, so it can yield while waiting for the host (see the eventLoop option). Errors
    -- end the coroutine, so they are caught without a pcall, which Lua 5.1 can't yield across.
    local runCoroutine = coroutine.create(function()
        return testSetRoot:run(reporter, runnerOptions)
    end)

    local function finish(success, err)
        local duration = now() - startTime

        activeRun = nil
        activeRunnerOptions = nil
        currentDescribeOrTest = nil

        local counts = countTests(tests)
        local bailed = false

        if not success then
            if getmetatable(err) ~= BAIL_SIGNAL_META then
                error(debug.traceback(runCoroutine, tostring(err)), 0)
            end

            bailed = true
            reporter:printBailed(testSetRoot, tostring(err))
        else
            reporter:printEnd(testSetRoot, counts.failed, counts.skipped, duration)
        end

        -- Like Jest, finding no tests at all fails the run, since it usually means the tests weren't found
        local noTestsFound = counts.total == 0 and not runnerOptions.passWithNoTests

        if noTestsFound then
            print("No tests found. Check the roots and testMatch options, or set passWithNoTests to pass without tests.")
        end

        local results = {
            success = counts.failed == 0 and not bailed and not noTestsFound,
            bailed = bailed,
            totalCount = counts.total,
            passedCount = counts.passed,
            failedCount = counts.failed,
            skippedCount = counts.skipped,
            todoCount = counts.todo,
            duration = duration,
        }

        if onFinished then
            onFinished(results)
        end

        return results
    end

    local function step()
        local success, err = coroutine.resume(runCoroutine)

        if coroutine.status(runCoroutine) == "dead" then
            return true, finish(success, err)
        elseif not isWaitingForHost then
            error("The test runner's coroutine was yielded by a test. Use your own coroutine to yield in tests.", 0)
        end

        return false
    end

    activeRun = { step = step }

    local _, results = step()

    return results
end

--- Continues the current run when it is waiting for the host (see the `external` field of the eventLoop option).
--- Call this regularly, e.g. every frame, until it returns true.
--- @return boolean # True when there is no run waiting anymore.
local function tick()
    if not activeRun then
        return true
    end

    return (activeRun.step())
end

return {
    DESCRIBE_OR_TEST_META = DESCRIBE_OR_TEST_META,
    DESCRIBE_OR_TEST_FOR_RUN_META = DESCRIBE_OR_TEST_FOR_RUN_META,
    HOOK_KINDS = HOOK_KINDS,

    resetEnvironment = resetEnvironment,

    getCurrentDescribeOrTest = getCurrentDescribeOrTest,
    getFullName = getFullName,

    registerDescribeOrTest = registerDescribeOrTest,
    setRoots = setRoots,
    registerTests = registerTests,
    runTests = runTests,
    tick = tick,

    incrementAssertionCount = incrementAssertionCount,
    getAssertionCount = getAssertionCount,
    setExpectAssertion = setExpectAssertion,
    getExpectedAssertionCount = getExpectedAssertionCount,
    setExpectedAssertionCount = setExpectedAssertionCount,

    retryTimes = retryTimes,

    afterAll = afterAll,
    afterEach = afterEach,
    beforeAll = beforeAll,
    beforeEach = beforeEach,
}
