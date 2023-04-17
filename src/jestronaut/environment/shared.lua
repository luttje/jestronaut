local stateLib = require "jestronaut.environment.state"

--- @class DescribeOrTest
local DESCRIBE_OR_TEST_META = {
  indentationLevel = 0,
  name = "",
  fn = function() end,
  isOnly = false,
  isSkipping = false,

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

  --- Runs the test and returns the amount of failed tests.
  --- @param self DescribeOrTest
  --- @param printer Printer
  --- @param runnerOptions RunnerOptions
  --- @return number
  run = function(self, printer, runnerOptions)
    local failedTestCount = 0

    if self.isSkipping then
      printer:printSkip(self)
      return failedTestCount
    end

    if self.isTest then
      if stateLib.getIsExecutingTests() then
        if runnerOptions.testPathIgnorePatterns then
          for _, pattern in pairs(runnerOptions.testPathIgnorePatterns) do
            if self.name:find(pattern) then
              printer:printSkip(self)
              return failedTestCount
            end
          end
        elseif runnerOptions.testNamePattern then
          if not self.name:find(runnerOptions.testNamePattern) then
            printer:printSkip(self)
            return failedTestCount
          end
        end

        local success = printer:printResult(self, xpcall(self.fn, function(err)
          return debug.traceback(err, 2)
        end))

        if not success then
          failedTestCount = failedTestCount + 1

          if runnerOptions.bail ~= nil and failedTestCount >= runnerOptions.bail then
            error("Bail after " .. failedTestCount .. " failed " .. (failedTestCount == 1 and "test" or "tests"))
          end
        end
      else
        printer:printSkip(self)
        return failedTestCount
      end
    elseif #self.children > 0 then
      for _, child in pairs(self.children) do
        printer:printName(child)
        failedTestCount = failedTestCount + child:run(printer, runnerOptions)
      end
    end

    if self.isOnly then
      stateLib.setIsExecutingTests(false)
    end

    return failedTestCount
  end,
}

DESCRIBE_OR_TEST_META.__index = DESCRIBE_OR_TEST_META

return {
  DESCRIBE_OR_TEST_META = DESCRIBE_OR_TEST_META,
}