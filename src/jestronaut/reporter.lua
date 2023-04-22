local split = require "jestronaut.utils.strings".split
local styledText = require "jestronaut.utils.styledtexts"
local originalPrint = print

--- @class Reporter
local DefaultReporter = {
  isVerbose = false,

  width = 75,
}

--- Prefixes each line in a string with a prefix.
--- @param string string
--- @param prefix string
--- @return string
local function prefixLines(string, prefix)
  local lines = split(string, "\n")
  local prefixedLines = {}

  for _, line in ipairs(lines) do
    table.insert(prefixedLines, prefix .. line)
  end

  return table.concat(prefixedLines, "\n")
end

--- Gets the indentations.
--- @param describeOrTest DescribeOrTest
--- @return string
local function getIndentations(describeOrTest)
  return string.rep("  ", describeOrTest.indentationLevel)
end

--- Redraws the summary lines, clearing the previous ones.
-- Draws a summary like:
-- PASS ./src/tests/expectAPI/toBeCloseTo.lua
-- RUNS ./src/tests/expectAPI/toBeCloseToYo.lua
--   ✓ toBeCloseTo
--   ✓ toBeCloseToYo
--   o toBeCloseToYoYo
function DefaultReporter:redrawSummary()
  local currentTestDescribes = self.currentTestDescribes or {}
  local currentTests = self.currentTests or {}

  local summary = styledText.new()
  local height = 0

  for _, describe in pairs(currentTestDescribes) do
    local isActiveDescribe = false

    if describe.success then
      summary:colored(" PASS ", styledText.foregroundColors.black, styledText.backgroundColors.green)
    else
      -- summary:colored(" FAIL ", styledText.foregroundColors.black, styledText.backgroundColors.red)
      summary:colored(" RUNS ", styledText.foregroundColors.black, styledText.backgroundColors.yellow)
      isActiveDescribe = true
    end
    summary:plain(" " .. describe.filePath .. "\n")
    height = height + 1

    if isActiveDescribe then
      for _, test in ipairs(currentTests) do
        summary:plain(getIndentations(test))

        if test.success then
          summary:colored("✓", styledText.foregroundColors.green)
        elseif test.isSkipped then
          summary:colored("⚠", styledText.foregroundColors.yellow)
        else
          summary:colored("✗", styledText.foregroundColors.red)
        end

        summary:plain(" " .. test.name .. "\n")
        height = height + 1
      end
    end
  end

  -- Remove all the previous lines (same height) and print the new summary.
  local clearLines = styledText.new()
    :cursor(styledText.cursorCodes.moveUpLines, 1)
    :erase(styledText.eraseCodes.eraseLine)
    
  originalPrint(tostring(clearLines):rep(height) .. tostring(summary))
end


--- Prints the name of the test.
--- @param describeOrTest DescribeOrTest
function DefaultReporter:startingTest(describeOrTest)
  -- Override print so there's no interference with the test output.
  print = function() end -- TODO: Store the print and output it at the end of the test.

  if describeOrTest.isDescribe then
    self.currentTestDescribes = self.currentTestDescribes or {}
    local exists = false

    for _, value in pairs(self.currentTestDescribes) do
      if value.filePath == describeOrTest.filePath then
        exists = true
        break
      end
    end
    
    if not exists then
      self.currentTests = {}
      table.insert(self.currentTestDescribes, describeOrTest)
    end
  else
    self.currentTests = self.currentTests or {}
    table.insert(self.currentTests, describeOrTest)
  end

  if not self.isVerbose then
    self:redrawSummary()
    return
  end

  if describeOrTest.isTest then
    originalPrint(getIndentations(describeOrTest) .. "🧪 " .. describeOrTest.name .. "...")
  else
    originalPrint(getIndentations(describeOrTest) .. "📦 " .. describeOrTest.name .. "...")
  end

  originalPrint(getIndentations(describeOrTest) .. "(" .. describeOrTest.filePath .. ":" .. describeOrTest.lineNumber .. ")")
end

--- Prints the result of the test and returns whether it passed.
--- @param describeOrTest DescribeOrTest
--- @param success boolean
--- @param ... any
--- @return boolean
function DefaultReporter:testFinished(describeOrTest, success, ...)
  print = originalPrint

  if describeOrTest.isDescribe then
    
  end

  if not self.isVerbose then
    self:redrawSummary()

    return
  end
  
  if not success then
    originalPrint(
      styledText.new()
        :plain(getIndentations(describeOrTest))
        :colored(" FAIL ", styledText.foregroundColors.black, styledText.backgroundColors.red)
        :plain("\n\t• Test suite failed to run\n\n")
        :plain(prefixLines(tostring(...), "\t\t"))
    )
    return false
  end
  
  originalPrint(
    styledText.new()
      :plain(getIndentations(describeOrTest))
      :colored(" PASS ", styledText.foregroundColors.black, styledText.backgroundColors.green)
      :plain("\n")
  )
  return true
end

--- Prints the skip message of the test.
--- @param describeOrTest DescribeOrTest
function DefaultReporter:testSkipped(describeOrTest)
  if not self.isVerbose then
    self:redrawSummary()

    return
  end
  
  originalPrint(
    styledText.new()
      :plain(getIndentations(describeOrTest))
      :colored(" SKIP ", styledText.foregroundColors.black, styledText.backgroundColors.yellow)
      :plain("\n")
  )
end

--- Prints the retry message of the test.
--- @param describeOrTest DescribeOrTest
--- @param retryCount number
function DefaultReporter:testRetrying(describeOrTest, retryCount)
  if not self.isVerbose then
    self:redrawSummary()

    return
  end
  
  originalPrint(
    styledText.new()
      :plain(getIndentations(describeOrTest))
      :colored(" RETRY ", styledText.foregroundColors.black, styledText.backgroundColors.yellow)
      :plain("\n")
  )
end

--- Prints text centered, using the reporter width.
--- @param text string
function DefaultReporter:printCentered(text)
  local textLength = text:len()
  local leftPadding = math.floor((self.width - textLength) * .5)
  local rightPadding = self.width - textLength - leftPadding

  originalPrint(((" "):rep(leftPadding)) .. text .. (" "):rep(rightPadding))
end

--- Creates a horizontal line using the reporter width.
--- @param char string
function DefaultReporter:printHorizontalLine(char)
  char = char or "─"

  originalPrint(char:rep(self.width))
end

--- Creates some space by printing a new line.
--- @param count number
function DefaultReporter:printNewline(count)
  count = count or 1

  for i = 1, count do
    originalPrint()
  end
end

--- Prints the start message of the test.
--- @param rootDescribe Describe
function DefaultReporter:printStart(rootDescribe)
  local totalTestCount = rootDescribe.childCount + rootDescribe.grandChildrenCount
  local startTime = os.date("%X")

  self:printNewline(2)
  self:printCentered("🚀 Starting " .. totalTestCount .. " tests at " .. startTime .. "...")
  self:printNewline(2)
  self:printHorizontalLine()
  self:printNewline(2)
end

--- Prints the success message of the test.
--- @param rootDescribe Describe
--- @param failedTestCount number
--- @param skippedTestCount number
--- @param duration number
function DefaultReporter:printSummary(rootDescribe, failedTestCount, skippedTestCount, duration)
  local totalTestCount = rootDescribe.childCount + rootDescribe.grandChildrenCount
  local notRunCount = failedTestCount + skippedTestCount
  local relativeSuccess = 1 - (notRunCount / totalTestCount)

  self:printNewline()

  if(relativeSuccess == 1) then
    self:printCentered("🎉 All tests passed. Great job!")
    self:printNewline()
    return
  end

  local testResults = styledText.new()
    :colored("Tests:       ", styledText.foregroundColors.white)

  if failedTestCount > 0 then
    testResults = testResults
      :colored(failedTestCount .. " failed", styledText.foregroundColors.black, styledText.backgroundColors.red)
      :plain(", ")
  end

  if skippedTestCount > 0 then
    testResults = testResults
      :colored(skippedTestCount .. " skipped", styledText.foregroundColors.black, styledText.backgroundColors.yellow)
      :plain(", ")
  end

  testResults = testResults
    :colored((totalTestCount - notRunCount) .. " passed", styledText.foregroundColors.black, styledText.backgroundColors.green)
    :plain(", " .. totalTestCount .. " total")

  originalPrint(testResults)

  originalPrint(
    styledText.new()
      :plain("Time:        " .. duration .. "s")
  )
  originalPrint(
    styledText.new()
      :styled("Ran all test suites.", styledText.styles.dim)
  )
end

--- Prints the progress of the test.
--- @param relativeSuccess number
function DefaultReporter:printProgress(relativeSuccess)
  local suffix = math.floor(relativeSuccess * 100) .. "% of tests succeeded"
  
  local progressBar = "["
  local progressBarLength = self.width - suffix:len() - 3
  local progressBarSuccessLength = math.floor(progressBarLength * relativeSuccess)
  local progressBarFailLength = progressBarLength - progressBarSuccessLength

  progressBar = progressBar .. string.rep("#", progressBarSuccessLength)
  progressBar = progressBar .. string.rep(" ", progressBarFailLength)
  progressBar = progressBar .. "]"

  self:printHorizontalLine()
  originalPrint(progressBar .. " " .. suffix)
  self:printHorizontalLine()
end

--- Prints the fail fast message of the test.
--- @param describeOrTest DescribeOrTest
function DefaultReporter:printFailFast(describeOrTest)
  self:printCentered("🚨 Fail fast triggered by " .. describeOrTest.name .. ".")
end

return {
  DefaultReporter = DefaultReporter,
}