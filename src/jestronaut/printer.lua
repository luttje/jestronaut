--- @class Printer
local Printer = {}

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

--- Prints the start message of the test.
--- @param rootDescribe Describe
function Printer:printStart(rootDescribe)
  local totalTestCount = rootDescribe.childCount + rootDescribe.grandChildrenCount
  local startTime = os.date("%X")
  print("🚀 Starting " .. totalTestCount .. " tests at " .. startTime .. "...\n\n")
end

--- Prints the end message of the test.
--- @param duration number
function Printer:printEnd(duration)
  local endTime = os.date("%X")
  print("\n\n🏁 Finished tests at " .. endTime .. " in " .. duration .. " seconds.")
end

--- Prints the fail fast message of the test.
--- @param describeOrTest DescribeOrTest
function Printer:printFailFast(describeOrTest)
  print("\n\n🚨 Fail fast triggered by " .. describeOrTest.name .. ".")
end

return {
  Printer = Printer,
}