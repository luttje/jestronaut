local extendMetaTableIndex = require "jestronaut/utils/metatables".extendMetaTableIndex
local runnerLib = require "jestronaut/environment/runner"
local functionLib = require "jestronaut/utils/functions"
local stringsLib = require "jestronaut/utils/strings"

local rootFilePaths

--- @class DescribeOrTest
--- @type DescribeOrTest?
local currentDescribeOrTest = nil

--- @class LocalState
--- @field notExecuting DescribeOrTest
--- @field retrySettings table
--- @field beforeAll fun(): void
--- @field beforeEach fun(): void
--- @field afterAll fun(): void
--- @field afterEach fun(): void
local LOCAL_STATE_META = {}

--- @type LocalState[]
local testLocalStates = {}

--- All file paths with all tests and describes in the file.
--- @type table<string, DescribeOrTest[]>
local testFunctionLookup = {}

--- @type DescribeOrTest?
local currentParent = nil

local function getCurrentDescribeOrTest()
    return currentDescribeOrTest
end

local function resetEnvironment()
    currentDescribeOrTest = nil
    rootFilePaths = nil
    currentParent = nil
    testLocalStates = {}
    testFunctionLookup = {}
end

--- Sets where Jestronaut should look for tests. This is used to determine the test file path.
--- @param roots string[]
local function setRoots(roots)
    for i, root in ipairs(roots) do
        roots[i] = stringsLib.normalizePath(root)
    end

    rootFilePaths = roots
end

--- Gets the file path, starting line, and ending line of the test by checking the stack trace
--- until it reaches beyond the root of this package.
--- @param test DescribeOrTest
--- @return string, number, number
local function getTestFilePath(test)
    local filePath, startLineNumber, endLineNumber
    local i = 1

    local testFn = test and test.fn

    if (test and type(testFn) == "table") then
        -- Async tests are wrapped in a table and have the original function stored
        -- for this function, so we can get the file path and line number from the original function
        testFn = testFn.originalFunction
    end

    while true do
        local info = debug.getinfo(testFn or i, "Sl")

        if (not info) then
            error(
                "Could not find the test file path. Please make sure options.roots is set to the directories where your tests are located."
            )

            break
        end

        local path = stringsLib.normalizePath(
            info.source:sub(1, 1) == "@" and info.source:sub(2) or info.source
        )

        if rootFilePaths ~= nil then
            local found = false

            -- Check if the file path contains the root file path. If it does, then we've found the test
            for _, rootFilePath in ipairs(rootFilePaths) do
                if path:sub(1, rootFilePath:len()) == rootFilePath then
                    filePath = path
                    startLineNumber = info.linedefined
                    endLineNumber = info.lastlinedefined
                    found = true
                    break
                end
            end

            if found then
                break
            end
        else
            filePath = path
            startLineNumber = info.linedefined
            endLineNumber = info.lastlinedefined
            break
        end

        if (not testFn) then
            i = i + 1
        else
            testFn = nil
        end
    end

    return filePath, startLineNumber, endLineNumber
end

--- Returns the state local to the test file.
--- @param test DescribeOrTest
--- @return LocalState
local function getTestLocalState(testFilePath)
    local testLocalState = testLocalStates[testFilePath]

    if not testLocalState then
        testLocalState = {}
        testLocalStates[testFilePath] = testLocalState
    end

    return testLocalState
end

--- Sets the amount of times tests will be retried. Must be called at the top of a file or describe block.
--- @param numRetries number
--- @param options table
local function retryTimes(numRetries, options)
    local filePath, startLineNumber, endLineNumber = getTestFilePath(currentDescribeOrTest)
    local testLocalState = getTestLocalState(filePath)

    if currentDescribeOrTest and currentDescribeOrTest.isTest then
        error("Cannot set the test retries outside of a file or describe block", 2)
    end

    testLocalState.retrySettings = {
        timesRemaining = numRetries,
        options = options or {},
    }
end

local function beforeDescribeOrTest(describeOrTest)
    currentDescribeOrTest = describeOrTest

    local fileLocalState = getTestLocalState(describeOrTest.filePath)

    if fileLocalState.beforeAll then
        fileLocalState.beforeAll()
    end

    if fileLocalState.beforeEach then
        fileLocalState.beforeEach()
    end
end

local function afterDescribeOrTest(describeOrTest, success)
    local fileLocalState = getTestLocalState(describeOrTest.filePath)

    if fileLocalState.afterEach then
        fileLocalState.afterEach()
    end

    if fileLocalState.afterAll then
        fileLocalState.afterAll()
    end

    currentDescribeOrTest = nil
end

local function afterAll(fn, timeout)
    local filePath = getTestFilePath(currentDescribeOrTest)
    local fileLocalState = getTestLocalState(filePath)
    fileLocalState.afterAll = fn
end

local function afterEach(fn, timeout)
    local filePath = getTestFilePath(currentDescribeOrTest)
    local fileLocalState = getTestLocalState(filePath)
    fileLocalState.afterEach = fn
end

local function beforeAll(fn, timeout)
    local filePath = getTestFilePath(currentDescribeOrTest)
    local fileLocalState = getTestLocalState(filePath)
    fileLocalState.beforeAll = fn
end

local function beforeEach(fn, timeout)
    local filePath = getTestFilePath(currentDescribeOrTest)
    local fileLocalState = getTestLocalState(filePath)
    fileLocalState.beforeEach = fn
end

--- @class DescribeOrTest
local DESCRIBE_OR_TEST_META = {
    indentationLevel = -1, -- Start at -1 so the root describe is at 0
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

function DESCRIBE_OR_TEST_META:flipIfFailExpected(success, errorMessage)
    if self.expectFail == true then
        if success then
            success = false
            errorMessage = "Error! Expected test to fail, but it succeeded."
        else
            success = true
        end
    end

    return success, errorMessage
end

-- --- Runs the test and returns the amount of failed tests.
-- --- @param reporter Reporter
-- --- @param runnerOptions RunnerOptions
-- --- @return number
-- function DESCRIBE_OR_TEST_META:run(reporter, runnerOptions)
--     local failedTestCount = 0

--     if self.toSkip then
--         reporter:testSkipped(self)

--         return failedTestCount
--     end

--     if (runnerOptions.slowDown) then -- For debugging terminal output
--         local slowDown = runnerOptions.slowDown * 0.001

--         local startTime = os.clock()
--         local endTime = startTime + slowDown

--         -- Start a loop to freeze for the specified amount of milliseconds
--         while os.clock() < endTime do end
--     end

--     if self.isTest then
--         reporter:testStarting(self)
--         self.isRunning = true

--         local testLocalState = getTestLocalState(self.filePath)
--         local retrySettings = testLocalState.retrySettings

--         beforeDescribeOrTest(self)

--         if (type(self.fn) == "table") then
--             error("TODO: Implement async tests")
--         end

--         local success, errorMessage = xpcall(self.fn, debug.traceback)

--         success, errorMessage = self:flipIfFailExpected(success, errorMessage)

--         afterDescribeOrTest(self, success)

--         self.success = success
--         self.isRunning = false
--         self.hasRun = true

--         if not success then
--             self.errorMessage = errorMessage
--         end

--         if (success or (not retrySettings or retrySettings.options.logErrorsBeforeRetry)) then
--             reporter:testFinished(self, success)
--         end

--         if not success then
--             failedTestCount = failedTestCount + 1

--             if retrySettings and retrySettings.timesRemaining then
--                 if retrySettings.timesRemaining > 0 then
--                     retrySettings.timesRemaining = retrySettings.timesRemaining - 1

--                     reporter:testRetrying(self, retrySettings.timesRemaining + 1)

--                     return self:run(reporter, runnerOptions)
--                 end
--             end

--             if runnerOptions.bail ~= nil and failedTestCount >= runnerOptions.bail then
--                 reporter:testFinished(self, success)

--                 error(
--                     "Bail after " .. failedTestCount .. " failed "
--                     .. (failedTestCount == 1 and "test" or "tests") .. " with error: \n" .. errorMessage
--                 )
--             end
--         end
--     else
--         if #self.children > 0 then
--             self.isRunning = true

--             for _, child in ipairs(self.children) do
--                 local childFailedCount = child:run(reporter, runnerOptions)

--                 failedTestCount = failedTestCount + childFailedCount
--             end

--             self.isRunning = false
--             self.hasRun = true
--             self.success = failedTestCount == 0
--         end

--         reporter:testFinished(self, self.success)
--     end

--     return failedTestCount
-- end

--- @class DescribeOrTestForRun : DescribeOrTest
local DESCRIBE_OR_TEST_FOR_RUN_META = {
    isDescribeOrTestForRun = true,
}

extendMetaTableIndex(DESCRIBE_OR_TEST_FOR_RUN_META, DESCRIBE_OR_TEST_META)

function DESCRIBE_OR_TEST_FOR_RUN_META:addChild(describeOrTest)
    self.children[#self.children + 1] = describeOrTest
end

--- Creates a copy of the describe or test for running. Returns the estimated amount of tests to skip.
--- @param describeOrTest DescribeOrTest
--- @param runnerOptions RunnerOptions
--- @return DescribeOrTestForRun, number
local function makeDescribeOrTestForRun(describeOrTest, runnerOptions)
    local describeOrTestForRun = {}

    for key, value in pairs(describeOrTest) do
        if key == "children" then
            value = {}
        elseif key == "parent" then
            value = nil
        end

        describeOrTestForRun[key] = value
    end

    -- Some things to copy that are in the metatable
    describeOrTestForRun.indentationLevel = describeOrTest.indentationLevel
    describeOrTestForRun.isTest = describeOrTest.isTest
    describeOrTestForRun.isDescribe = describeOrTest.isDescribe

    if runnerOptions.testPathIgnorePatterns then
        for _, pattern in ipairs(runnerOptions.testPathIgnorePatterns) do
            local plain = not pattern:find("^/.*/$")    -- Only enable pattern matching if the pattern doesn't start and end with a slash
            pattern = plain and pattern or pattern:sub(2, -2) -- Remove the slashes if pattern matching is enabled

            if describeOrTestForRun.filePath:find(pattern, nil, plain) then
                describeOrTestForRun.toSkip = true
            end
        end
    elseif runnerOptions.testNamePattern then
        if not describeOrTestForRun.name:find(runnerOptions.testNamePattern) then
            describeOrTestForRun.toSkip = true
        end
    end

    setmetatable(describeOrTestForRun, DESCRIBE_OR_TEST_FOR_RUN_META)

    return describeOrTestForRun, (describeOrTestForRun.toSkip and 1 or 0)
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
    skippedCount = 0,
    failedCount = 0,
}

FILE_FOR_RUN.__index = FILE_FOR_RUN

--- Recursively copies a Describe or Test to be run, returning the root describe, a table with all describes grouped by file path,
--- and the number of skipped tests.
--- TODO: This function is a bit of a mess and could be cleaned up. I don't like the way it's handling the file paths.
--- TODO: I later added the bit to cache test file paths and line numbers, and I don't think the original describesByFilePath
--- TODO: table is that useful anymore.
--- @param describeOrTest DescribeOrTest
--- @param runnerOptions RunnerOptions
--- @return DescribeOrTestForRun, table, number, table
local function copyDescribeOrTestForRun(describeOrTest, runnerOptions)
    local describeOrTestForRun, skippedTestCount = makeDescribeOrTestForRun(describeOrTest, runnerOptions)
    local describesByFilePath = {}

    local function insertChildWithFile(child)
        local fileIndex = #describesByFilePath + 1

        for i, file in ipairs(describesByFilePath) do
            if file.filePath == child.filePath then
                fileIndex = i
                break
            end
        end

        -- Build the lookup for easily finding tests and describes by file, which
        -- is used to find test contexts by file path and line number
        testFunctionLookup[child.filePath] = testFunctionLookup[child.filePath] or {}
        table.insert(testFunctionLookup[child.filePath], child)

        describesByFilePath[fileIndex] = describesByFilePath[fileIndex] or setmetatable({
            filePath = child.filePath,
            describesOrTests = {},
        }, FILE_FOR_RUN)

        if describesByFilePath[fileIndex].__skipNextAdded then
            child.toSkip = true
            skippedTestCount = skippedTestCount + 1
        end

        if child.isOnlyToRun then
            describesByFilePath[fileIndex].__skipNextAdded = true
        end

        table.insert(describesByFilePath[fileIndex].describesOrTests, child)
    end

    if describeOrTest.isDescribe then
        for _, child in pairs(describeOrTest.children) do
            local child, childDescribesByFilePath, childSkippedCount = copyDescribeOrTestForRun(child, runnerOptions)

            describeOrTestForRun:addChild(child)

            skippedTestCount = skippedTestCount + childSkippedCount
        end
    end

    if describeOrTestForRun.children then
        for _, child in pairs(describeOrTestForRun.children) do
            insertChildWithFile(child)
        end
    end

    return describeOrTestForRun, describesByFilePath, skippedTestCount
end

--- Registers a Describe or Test to be run.
--- Must be called once befrore all others with a Describe to set as root.
--- @param describeOrTest DescribeOrTest
local function registerDescribeOrTest(describeOrTest)
    local filePath, startLineNumber, endLineNumber = getTestFilePath(describeOrTest)

    describeOrTest.filePath = filePath
    describeOrTest.startLineNumber = startLineNumber
    describeOrTest.endLineNumber = endLineNumber

    if not currentParent then
        currentParent = describeOrTest
    else
        currentParent:addChild(describeOrTest)
    end

    describeOrTest.indentationLevel = currentParent and currentParent.indentationLevel + 1 or 0

    if describeOrTest.isDescribe then
        local oldParent = currentParent
        currentParent = describeOrTest

        describeOrTest.fn()

        currentParent = oldParent
    end

    return describeOrTest
end

--- Gets a test by checking if the given filePath and line number
--- matches a test function.
--- @param filePath string
--- @param lineNumber number
--- @return DescribeOrTest?
local function getTestByFilePathAndLineNumber(filePath, lineNumber)
    filePath = stringsLib.normalizePath(
        filePath:sub(1, 1) == "@" and filePath:sub(2) or filePath
    )

    local testsAndDescribes = testFunctionLookup[filePath]

    if not testsAndDescribes then
        return nil
    end

    for _, describeOrTest in ipairs(testsAndDescribes) do
        if describeOrTest.isTest and describeOrTest.startLineNumber <= lineNumber and describeOrTest.endLineNumber >= lineNumber then
            return describeOrTest
        end
    end

    return nil
end

--- Gets the most nested describe that matches the given line number in a file.
--- If nested describes are found, the most nested describe is returned.
--- @param filePath string
--- @param lineNumber number
--- @return DescribeOrTest?
local function getMostNestedDescribeByFilePathAndLineNumber(filePath, lineNumber)
    local testsAndDescribes = testFunctionLookup[filePath]

    if not testsAndDescribes then
        return nil
    end

    local mostNestedDescribe = nil

    for _, describeOrTest in ipairs(testsAndDescribes) do
        if describeOrTest.isDescribe and describeOrTest.startLineNumber <= lineNumber and describeOrTest.endLineNumber >= lineNumber then
            -- The last describe will be the most nested
            mostNestedDescribe = describeOrTest
        end
    end

    return mostNestedDescribe
end

--- Gets information about the caller function, such that we can find the
--- file path and line number of the caller for tracking which test we're
--- being called inside of.
--- @return string, number # The file path and line number of the caller
local function getCallerFunctionInfo()
    -- Let's traverse the stack to find the correct caller, starting at 3,
    -- since those are definetely not the caller we want
    local i = 3

    while true do
        local info = debug.getinfo(i, "Sl")

        if (not info) then
            error("Could not find the caller function line.")
        end

        local source = stringsLib.normalizePath(
            info.source:sub(1, 1) == "@" and info.source:sub(2) or info.source
        )

        if rootFilePaths ~= nil then
            local found = false

            -- Check if the file path contains the root file path. If it does, then we've found the test
            for _, rootFilePath in ipairs(rootFilePaths) do
                if source:sub(1, rootFilePath:len()) == rootFilePath then
                    return source, info.currentline
                end
            end
        else
            return source, info.currentline
        end

        i = i + 1
    end
end

--- Gets the test that is being called from the caller function.
--- @return DescribeOrTest?
local function getTestFromCallerFunction()
    local source, lineNumber = getCallerFunctionInfo()
    local describeOrTest = getTestByFilePathAndLineNumber(source, lineNumber)

    return describeOrTest
end

local function incrementAssertionCount()
    local relevantDescribeOrTest = getTestFromCallerFunction()

    if not relevantDescribeOrTest then
        error("Cannot increase the assertion count outside of a test or describe block", 2)
    end

    relevantDescribeOrTest.assertionCount = relevantDescribeOrTest.assertionCount + 1
end

local function getAssertionCount()
    local relevantDescribeOrTest = getTestFromCallerFunction()

    if not relevantDescribeOrTest then
        error("Cannot get the assertion count outside of a test or describe block", 2)
    end

    return relevantDescribeOrTest.assertionCount
end

local function setExpectAssertion()
    local relevantDescribeOrTest = getTestFromCallerFunction()

    if not relevantDescribeOrTest then
        error("Cannot set the expect assertion outside of a test or describe block", 2)
    end

    relevantDescribeOrTest.expectAssertion = true
end

local function getExpectedAssertionCount()
    local relevantDescribeOrTest = getTestFromCallerFunction()

    if not relevantDescribeOrTest then
        error("Cannot get the expected assertion count outside of a test or describe block", 2)
    end

    return relevantDescribeOrTest.expectedAssertionCount
end

local function setExpectedAssertionCount(count)
    local relevantDescribeOrTest = getTestFromCallerFunction()

    if not relevantDescribeOrTest then
        error("Cannot set the expected assertion count outside of a test or describe block", 2)
    end

    relevantDescribeOrTest.expectedAssertionCount = count
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

--- Runs all registered tests.
--- @param runnerOptions RunnerOptions
local function runTests(runnerOptions)
    assert(currentParent, 'Root describe not set. Use `jestronaut.describe("root", function() end)` to set the root describe.')

    local runner = runnerLib.newTestRunner(runnerOptions)

    runner:setPreTestCallback(function(test)
        beforeDescribeOrTest(test)
    end)

    runner:setModifyTestResultCallback(function(test, success, errorMessage)
        if (test.expectedAssertionCount ~= nil and test.expectedAssertionCount ~= test.assertionCount) then
            success = false
            errorMessage = "Expected " .. test.expectedAssertionCount .. " assertions, but " .. test.assertionCount .. " were run"
        end

        if (test.expectAssertion and test.assertionCount == 0) then
            success = false
            errorMessage = "Expected at least one assertion to be run, but none were run"
        end

        return test:flipIfFailExpected(success, errorMessage)
    end)

    runner:setPostTestCallback(function(test, success)
        afterDescribeOrTest(test, success)
    end)

    local testSetRoot, describesByFilePath, skippedTestCount = copyDescribeOrTestForRun(currentParent, runnerOptions)

    local function queueTestIfTest(describeOrTest)
        if describeOrTest.isTest then
            runner:queueTest(describeOrTest)
        end
    end

    -- Find all nested describes and tests and add them to the runner queue
    local i = 1

    while i <= #testSetRoot.children do
        local describeOrTest = testSetRoot.children[i]

        queueTestIfTest(describeOrTest)

        if describeOrTest.children then
            for _, child in ipairs(describeOrTest.children) do
                table.insert(testSetRoot.children, i + 1, child)
            end
        end

        i = i + 1
    end

    runnerOptions.eventLoopTicker(function()
        return runner:tick()
    end)
end

return {
    DESCRIBE_OR_TEST_META = DESCRIBE_OR_TEST_META,
    DESCRIBE_OR_TEST_FOR_RUN_META = DESCRIBE_OR_TEST_FOR_RUN_META,

    resetEnvironment = resetEnvironment,

    getCurrentDescribeOrTest = getCurrentDescribeOrTest,
    getDescribeOrTestForRun = copyDescribeOrTestForRun,

    registerDescribeOrTest = registerDescribeOrTest,
    setRoots = setRoots,
    registerTests = registerTests,
    runTests = runTests,

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
