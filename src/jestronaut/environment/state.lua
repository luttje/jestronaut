local functionLib = require "jestronaut.utils.functions"
local stringsLib = require "jestronaut.utils.strings"

local rootFilePaths

--- @class DescribeOrTest
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

--- @type DescribeOrTest[]
local isExecutingTests = false

--- @type DescribeOrTest
local currentParent = nil

local function getCurrentDescribeOrTest()
  return currentDescribeOrTest
end

--- Sets where Jestronaut should look for tests. This is used to determine the test file path.
--- @param roots string[]
local function setRoots(roots)
  for i, root in ipairs(roots) do
    roots[i] = stringsLib.normalizePath(root)
  end

  rootFilePaths = roots
end

--- Gets the file path and line number of the test by checking the stack trace until it reaches beyond the root of this package.
--- @param test DescribeOrTest
--- @return string, number
local function getTestFilePath(test)
  local filePath, lineNumber
  local i = 1

  while true do
    local info = debug.getinfo(i, "Sl")

    if not info then
      error("Could not find the test file path. Please make sure options.roots is set to the directories where your tests are located.")
      break
    end

    local path = stringsLib.normalizePath(info.source:sub(1, 1) == "@" and info.source:sub(2) or info.source)

    if rootFilePaths ~= nil then
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

--- @param test DescribeOrTest
local function getIsExecutingTests(test)
  local fileLocalState = getTestLocalState(test.filePath)
  if test and fileLocalState.notExecuting and fileLocalState.notExecuting ~= test and fileLocalState.notExecuting ~= test.parent then
    return false
  end

  return isExecutingTests
end

local function setIsExecutingTests(executing)
  isExecutingTests = executing
end

--- @param test DescribeOrTest
local function setNotExecuteTestsOtherThan(test)
  local fileLocalState = getTestLocalState(test.filePath)
  fileLocalState.notExecuting = test
end

--- Sets the amount of times tests will be retried. Must be called at the top of a file or describe block.
--- @param numRetries number
--- @param options table
local function retryTimes(numRetries, options)
  local filePath, lineNumber = getTestFilePath(currentDescribeOrTest)
  local testLocalState = getTestLocalState(filePath)

  if currentDescribeOrTest and currentDescribeOrTest.isTest then
    error("Cannot set the test retries outside of a file or describe block", 2)
  end

  testLocalState.retrySettings = {
    timesRemaining = numRetries,
    options = options or {},
  }
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

  if not success then
    return
  end

  if describeOrTest.expectedAssertionCount ~= nil and describeOrTest.expectedAssertionCount ~= describeOrTest.assertionCount then
    error("Expected " .. describeOrTest.expectedAssertionCount .. " assertions, but " .. describeOrTest.assertionCount .. " were run")
  end

  if describeOrTest.expectAssertion and describeOrTest.assertionCount == 0 then
    error("Expected at least one assertion to be run, but none were run")
  end
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
  indentationLevel = 0,
  name = "",
  fn = function() end,
  isOnly = false,
  isSkipped = false,

  assertionCount = 0,
  parent = nil,
  childCount = 0,
  grandChildrenCount = 0,

  --- Adds a child describe or test.
  --- @param child DescribeOrTest
  addChild = function(self, child)
    self.childCount = self.childCount + 1

    self.children[self.childCount] = child
    self.childrenLookup[child.name] = self.childCount

    child.parent = self

    if self.parent then
      self.parent.grandChildrenCount = self.parent.grandChildrenCount + 1
    end
  end,

  --- Runs the test and returns the amount of failed and skippewd tests.
  --- @param self DescribeOrTest
  --- @param printer Printer
  --- @param runnerOptions RunnerOptions
  --- @return number
  run = function(self, printer, runnerOptions)
    local failedTestCount = 0
    local skippedTestCount = 0

    if self.isSkipped then
      printer:printSkip(self)

      return failedTestCount, skippedTestCount + 1
    end

    if not getIsExecutingTests(self) then
      printer:printSkip(self)
      return failedTestCount, skippedTestCount + 1
    end

    if self.isTest then
      if runnerOptions.testPathIgnorePatterns then
        for _, pattern in ipairs(runnerOptions.testPathIgnorePatterns) do
          local plain = not pattern:find("^/.*/$") -- Only enable pattern matching if the pattern doesn't start and end with a slash
          pattern = plain and pattern or pattern:sub(2, -2) -- Remove the slashes if pattern matching is enabled
          
          if self.filePath:find(pattern, nil, plain) then
            printer:printSkip(self)
            return failedTestCount, skippedTestCount + 1
          end
        end
      elseif runnerOptions.testNamePattern then
        if not self.name:find(runnerOptions.testNamePattern) then
          printer:printSkip(self)
          return failedTestCount, skippedTestCount + 1
        end
      end

      local testLocalState = getTestLocalState(self.filePath)
      local retrySettings = testLocalState.retrySettings

      beforeDescribeOrTest(self)

      local success, results = functionLib.captureSafeCallInTable(xpcall(self.fn, function(err)
        return debug.traceback(err, 2)
      end))

      if self.expectFail == true then
        if success then
          success = false
          results = {"Expected test to fail, but it succeeded"}
        else
          success = true
        end
      end

      afterDescribeOrTest(self, success)

      if (success or (not retrySettings or retrySettings.options.logErrorsBeforeRetry)) then
        printer:printTestResult(self, success, unpack(results))
      end

      if not success then
        failedTestCount = failedTestCount + 1

        if retrySettings and retrySettings.timesRemaining then
          if retrySettings.timesRemaining > 0 then
            retrySettings.timesRemaining = retrySettings.timesRemaining - 1

            printer:printRetry(self, retrySettings.timesRemaining + 1)

            return self:run(printer, runnerOptions)
          end
        end

        if runnerOptions.bail ~= nil and failedTestCount >= runnerOptions.bail then
          error("Bail after " .. failedTestCount .. " failed " .. (failedTestCount == 1 and "test" or "tests") .. " with error: \n" .. tostring(results[1]))
        end
      end
    elseif #self.children > 0 then
      for _, child in pairs(self.children) do
        printer:printName(child)
        local childFailedCount, childSkippedCount = child:run(printer, runnerOptions)

        failedTestCount = failedTestCount + childFailedCount
        skippedTestCount = skippedTestCount + childSkippedCount
      end
    end

    if self.isOnly then
      setNotExecuteTestsOtherThan(self)
    end

    return failedTestCount, skippedTestCount
  end,
}

DESCRIBE_OR_TEST_META.__index = DESCRIBE_OR_TEST_META

--- Registers a Describe or Test to be run.
--- Must be called once befrore all others with a Describe to set as root.
--- @param describeOrTest DescribeOrTest
local function registerDescribeOrTest(describeOrTest)
  local filePath, lineNumber = getTestFilePath(describeOrTest)
  
  describeOrTest.filePath = filePath
  describeOrTest.lineNumber = lineNumber

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

--- Registers the tests
--- @param testRegistrar function
local function registerTests(testRegistrar)
  if not rootFilePaths then
    error("No root directory paths have been set. Configure options.roots using jestronaut:config(options) before registering tests.")
  end
  
  testRegistrar()
end

--- Runs all registered tests.
--- @param runnerOptions RunnerOptions
local function runTests(runnerOptions)
  local printer = runnerOptions.printer or (require "jestronaut.printer".DefaultPrinter)

  local startTime = os.clock()
  setIsExecutingTests(true)

  printer:printStart(currentParent)

  local success, errOrFailedTestCount, skippedTestCount = pcall(currentParent.run, currentParent, printer, runnerOptions)

  local endTime = os.clock()
  printer:printEnd(endTime - startTime)

  if not success then
    if not errOrFailedTestCount:find("^Bail after") then
      -- TODO: Use xpcall as to not lose the stack trace
      error(errOrFailedTestCount)
    end

    printer:printFailFast(currentParent)
  else
    printer:printSuccess(currentParent, errOrFailedTestCount, skippedTestCount)
  end

  setIsExecutingTests(false)
end

return {
  DESCRIBE_OR_TEST_META = DESCRIBE_OR_TEST_META,
  getCurrentDescribeOrTest = getCurrentDescribeOrTest,

  registerDescribeOrTest = registerDescribeOrTest,
  setRoots = setRoots,
  registerTests = registerTests,
  runTests = runTests,

  getIsExecutingTests = getIsExecutingTests,
  setIsExecutingTests = setIsExecutingTests,

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