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

  --- Runs the test and returns the amount of successful tests.
  --- @param self DescribeOrTest
  --- @param printer Printer
  --- @param failFast boolean
  --- @return number
  run = function(self, printer, failFast)
    local successfulTestCount = 0

    if self.isSkipping then
      printer:printSkip(self)
      return
    end

    if self.isTest then
      if stateLib.getIsExecutingTests() then
        local success = printer:printResult(self, xpcall(self.fn, function(err)
          return debug.traceback(err, 2)
        end))

        if success then
          successfulTestCount = successfulTestCount + 1
        elseif failFast then
          error("")
        end
      else
        printer:printSkip(self)
        return
      end
    elseif #self.children > 0 then
      for _, child in pairs(self.children) do
        printer:printName(child)
        successfulTestCount = successfulTestCount + child:run(printer, failFast)
      end
    end

    if self.isOnly then
      stateLib.setIsExecutingTests(false)
    end

    return successfulTestCount
  end,
}

DESCRIBE_OR_TEST_META.__index = DESCRIBE_OR_TEST_META

return {
  DESCRIBE_OR_TEST_META = DESCRIBE_OR_TEST_META,
}