local split = require "jestronaut.utils.strings".split

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
    print(getIndentations(describeOrTest) .. "\27[30;41m FAIL \27[m\n\t• Test suite failed to run\n\n" .. prefixLines(tostring(...), "\t\t") .. "\n")
    return false
  end
  
  print(getIndentations(describeOrTest) .. "\27[30;42m PASS \27[m\n")
  return true
end

--- Prints the skip message of the test.
--- @param describeOrTest DescribeOrTest
function DefaultPrinter:printSkip(describeOrTest)
  print(getIndentations(describeOrTest) .. "🚫 Skipped\n")
end

--- Prints the retry message of the test.
--- @param describeOrTest DescribeOrTest
--- @param retryCount number
function DefaultPrinter:printRetry(describeOrTest, retryCount)
  print(getIndentations(describeOrTest) .. "🔁 Retrying (" .. retryCount .. ")...\n")
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

--- Prints the end message of the test.
--- @param duration number
function DefaultPrinter:printEnd(duration)
  local endTime = os.date("%X")
  self:printNewline()
  self:printCentered("🏁 Finished tests at " .. endTime .. " in " .. duration .. " seconds.")
  self:printNewline()
end

--- Prints the success message of the test.
--- @param rootDescribe Describe
--- @param failedTestCount number
--- @param skippedTestCount number
function DefaultPrinter:printSuccess(rootDescribe, failedTestCount, skippedTestCount)
  local totalTestCount = rootDescribe.childCount + rootDescribe.grandChildrenCount
  local notRunCount = failedTestCount + skippedTestCount
  local relativeSuccess = 1 - (notRunCount / totalTestCount)

  self:printProgress(relativeSuccess)
  self:printNewline()

  if(relativeSuccess == 1) then
    self:printCentered("🎉 All tests passed. Great job!")
    self:printNewline()
    return
  end

  self:printCentered("✅ " .. (totalTestCount - notRunCount) .. " of " .. totalTestCount .. " tests succeeded.")
  self:printNewline()
  self:printCentered("🚨 " .. failedTestCount .. " tests failed.")
  self:printNewline()
  self:printCentered("🚫 " .. skippedTestCount .. " tests skipped.")
  self:printNewline()
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