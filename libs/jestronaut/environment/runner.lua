local callRespectingRequireOverride = require "jestronaut/utils/require".callRespectingRequireOverride

local TEST_RUNNER = {}
TEST_RUNNER.__index = TEST_RUNNER

--- Ticks the event loop
--- @alias EventLoopTicker fun(): boolean

--- @param runnerOptions RunnerOptions
local function newTestRunner(runnerOptions)
    local self = setmetatable({}, TEST_RUNNER)

    self.reporter = callRespectingRequireOverride(function()
        return runnerOptions.reporter or (require "jestronaut/reporter".newDefaultReporter())
    end)

    self.reporter.isVerbose = runnerOptions.verbose

    self.runnerOptions = runnerOptions

    self.queuedTests = {}
    self.processedTests = {}
    self.timeout = runnerOptions.testTimeout or 5000
    self.preTestCallback = nil
    self.modifyTestResultCallback = nil
    self.postTestCallback = nil

    self:reset()

    return self
end

--- Sets a callback to be called before each test is run.
--- @param callback fun(test: DescribeOrTest)
function TEST_RUNNER:setPreTestCallback(callback)
    self.preTestCallback = callback
end

--- Sets a callback to be called after each test is run
--- and allows for modifying the test result.
--- @param callback fun(test: DescribeOrTest, success: boolean, errorMessage: string?): boolean, string?
function TEST_RUNNER:setModifyTestResultCallback(callback)
    self.modifyTestResultCallback = callback
end

--- Sets a callback to be called after each test is run.
--- @param callback fun(test: DescribeOrTest, success: boolean)
function TEST_RUNNER:setPostTestCallback(callback)
    self.postTestCallback = callback
end

function TEST_RUNNER:queueTest(test)
    local name = test.name
    local testFnOrAsyncWrapper = test.fn
    local timeout = test.timeout
    local isAsync = type(testFnOrAsyncWrapper) == "table"

    assert(test.registered ~= nil, "Should pass copy to test runner, not the original test registration")

    local queuedTest = {
        name = name,
        type = isAsync and "async" or "sync",
        timeout = timeout or self.timeout,
        status = "starting",
        shouldSkip = test.toSkip,

        test = not test.isDescribe and test or nil,
        describe = test.isDescribe and test or nil,
    }

    if isAsync then
        queuedTest.asyncWrapper = testFnOrAsyncWrapper
    else
        queuedTest.fn = testFnOrAsyncWrapper
    end

    table.insert(self.queuedTests, queuedTest)
end

function TEST_RUNNER:reset()
    self.isCompleted = false
    self.isStarted = false
    self.failedTestCount = 0

    for _, test in ipairs(self.processedTests) do
        test.status = "starting"
        test.error = nil
        test.result = nil
        test.startTime = nil
        table.insert(self.queuedTests, test)
	end

    self.processedTests = {}
    self.describeMap = {}

    -- Map describes and tests, so we can track which ones are done
    for _, queuedTest in ipairs(self.queuedTests) do
        if queuedTest.test then
            self.describeMap[queuedTest.test] = queuedTest
        end
    end
end

function TEST_RUNNER:markFinished(queuedTest, status, err, retryWithRemainingCount)
    queuedTest.status = status
    queuedTest.error = err

    if (retryWithRemainingCount) then
        self.reporter:onTestRetrying(queuedTest.test, retryWithRemainingCount)
        return
    else
        table.insert(self.processedTests, queuedTest)
    end

    if (status == nil) then
        self.reporter:onTestSkipped(queuedTest.test)
    else
        self.reporter:onTestFinished(queuedTest.test, status, err)
    end

    self:updateDescribeMap(queuedTest.test)
end

function TEST_RUNNER:updateDescribeMap(testOrDescribe)
    -- Remove this test from the map, and check if the describe is done
    self.describeMap[testOrDescribe] = nil

    local describe = testOrDescribe.parent

    if describe then
        local describeDone = true

        for _, child in ipairs(describe.children) do
            if self.describeMap[child] then
                describeDone = false
                break
            end
        end

        if describeDone then
            self.reporter:onTestFinished(describe, true)

            self:updateDescribeMap(describe)
        end
    end
end

function TEST_RUNNER:handleTestFinished(queuedTest, success, errorMessage)
    if success or success == nil then
        self:markFinished(queuedTest, success, errorMessage)
    else
        queuedTest.firstError = queuedTest.firstError or errorMessage

        -- Go up the test context, finding the first place where retrySettings is set
        local retryWithRemainingCount = queuedTest.test.traverseTestContexts(function(testContext, object)
            if testContext.retrySettings then
                local retrySettings = testContext.retrySettings

                if retrySettings.timesRemaining > 0 then
                    retrySettings.timesRemaining = retrySettings.timesRemaining - 1

                    queuedTest.status = "starting"
                    queuedTest.error = nil
                    queuedTest.result = nil
                    queuedTest.startTime = nil

                    -- Retry it right away, placing it after the current test
                    table.insert(self.queuedTests, self.currentTestIndex + 1, queuedTest)
                end

                return retrySettings.timesRemaining
            end
        end)

        if (retryWithRemainingCount) then
            self:markFinished(queuedTest, success, queuedTest.firstError, retryWithRemainingCount)
        else
            self:markFinished(queuedTest, success, queuedTest.firstError)

            self.failedTestCount = self.failedTestCount + 1

            local bailAfter = self.runnerOptions.bail

            if bailAfter ~= nil and self.failedTestCount >= bailAfter then
                error(
                    "Bail after " .. self.failedTestCount .. " failed "
                    .. (self.failedTestCount == 1 and "test" or "tests")
                    .. ". Test '" .. queuedTest.name .. "' (file: " .. queuedTest.test.filePath .. ":"
                    .. queuedTest.test.startLineNumber .. ") . Test failed with error: \n" .. tostring(queuedTest.firstError)
                )
            end
        end
    end
end

function TEST_RUNNER:runTest(queuedTest)
    if self.preTestCallback then
        self.preTestCallback(queuedTest.test)
    end

    local isAsync = queuedTest.type == "async"
    local testFn = queuedTest.fn
    local testFnParameter

    if isAsync then
        testFn = queuedTest.asyncWrapper.testFn
        testFnParameter = queuedTest.asyncWrapper
    end

    local status, errorMessage = xpcall(function()
        testFn(testFnParameter)
    end, function(err)
        return debug.traceback(err, 2)
    end)

    -- Only modify the test result if the async function fails immediately, or this
    -- is a sync test
    if ((not isAsync or not status) and self.modifyTestResultCallback) then
        status, errorMessage = self.modifyTestResultCallback(queuedTest.test, status, errorMessage)
    end

    -- TODO: Should this also run here for async tests? Even though those may not have finished yet?
    if self.postTestCallback and queuedTest.status ~= nil then
        self.postTestCallback(queuedTest.test, queuedTest.status == true)
    end

    return status, errorMessage
end

function TEST_RUNNER:start(rootDescribe, describesByFilePath, skippedTestCount)
    self.isStarted = true
    self.startTime = os.time()
    self.reporter:onStartTestSet(rootDescribe, describesByFilePath, skippedTestCount)
end

function TEST_RUNNER:tick()
    if self.isCompleted then
        return false
	end

    if not self.isStarted then
        error("Test runner not started! Did you forget to call `:start()`?")
    end

    local slowDown = self.runnerOptions.slowDown
    local remainingTests = {}

    -- Process queued tests
    for i, queuedTest in ipairs(self.queuedTests) do
        self.currentTestIndex = i

        if (slowDown) then
            os.execute("sleep " .. (slowDown * .001))
        end

        self.reporter:onTestStarting(queuedTest.test or queuedTest.describe)

        if (queuedTest.describe) then
            table.insert(self.processedTests, queuedTest)
        elseif (queuedTest.shouldSkip) then
            self:handleTestFinished(queuedTest, nil, "Test skipped")
        elseif queuedTest.type == "sync" then
            -- Run sync tests immediately
            local success, errorMessage = self:runTest(queuedTest)

            self:handleTestFinished(queuedTest, success, errorMessage)
        elseif queuedTest.type == "async" then
            -- Start async test if not started
            if queuedTest.status == "starting" then
                queuedTest.startTime = os.time()
                queuedTest.status = "pending"

                local success, errorMessage = self:runTest(queuedTest)

                -- Failed even while starting the test
                if not success then
					self:handleTestFinished(queuedTest, success, errorMessage)
                else
                    -- Test started, might need further processing
                    queuedTest.result = queuedTest
                    table.insert(remainingTests, queuedTest)
                end
            elseif queuedTest.status == "pending" then
                -- Check for timeout on pending async tests
                -- We explicitly check if they're still pending, as they might have been marked as failed/finished
				-- while the loop already started
                local elapsedTime = os.time() - queuedTest.startTime

                -- We check the timeout first, because even if 'done' is true, if it's late we should fail the test
                if elapsedTime > queuedTest.timeout then
                    local status, errorMessage = false, "Test timed out after " .. queuedTest.timeout .. " seconds"

                    if self.modifyTestResultCallback then
                        status, errorMessage = self.modifyTestResultCallback(queuedTest.test, status, errorMessage)
                    end

					self:handleTestFinished(queuedTest, status, errorMessage)
                elseif (queuedTest.asyncWrapper.isDone) then
                    local errorMessage = queuedTest.asyncWrapper.errorMessage
                    local success = not errorMessage

                    if self.modifyTestResultCallback then
                        success, errorMessage = self.modifyTestResultCallback(queuedTest.test, success, errorMessage)
                    end

                    self:handleTestFinished(queuedTest, success, errorMessage)
                else
                    -- Test still in progress
                    table.insert(remainingTests, queuedTest)
                end
            end
        end
    end

    -- Update queued tests
    self.queuedTests = remainingTests

    -- Check if all tests are processed
    if #self.queuedTests == 0 then
        self:finalize()
    end

	return not self.isCompleted
end

function TEST_RUNNER:finalize()
    if self.isCompleted then
        return
    end

    local testDuration = os.time() - self.startTime

    self.isCompleted = true
    self.isStarted = false

	self:printResults(testDuration)
end

function TEST_RUNNER:printResults(testDuration)
    local passed = 0
    local failed = 0
    local skipped = 0

    for _, processedTest in ipairs(self.processedTests) do
        if processedTest.test then
            if processedTest.status == true then
                passed = passed + 1
            elseif processedTest.status == nil then
                skipped = skipped + 1
            else
                failed = failed + 1
            end
        end
    end

    self.reporter:onEndTestSet(self.processedTests, passed, failed, skipped, testDuration)
end

return {
    newTestRunner = newTestRunner,
}
