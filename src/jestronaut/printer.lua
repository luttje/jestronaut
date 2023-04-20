local split = require "jestronaut.utils.strings".split
local styledText = require "jestronaut.utils.styledtexts"

--- @class Printer
local DefaultPrinter = {
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

--- Prints the name of the test.
--- @param describeOrTest DescribeOrTest
function DefaultPrinter:printName(describeOrTest)
  if describeOrTest.isTest then
    print(getIndentations(describeOrTest) .. "🧪 " .. describeOrTest.name .. "...")
  else
    print(getIndentations(describeOrTest) .. "📦 " .. describeOrTest.name .. "...")
  end

  print(getIndentations(describeOrTest) .. "(" .. describeOrTest.filePath .. ":" .. describeOrTest.lineNumber .. ")")
end

--- Prints the result of the test and returns whether it passed.
--- @param describeOrTest DescribeOrTest
--- @param success boolean
--- @param ... any
--- @return boolean
function DefaultPrinter:printTestResult(describeOrTest, success, ...)
  if not success then
    print(
      styledText.new()
        :plain(getIndentations(describeOrTest))
        :colored(" FAIL ", styledText.foregroundColors.black, styledText.backgroundColors.red)
        :plain("\n\t• Test suite failed to run\n\n")
        :plain(prefixLines(tostring(...), "\t\t"))
    )
    return false
  end
  
  print(
    styledText.new()
      :plain(getIndentations(describeOrTest))
      :colored(" PASS ", styledText.foregroundColors.black, styledText.backgroundColors.green)
      :plain("\n")
  )
  return true
end

--- Prints the skip message of the test.
--- @param describeOrTest DescribeOrTest
function DefaultPrinter:printSkip(describeOrTest)
  print(
    styledText.new()
      :plain(getIndentations(describeOrTest))
      :colored(" SKIP ", styledText.foregroundColors.black, styledText.backgroundColors.yellow)
      :plain("\n")
  )
end

--- Prints the retry message of the test.
--- @param describeOrTest DescribeOrTest
--- @param retryCount number
function DefaultPrinter:printRetry(describeOrTest, retryCount)
  print(
    styledText.new()
      :plain(getIndentations(describeOrTest))
      :colored(" RETRY ", styledText.foregroundColors.black, styledText.backgroundColors.yellow)
      :plain("\n")
  )
end

--- Prints text centered, using the printer width.
--- @param text string
function DefaultPrinter:printCentered(text)
  local textLength = text:len()
  local leftPadding = math.floor((self.width - textLength) * .5)
  local rightPadding = self.width - textLength - leftPadding

  print(((" "):rep(leftPadding)) .. text .. (" "):rep(rightPadding))
end

--- Creates a horizontal line using the printer width.
--- @param char string
function DefaultPrinter:printHorizontalLine(char)
  char = char or "─"

  print(char:rep(self.width))
end

--- Creates some space by printing a new line.
--- @param count number
function DefaultPrinter:printNewline(count)
  count = count or 1

  for i = 1, count do
    print()
  end
end

--- Prints the start message of the test.
--- @param rootDescribe Describe
function DefaultPrinter:printStart(rootDescribe)
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
function DefaultPrinter:printSummary(rootDescribe, failedTestCount, skippedTestCount, duration)
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

  print(testResults)

  print(
    styledText.new()
      :plain("Time:        " .. duration .. "s")
  )
  print(
    styledText.new()
      :styled("Ran all test suites.", styledText.styles.dim)
  )
end

--- Prints the progress of the test.
--- @param relativeSuccess number
function DefaultPrinter:printProgress(relativeSuccess)
  local suffix = math.floor(relativeSuccess * 100) .. "% of tests succeeded"
  
  local progressBar = "["
  local progressBarLength = self.width - suffix:len() - 3
  local progressBarSuccessLength = math.floor(progressBarLength * relativeSuccess)
  local progressBarFailLength = progressBarLength - progressBarSuccessLength

  progressBar = progressBar .. string.rep("#", progressBarSuccessLength)
  progressBar = progressBar .. string.rep(" ", progressBarFailLength)
  progressBar = progressBar .. "]"

  self:printHorizontalLine()
  print(progressBar .. " " .. suffix)
  self:printHorizontalLine()
end

--- Prints the fail fast message of the test.
--- @param describeOrTest DescribeOrTest
function DefaultPrinter:printFailFast(describeOrTest)
  self:printCentered("🚨 Fail fast triggered by " .. describeOrTest.name .. ".")
end

return {
  DefaultPrinter = DefaultPrinter,
}