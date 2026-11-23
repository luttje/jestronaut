local getFullName = require "jestronaut/environment/state".getFullName
local styledText = require "jestronaut/utils/styledtexts"
local originalPrint = print

--- Indents every line of the text.
--- @param text string
--- @param indentation string
--- @return string
local function indent(text, indentation)
    local lines = {}

    for line in (text .. "\n"):gmatch("(.-)\n") do
        table.insert(lines, line ~= "" and (indentation .. line) or "")
    end

    return table.concat(lines, "\n")
end

--- A reporter that prints each test file once, when its tests have finished, followed by a summary. Unlike the
--- default reporter it never redraws earlier output, so it works in CI logs and terminals without ANSI support.
--- @class PlainReporter
local PLAIN_REPORTER = {
    isVerbose = false,
    isSilent = false,
    isColorDisabled = false,
}
PLAIN_REPORTER.__index = PLAIN_REPORTER

function PLAIN_REPORTER:text()
    return styledText.new(nil, self.isColorDisabled)
end

--- Gets the entry that collects results for the file of the describe or test. When the describe or test is from
--- another file than the current entry, the current entry is printed and a new one is started.
--- @param describeOrTest DescribeOrTest
--- @return table
function PLAIN_REPORTER:getFileEntry(describeOrTest)
    local filePath = describeOrTest.filePath

    if self.currentFile and self.currentFile.filePath == filePath then
        return self.currentFile
    end

    self:printCurrentFile()

    self.currentFile = {
        filePath = filePath,
        passed = {},
        failed = {},
        skipped = {},
        withOutput = {},
    }

    return self.currentFile
end

function PLAIN_REPORTER:printCurrentFile()
    local file = self.currentFile

    if not file then
        return
    end

    self.currentFile = nil

    local hasRun = #file.passed + #file.failed > 0
    local header = self:text()

    if #file.failed > 0 then
        header:colored(" FAIL ", styledText.foregroundColors.black, styledText.backgroundColors.red)
    elseif hasRun then
        header:colored(" PASS ", styledText.foregroundColors.black, styledText.backgroundColors.green)
    else
        header:colored(" SKIP ", styledText.foregroundColors.black, styledText.backgroundColors.blue)
    end

    originalPrint(tostring(header:plain(" " .. file.filePath)))

    if self.isVerbose then
        for _, test in ipairs(file.passed) do
            originalPrint(tostring(self:text():colored("  ✓ ", styledText.foregroundColors.green):plain(getFullName(test))))
        end

        for _, describeOrTest in ipairs(file.skipped) do
            originalPrint(tostring(self:text():colored("  ○ ", styledText.foregroundColors.blue)
                :plain(getFullName(describeOrTest) .. (describeOrTest.isTodo and " (todo)" or ""))))
        end
    end

    for _, test in ipairs(file.failed) do
        originalPrint(tostring(self:text():colored("  ✗ ", styledText.foregroundColors.red):plain(getFullName(test))))
        originalPrint(indent(table.concat(test.errors or {}), "      "))
    end

    if not self.isSilent then
        for _, test in ipairs(file.withOutput) do
            originalPrint(tostring(self:text():styled("  Console output of " .. getFullName(test) .. ":",
                styledText.styles.dim)))
            originalPrint(indent(table.concat(test.output, "\n"), "      "))
        end
    end
end

function PLAIN_REPORTER:startTestSet(rootDescribe, describesByFilePath)
    self.startedTodos = {}

    local totalTestCount = rootDescribe.totalTestCount

    originalPrint("Running " .. totalTestCount .. (totalTestCount == 1 and " test" or " tests") .. "...\n")
end

function PLAIN_REPORTER:testStarting(describeOrTest)
end

function PLAIN_REPORTER:testFinished(describeOrTest, success, ...)
    if not describeOrTest.isTest or not describeOrTest.hasRun then
        return
    end

    local file = self:getFileEntry(describeOrTest)

    table.insert(success and file.passed or file.failed, describeOrTest)

    if describeOrTest.output and #describeOrTest.output > 0 then
        table.insert(file.withOutput, describeOrTest)
    end
end

function PLAIN_REPORTER:testSkipped(describeOrTest)
    local file = self:getFileEntry(describeOrTest)

    table.insert(file.skipped, describeOrTest)

    if describeOrTest.isTodo then
        table.insert(self.startedTodos, describeOrTest)
    end
end

function PLAIN_REPORTER:testRetrying(describeOrTest, retryCount)
end

--- Prints the summary of the run.
--- @param rootDescribe DescribeOrTestForRun
--- @param failedTestCount number
--- @param skippedTestCount number
--- @param duration number
function PLAIN_REPORTER:printEnd(rootDescribe, failedTestCount, skippedTestCount, duration)
    self:printCurrentFile()

    local totalTestCount = rootDescribe.totalTestCount
    local todoCount = rootDescribe.todoCount or 0
    local passedCount = totalTestCount - failedTestCount - skippedTestCount - todoCount
    local summary = self:text():plain("\nTests:       ")

    if failedTestCount > 0 then
        summary:colored(failedTestCount .. " failed", styledText.foregroundColors.red):plain(", ")
    end

    if skippedTestCount > 0 then
        summary:colored(skippedTestCount .. " skipped", styledText.foregroundColors.blue):plain(", ")
    end

    if todoCount > 0 then
        summary:colored(todoCount .. " todo", styledText.foregroundColors.magenta):plain(", ")
    end

    summary:colored(passedCount .. " passed", styledText.foregroundColors.green)
        :plain(", " .. totalTestCount .. " total")

    originalPrint(tostring(summary))
    originalPrint("Time:        " .. duration .. "s")

    for _, test in ipairs(self.startedTodos) do
        originalPrint(tostring(self:text():colored("  todo ", styledText.foregroundColors.magenta)
            :plain(getFullName(test) .. " (" .. test.filePath .. ")")))
    end
end

--- Prints that the run stopped early because of the bail option.
--- @param rootDescribe DescribeOrTestForRun
--- @param bailError string
function PLAIN_REPORTER:printBailed(rootDescribe, bailError)
    self:printCurrentFile()

    originalPrint(tostring(self:text():colored("\nBailed out of tests after too many failures.",
        styledText.foregroundColors.red)))
end

--- @return PlainReporter
local function newPlainReporter()
    return setmetatable({}, PLAIN_REPORTER)
end

return {
    PLAIN_REPORTER = PLAIN_REPORTER,
    newPlainReporter = newPlainReporter,
}
