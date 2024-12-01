local require = require
local extendMetaTableIndex = require "jestronaut/utils/metatables".extendMetaTableIndex
local functionLib = require "jestronaut/utils/functions"
local stringsLib = require "jestronaut/utils/strings"

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

    if (not info) then
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

--- Runs the test and returns the amount of failed tests.
--- @param reporter Reporter
--- @param runnerOptions RunnerOptions
--- @return number
function DESCRIBE_OR_TEST_META:run(reporter, runnerOptions)
  local failedTestCount = 0

  if self.toSkip then
    reporter:testSkipped(self)

    return failedTestCount
  end

  if(runnerOptions.slowDown) then -- For debugging terminal output
    local slowDown = runnerOptions.slowDown * 0.001
    
    local startTime = os.clock()
    local endTime = startTime + slowDown

    -- Start a loop to freeze for the specified amount of milliseconds
    while os.clock() < endTime do end
  end
  
  reporter:testStarting(self)
  self.isRunning = true

  if self.isTest then
    local testLocalState = getTestLocalState(self.filePath)
    local retrySettings = testLocalState.retrySettings

    beforeDescribeOrTest(self)

    local success, results = functionLib.captureSafeCallInTable(xpcall(self.fn, function(err)
      return debug.traceback(err, 2)
    end))

    if self.expectFail == true then
      if success then
        success = false
        results = {"Error! Expected test to fail, but it succeeded."}
      else
        success = true
      end
    end

    afterDescribeOrTest(self, success)

    self.success = success
    self.isRunning = false
    self.hasRun = true

    if not success then
      self.errors = results
    end

    if (success or (not retrySettings or retrySettings.options.logErrorsBeforeRetry)) then
      reporter:testFinished(self, success, unpack(results))
    end

    if not success then
      failedTestCount = failedTestCount + 1

      if retrySettings and retrySettings.timesRemaining then
        if retrySettings.timesRemaining > 0 then
          retrySettings.timesRemaining = retrySettings.timesRemaining - 1

          reporter:testRetrying(self, retrySettings.timesRemaining + 1)

          return self:run(reporter, runnerOptions)
        end
      end

      if runnerOptions.bail ~= nil and failedTestCount >= runnerOptions.bail then
        reporter:testFinished(self, success, unpack(results))

        error("Bail after " .. failedTestCount .. " failed " .. (failedTestCount == 1 and "test" or "tests") .. " with error: \n" .. tostring(results[1]))
      end
    end
  else
    if #self.children > 0 then
      self.isRunning = true

      for _, child in pairs(self.children) do
        local childFailedCount = child:run(reporter, runnerOptions)

        failedTestCount = failedTestCount + childFailedCount
      end

      self.isRunning = false
      self.hasRun = true
      self.success = failedTestCount == 0
    end

    reporter:testFinished(self, self.success)
  end

  return failedTestCount
end

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
      local plain = not pattern:find("^/.*/$") -- Only enable pattern matching if the pattern doesn't start and end with a slash
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

--- Recursively copies a Describe or Test to be run, returning the root describe, a table with all describes grouped by file path, and the number of skipped tests.
--- @param describeOrTest DescribeOrTest
--- @param runnerOptions RunnerOptions
--- @return DescribeOrTestForRun, table, number
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
  -- Pass modified require's on through
  local oldRequire = _G.require
  _G.require = require
  local reporter = runnerOptions.reporter or (require "jestronaut/reporter".DefaultReporter)
  _G.require = oldRequire

  reporter.isVerbose = runnerOptions.verbose
  
  -- currentParent is the root describe at this point
  local testSetRoot, describesByFilePath, skippedTestCount = copyDescribeOrTestForRun(currentParent, runnerOptions)

  reporter:startTestSet(testSetRoot, describesByFilePath)

  local startTime = os.clock()
  local success, errOrFailedTestCount = pcall(testSetRoot.run, testSetRoot, reporter, runnerOptions)
  local endTime = os.clock()

  if not success then
    if not errOrFailedTestCount:find("(.*): Bail after") then
      -- TODO: Use xpcall as to not lose the stack trace
      error(errOrFailedTestCount)
    end

    reporter:printBailed(testSetRoot, errOrFailedTestCount)
    return
  end

  reporter:printEnd(testSetRoot, errOrFailedTestCount, skippedTestCount, endTime - startTime)
end

return {
  DESCRIBE_OR_TEST_META = DESCRIBE_OR_TEST_META,
  DESCRIBE_OR_TEST_FOR_RUN_META = DESCRIBE_OR_TEST_FOR_RUN_META,
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