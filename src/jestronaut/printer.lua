--- @class Printer
local Printer = {
  width = 75,
}

--- Gets the indentations.
--- @param describeOrTest DescribeOrTest
--- @return string
function Printer:getIndentations(describeOrTest)
  return string.rep("  ", describeOrTest.indentationLevel)
end

--- Prints the name of the test.
--- @param describeOrTest DescribeOrTest
function Printer:printName(describeOrTest)
  if describeOrTest.isTest then
    print(self:getIndentations(describeOrTest) .. "🧪 " .. describeOrTest.name .. "...")
  else
    print(self:getIndentations(describeOrTest) .. "📦 " .. describeOrTest.name .. "...")
  end

  print(self:getIndentations(describeOrTest) .. "(" .. describeOrTest.filePath .. ":" .. describeOrTest.lineNumber .. ")")
end

--- Prints the result of the test and returns whether it passed.
--- @param describeOrTest DescribeOrTest
--- @param success boolean
--- @param ... any
--- @return boolean
function Printer:printResult(describeOrTest, success, ...)
  if not success then
    print(self:getIndentations(describeOrTest) .. "❌ Failed with error: " .. tostring(...) .. "\n")
    return false
  end
  
  print(self:getIndentations(describeOrTest) .. "✅ Passed\n")
  return true
end

--- Prints the skip message of the test.
--- @param describeOrTest DescribeOrTest
function Printer:printSkip(describeOrTest)
  print(self:getIndentations(describeOrTest) .. "🚫 Skipped\n")
end

--- Prints text centered, using the printer width.
--- @param text string
function Printer:printCentered(text)
  local textLength = text:len()
  local leftPadding = math.floor((self.width - textLength) * .5)
  local rightPadding = self.width - textLength - leftPadding

  print(((" "):rep(leftPadding)) .. text .. (" "):rep(rightPadding))
end

--- Creates a horizontal line using the printer width.
--- @param char string
function Printer:printHorizontalLine(char)
  char = char or "─"

  print(char:rep(self.width))
end

--- Creates some space by printing a new line.
--- @param count number
function Printer:printNewline(count)
  count = count or 1

  for i = 1, count do
    print()
  end
end

--- Prints the start message of the test.
--- @param rootDescribe Describe
function Printer:printStart(rootDescribe)
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
function Printer:printEnd(duration)
  local endTime = os.date("%X")
  self:printNewline()
  self:printCentered("🏁 Finished tests at " .. endTime .. " in " .. duration .. " seconds.")
  self:printNewline()
end

--- Prints the success message of the test.
--- @param rootDescribe Describe
--- @param failedTestCount number
--- @param skippedTestCount number
function Printer:printSuccess(rootDescribe, failedTestCount, skippedTestCount)
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
function Printer:printProgress(relativeSuccess)
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
function Printer:printFailFast(describeOrTest)
  self:printCentered("🚨 Fail fast triggered by " .. describeOrTest.name .. ".")
end

return {
  Printer = Printer,
}