--- @type DescribeOrTest[]
local isExecutingTests = false

--- @type DescribeOrTest
local currentParent = nil

local function getIsExecutingTests()
  return isExecutingTests
end

local function setIsExecutingTests(executing)
  isExecutingTests = executing
end

--- Registers a Describe or Test to be run.
--- Must be called once befrore all others with a Describe to set as root.
--- @param describeOrTest DescribeOrTest
local function registerDescribeOrTest(describeOrTest)
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

--- Runs all registered tests.
--- @param printer Printer
--- @param failFast boolean
local function runTests(printer, failFast)
  local startTime = os.clock()
  setIsExecutingTests(true)

  printer:printStart(currentParent)

  local success, err = pcall(currentParent.run, currentParent, printer, failFast)

  if not success then
    printer:printFailFast(currentParent)
  end

  local endTime = os.clock()
  printer:printEnd(endTime - startTime)

  setIsExecutingTests(false)
end

return {
  registerDescribeOrTest = registerDescribeOrTest,
  runTests = runTests,

  getIsExecutingTests = getIsExecutingTests,
  setIsExecutingTests = setIsExecutingTests,
}