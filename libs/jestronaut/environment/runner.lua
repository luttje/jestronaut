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

    self.queuedTests = {}
    self.processedTests = {}

    self.timeout = 5
    self.isCompleted = false

    self.preTestCallback = nil
    self.modifyTestResultCallback = nil
    self.postTestCallback = nil

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

    local queuedTest = {
        name = name,
        type = isAsync and "async" or "sync",
        timeout = timeout or self.timeout,
        status = "starting",
        shouldSkip = test.toSkip,

        test = test,
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

	for _, test in ipairs(self.processedTests) do
		test.status = "starting"
		test.error = nil
		test.result = nil
		test.startTime = nil
		table.insert(self.queuedTests, test)
	end

    self.processedTests = {}
end

function TEST_RUNNER:markFinished(test, status, err)
    test.status = status
    test.error = err

    -- TODO: Use reporter instead
    if status == "passed" then
        print(string.format("✅ PASSED %s", test.name))
    elseif status == "skipped" then
        print(string.format("⏭️  SKIPPED %s", test.name))
    else
        print(string.format("❌ FAILED %s - %s", test.name, test.error or "Unknown error"))
    end

    table.insert(self.processedTests, test)
end

function TEST_RUNNER:runTest(queuedTest)
    if self.preTestCallback then
        self.preTestCallback(queuedTest.test)
    end

    local testFn = queuedTest.fn
    local testFnParameter

    if queuedTest.type == "async" then
        testFn = queuedTest.asyncWrapper.testFn
        testFnParameter = queuedTest.asyncWrapper
    end

    -- local status, errorMessage = pcall(testFn, testFnParameter)
    local status, errorMessage = xpcall(function()
        testFn(testFnParameter)
    end, function(err)
        return debug.traceback(err, 2)
    end)

    if self.modifyTestResultCallback then
        status, errorMessage = self.modifyTestResultCallback(queuedTest.test, status, errorMessage)
    end

    if self.postTestCallback then
        self.postTestCallback(queuedTest.test, queuedTest.status == "passed")
    end

    return status, errorMessage
end

function TEST_RUNNER:tick()
    if self.isCompleted then
        return false
	end

    local remainingTests = {}

    -- Process queued tests
    for i, queuedTest in ipairs(self.queuedTests) do
        if (queuedTest.shouldSkip) then
            self:markFinished(queuedTest, "skipped")
        elseif queuedTest.type == "sync" then
            -- Run sync tests immediately
            local status, errorMessage = self:runTest(queuedTest)

            self:markFinished(queuedTest, status and "passed" or "failed", errorMessage)
        elseif queuedTest.type == "async" then
            -- Start async test if not started
            if queuedTest.status == "starting" then
                queuedTest.startTime = os.time()
                queuedTest.status = "pending"

                local status, errorMessage = self:runTest(queuedTest)

                if not status then
					self:markFinished(queuedTest, "failed", errorMessage)
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

                if (queuedTest.asyncWrapper.isDone) then
                    self:markFinished(queuedTest, "passed")
                elseif elapsedTime > queuedTest.timeout then
                    local status, errorMessage = false, "Test timed out after " .. queuedTest.timeout .. " seconds"

                    if self.modifyTestResultCallback then
                        status, errorMessage = self.modifyTestResultCallback(queuedTest.test, status, errorMessage)
                    end

					self:markFinished(queuedTest, status and "passed" or "failed", errorMessage)
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

	self:printResults()
	self.isCompleted = true
end

function TEST_RUNNER:printResults()
    print("\n================================")
    print("Test Results:")

    local passed = 0
    local failed = 0
    local skipped = 0

    for _, test in ipairs(self.processedTests) do
        if test.status == "passed" then
            passed = passed + 1
        elseif test.status == "skipped" then
            skipped = skipped + 1
        else
            failed = failed + 1
        end
    end

    print(string.format("✅ Passed: %d", passed))
    print(string.format("⏭️  Skipped: %d", skipped))
    print(string.format("❌ Failed: %d", failed))
    print("================================\n")
end

-- --[[
-- 	Event-Driven Execution Example for plain Lua
-- --]]
-- local function exampleEventLoop()
--     while runner:tick() do
-- 		-- Prevent tight loop
--         os.execute("sleep 0.1")
--     end
-- end

-- exampleEventLoop()

--[[
	Think hook for Garry's Mod
--]]

-- runner:reset()

-- hook.Add("Think", "AsyncTestRunner", function()
-- 	runner:tick()
-- end)

return {
    newTestRunner = newTestRunner,
}