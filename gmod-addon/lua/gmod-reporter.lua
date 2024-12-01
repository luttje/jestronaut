local split = require "jestronaut/utils/strings".split
local styledText = require "jestronaut/utils/styledtexts"
local originalPrint = print

local STYLING_DISABLED = true

--- @class Reporter
local GmodReporter = {
  isVerbose = false,

  width = 75,
}

--- Gets the indentations.
--- @param describeOrTest DescribeOrTest
--- @return string
local function getIndentations(describeOrTest)
  return string.rep("  ", describeOrTest.indentationLevel)
end

--- Ensures the text is always the given amount of characters long.
--- Truncates the text if it's too long, or pads it with spaces if it's too short.
--- @param text string
--- @param length number
--- @return string
local function ensureLength(text, length)
  if text:len() > length then
    return text:sub(1, length)
  end

  return text .. (" "):rep(length - text:len())
end

--- @param filePath string
function GmodReporter:getFileByPath(filePath)
  for _, file in ipairs(self.describesByFilePath) do
    if filePath == file.filePath then
      return file
    end
  end
end

local function drawDescribeOrTest(describeOrTest)
  local summary = styledText.new(nil, STYLING_DISABLED)

  summary:plain(getIndentations(describeOrTest))

  if describeOrTest.hasRun then
    if describeOrTest.success then
      summary:colored("✓", styledText.foregroundColors.green)
    else
      summary:colored("✗", styledText.foregroundColors.red)
    end
  elseif describeOrTest.toSkip then
    summary:colored("⚠", styledText.foregroundColors.blue)
  else
    summary:colored("o", styledText.foregroundColors.yellow)
  end

  summary:plain(" " .. describeOrTest.name .. "\n")
  
  if (describeOrTest.isRunning and describeOrTest.children) then
    for _, describeOrTest in ipairs(describeOrTest.children) do
      if describeOrTest.isDescribe then
        summary:plain(drawDescribeOrTest(describeOrTest))
      else
        summary:plain(getIndentations(describeOrTest))

        if describeOrTest.hasRun then
          if describeOrTest.success then
            summary:colored("✓", styledText.foregroundColors.green)
          else
            summary:colored("✗", styledText.foregroundColors.red)
          end
        elseif describeOrTest.toSkip then
          summary:colored("⚠", styledText.foregroundColors.blue)
        else
          summary:colored("o", styledText.foregroundColors.yellow)
        end

        summary:plain(" " .. describeOrTest.name .. "\n")

        if (describeOrTest.hasRun and not describeOrTest.success) then
          summary:plain(table.concat(describeOrTest.errors) .. "\n\n")
        end
      end
    end
  elseif (describeOrTest.hasRun and not describeOrTest.success) then
    summary:plain(table.concat(describeOrTest.errors) .. "\n\n")
  end

  return tostring(summary)
end

--- Prints the name of the test.
--- @param describeOrTest DescribeOrTest
function GmodReporter:testStarting(describeOrTest)
  -- Override print so there's no interference with the test output.
  print = function() end -- TODO: Store the print and output it at the end of the test.

  local file = self:getFileByPath(describeOrTest.filePath)

  if file then
    file.isRunning = true
  end

  local summary = styledText.new(nil, STYLING_DISABLED)
      :plain(drawDescribeOrTest(describeOrTest))
    
  originalPrint(ensureLength("STARTED:", 10) .. tostring(summary))
end

--- Prints the result of the test and returns whether it passed.
--- @param describeOrTest DescribeOrTest
--- @param success boolean
--- @param ... any
--- @return boolean
function GmodReporter:testFinished(describeOrTest, success, ...)
  print = originalPrint

  local file = self:getFileByPath(describeOrTest.filePath)

  if file then
    if not self.lastFile then
      self.lastFile = file
    elseif self.lastFile ~= file then
      self.lastFile.isRunning = false
      self.lastFile.hasRun = true
      self.lastFile.success = true -- TODO: Check if all tests passed.

      self.lastFile = file
    end
    
    file.isRunning = true
    
    if not success then
      file.hasRun = true
      file.success = false
    end
  end

  local summary = styledText.new(nil, STYLING_DISABLED)
      :plain(drawDescribeOrTest(describeOrTest))
    
  originalPrint(ensureLength("FINISHED:", 10) .. tostring(summary))
end

--- Prints the skip message of the test.
--- @param describeOrTest DescribeOrTest
function GmodReporter:testSkipped(describeOrTest)
  local file = self:getFileByPath(describeOrTest.filePath)

  if file then
    file.skippedCount = file.skippedCount + 1
  end

  local summary = styledText.new(nil, STYLING_DISABLED)
      :plain(drawDescribeOrTest(describeOrTest))
    
  originalPrint(ensureLength("SKIPPED:", 10) .. tostring(summary))
end

--- Prints the retry message of the test.
--- @param describeOrTest DescribeOrTest
--- @param retryCount number
function GmodReporter:testRetrying(describeOrTest, retryCount)
  self:redrawSummary(self.isVerbose)
end

--- Prints text centered, using the reporter width.
--- @param text string
function GmodReporter:printCentered(text)
  local textLength = text:len()
  local leftPadding = math.floor((self.width - textLength) * .5)
  local rightPadding = self.width - textLength - leftPadding

  originalPrint(((" "):rep(leftPadding)) .. text .. (" "):rep(rightPadding))
end

--- Creates a horizontal line using the reporter width.
--- @param char string
function GmodReporter:printHorizontalLine(char)
  char = char or "─"

  originalPrint(char:rep(self.width))
end

--- Creates some space by printing a new line.
--- @param count? number
function GmodReporter:printNewline(count)
  count = count or 1

  for i = 1, count do
    originalPrint()
  end
end

--- Stores the tests that will be run and prints the summary with header.
--- @param rootDescribe Describe
--- @param describesByFilePath table
function GmodReporter:startTestSet(rootDescribe, describesByFilePath)
  local totalTestCount = rootDescribe.childCount + rootDescribe.grandChildrenCount

  self.summaryHeader = styledText.new(nil, STYLING_DISABLED)
    :plain("🚀 Starting ")
    :colored(tostring(totalTestCount), styledText.foregroundColors.yellow)
    :plain(" tests at ")
    :colored(os.date("%X"), styledText.foregroundColors.yellow)
    :plain("...\n\n")

  self.describesByFilePath = describesByFilePath
  
  originalPrint(tostring(self.summaryHeader))
end

--- Prints the success message of the test.
--- @param rootDescribe Describe
--- @param failedTestCount number
--- @param skippedTestCount number
--- @param duration number
function GmodReporter:printEnd(rootDescribe, failedTestCount, skippedTestCount, duration)
  local totalTestCount = rootDescribe.childCount + rootDescribe.grandChildrenCount
  local notRunCount = failedTestCount + skippedTestCount
  local relativeSuccess = 1 - (notRunCount / totalTestCount)

  if self.lastFile then
    self.lastFile.isRunning = false
    self.lastFile.hasRun = true
    self.lastFile.success = true -- TODO: Check if all tests passed?
  end
  
  self:printNewline()

  if(relativeSuccess == 1) then
    self:printCentered("🎉 All tests passed. Great job!")
    self:printNewline()
  end

  local testResults = styledText.new(nil, STYLING_DISABLED)
    :colored("Tests:       ", styledText.foregroundColors.white)

  if failedTestCount > 0 then
    testResults = testResults
      :colored(failedTestCount .. " failed", styledText.foregroundColors.black, styledText.backgroundColors.red)
      :plain(", ")
  end

  if skippedTestCount > 0 then
    testResults = testResults
      :colored(skippedTestCount .. " skipped", styledText.foregroundColors.blue)
      :plain(", ")
  end

  testResults = testResults
    :colored((totalTestCount - notRunCount) .. " passed", styledText.foregroundColors.green)
    :plain(", " .. totalTestCount .. " total")

  originalPrint(testResults)

  originalPrint(
    styledText.new(nil, STYLING_DISABLED)
      :plain("Time:        " .. duration .. "s")
  )
  
  self:printNewline()

  originalPrint(
    styledText.new(nil, STYLING_DISABLED)
      :styled("Ran all test suites.", styledText.styles.dim)
  )

  local todos = {}

  -- Find which files have describesOrTests that are marked isTodo
  local function findTodos(file, describesOrTests)
    for _, describeOrTest in pairs(describesOrTests) do
      if describeOrTest.children then
        findTodos(file, describeOrTest.children)
      elseif describeOrTest.isTodo then
        table.insert(todos, describeOrTest)
      end
    end
  end
  
  for _, file in ipairs(self.describesByFilePath) do
    findTodos(file, file.describesOrTests)
  end

  if #todos > 0 then
    for _, describeOrTest in ipairs(todos) do
      originalPrint(
        styledText.new(nil, STYLING_DISABLED)
          :newline()
          :colored(" TODO ", styledText.foregroundColors.black, styledText.backgroundColors.yellow)
          :plain(" " .. describeOrTest.name)
          :styled(" (in file: " .. describeOrTest.filePath .. ")", styledText.styles.dim)
      )
    end
  end
end

--- Prints the bail message of the test.
--- @param rootDescribe Describe
--- @param bailError string
function GmodReporter:printBailed(rootDescribe, bailError)
  self:printNewline(2)
  self:printCentered("🚨 Bailed out of tests!")
  self:printNewline(2)
  self:printHorizontalLine()
  self:printNewline(2)
end

--- Prints the progress of the test.
--- @param relativeSuccess number
function GmodReporter:printProgress(relativeSuccess)
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

return {
  GmodReporter = GmodReporter,
}