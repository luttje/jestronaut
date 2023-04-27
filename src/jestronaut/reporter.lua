local split = require "jestronaut.utils.strings".split
local styledText = require "jestronaut.utils.styledtexts"
local originalPrint = print

--- @class Reporter
local DefaultReporter = {
  isVerbose = false,

  width = 75,
}

--- Gets the indentations.
--- @param describeOrTest DescribeOrTest
--- @return string
local function getIndentations(describeOrTest)
  return string.rep("  ", describeOrTest.indentationLevel)
end

--- @param filePath string
function DefaultReporter:getFileByPath(filePath)
  for _, file in ipairs(self.describesByFilePath) do
    if filePath == file.filePath then
      return file
    end
  end
end

local function drawDescribeOrTest(describeOrTest)
  local summary = styledText.new()

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

--- Gets the summary text and the amount of lines it takes up.
--- @param header styledText
--- @param describesByFilePath table
--- @param verbose boolean
--- @return string, number
local function getSummary(header, describesByFilePath, verbose)
  local summary = styledText.new(header)

  verbose = verbose == nil and false or verbose

  for _, file in ipairs(describesByFilePath) do
    local filePathForShowing = " " .. file.filePath .. "\n"
    local describesOrTests = file.describesOrTests

    if file.hasRun then
      if file.success then
        summary:colored(" PASS ", styledText.foregroundColors.black, styledText.backgroundColors.green)
      else
        summary:colored(" FAIL ", styledText.foregroundColors.black, styledText.backgroundColors.red)
      end

      summary:plain(filePathForShowing)

      if not file.success then
        for _, describeOrTest in ipairs(describesOrTests) do
          if not describeOrTest.success then
            summary:plain(drawDescribeOrTest(describeOrTest))
          end
        end
      end
    elseif file.skippedCount == #describesOrTests then
      summary:colored(" SKIP ", styledText.foregroundColors.black, styledText.backgroundColors.blue)
      summary:plain(filePathForShowing)
    else
      summary:colored(" RUNS ", styledText.foregroundColors.black, styledText.backgroundColors.yellow)
      summary:plain(filePathForShowing)
      
      if verbose and file.isRunning then
        for _, describeOrTest in ipairs(describesOrTests) do
          summary:plain(drawDescribeOrTest(describeOrTest))
        end
      end
    end
  end

  return tostring(summary), summary:getLineCount()
end

--- Redraws the summary lines, clearing the previous ones.
--- @param verbose boolean
function DefaultReporter:redrawSummary(verbose)
  local summary, lineCount = getSummary(self.summaryHeader, self.describesByFilePath, verbose)
  local summaryText = tostring(summary)

  if self.lastPrintEraseCount then
    -- Remove all the previous lines and print the new summary.
    local clearLines = styledText.new()
      :erase(styledText.eraseCodes.eraseCursorToEndOfLine)
      :cursor(styledText.cursorCodes.moveUpLines, 1)
      :rep(self.lastPrintEraseCount + 2) -- The two is to add two newlines caused by the two prints below

    originalPrint(clearLines) -- 1
  end
  self.lastPrintEraseCount = lineCount

  originalPrint(summaryText) -- 2
end

--- Prints the name of the test.
--- @param describeOrTest DescribeOrTest
function DefaultReporter:testStarting(describeOrTest)
  -- Override print so there's no interference with the test output.
  print = function() end -- TODO: Store the print and output it at the end of the test.

  local file = self:getFileByPath(describeOrTest.filePath)

  if file then
    file.isRunning = true
  end

  self:redrawSummary(self.isVerbose)
  return
end

--- Prints the result of the test and returns whether it passed.
--- @param describeOrTest DescribeOrTest
--- @param success boolean
--- @param ... any
--- @return boolean
function DefaultReporter:testFinished(describeOrTest, success, ...)
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

  self:redrawSummary(self.isVerbose)
end

--- Prints the skip message of the test.
--- @param describeOrTest DescribeOrTest
function DefaultReporter:testSkipped(describeOrTest)
  local file = self:getFileByPath(describeOrTest.filePath)

  if file then
    file.skippedCount = file.skippedCount + 1
  end

  self:redrawSummary(self.isVerbose)

  return
end

--- Prints the retry message of the test.
--- @param describeOrTest DescribeOrTest
--- @param retryCount number
function DefaultReporter:testRetrying(describeOrTest, retryCount)
  self:redrawSummary(self.isVerbose)
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

--- Stores the tests that will be run and prints the summary with header.
--- @param rootDescribe Describe
--- @param describesByFilePath table
function DefaultReporter:startTestSet(rootDescribe, describesByFilePath)
  local totalTestCount = rootDescribe.childCount + rootDescribe.grandChildrenCount

  self.summaryHeader = styledText.new()
    :plain("🚀 Starting ")
    :colored(tostring(totalTestCount), styledText.foregroundColors.yellow)
    :plain(" tests at ")
    :colored(os.date("%X"), styledText.foregroundColors.yellow)
    :plain("...\n\n")

  self.describesByFilePath = describesByFilePath
  self:redrawSummary()
end

--- Prints the success message of the test.
--- @param rootDescribe Describe
--- @param failedTestCount number
--- @param skippedTestCount number
--- @param duration number
function DefaultReporter:printEnd(rootDescribe, failedTestCount, skippedTestCount, duration)
  local totalTestCount = rootDescribe.childCount + rootDescribe.grandChildrenCount
  local notRunCount = failedTestCount + skippedTestCount
  local relativeSuccess = 1 - (notRunCount / totalTestCount)

  if self.lastFile then
    self.lastFile.isRunning = false
    self.lastFile.hasRun = true
    self.lastFile.success = true -- TODO: Check if all tests passed?
  end

  self:redrawSummary()
  self:printNewline()

  if(relativeSuccess == 1) then
    self:printCentered("🎉 All tests passed. Great job!")
    self:printNewline()
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
      :colored(skippedTestCount .. " skipped", styledText.foregroundColors.blue)
      :plain(", ")
  end

  testResults = testResults
    :colored((totalTestCount - notRunCount) .. " passed", styledText.foregroundColors.green)
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
        styledText.new()
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
function DefaultReporter:printBailed(rootDescribe, bailError)
  self:printNewline(2)
  self:printCentered("🚨 Bailed out of tests!")
  self:printNewline(2)
  self:printHorizontalLine()
  self:printNewline(2)
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

return {
  DefaultReporter = DefaultReporter,
}