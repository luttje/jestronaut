local M = {}

local currentTest = nil
local currentDescribe = nil

local function printWithTabs(text, depthOffset, withNewline)
  local depth = (currentDescribe and currentDescribe.depth or 0) + (depthOffset or 0)
  local tabs = string.rep('\t', depth)
  print((withNewline and '\n' or '') .. tabs .. text)
end

function M.it(description, callback)
  M.printFileIfChanged()

  currentTest = description

  printWithTabs('it: ' .. description, 1, true)

  callback()

  currentTest = nil
end

function M.describe(description, callback)
  M.printFileIfChanged()

  currentDescribe = {
    description = description,
    depth = currentDescribe and currentDescribe.depth + 1 or 0
  }

  printWithTabs('> ' .. description)

  callback()

  currentDescribe = nil
end

function M.expect(value)
  local expect = {}

  function expect.toBe(expected)
    if value == expected then
      printWithTabs('[v] PASS ' .. currentTest, 2)
    else
      printWithTabs('[×] FAIL ' .. currentTest, 2)
    end
  end
  expect.toEqual = expect.toBe

  function expect.toHaveProperty(expected)
    if value[expected] ~= nil then
      printWithTabs('[v] PASS ' .. currentTest, 2)
    else
      printWithTabs('[×] FAIL ' .. currentTest, 2)
    end
  end

  return expect
end

function M.printFileIfChanged()
  -- Get the current file name
  local info = debug.getinfo(2, "S")
  local fileName = info.source:sub(2)

  -- If the file name has changed, print it
  if fileName ~= currentFile then
    local title = 'Test Suite in ' .. fileName
    print('\n' .. title)
    print(string.rep('=', #title))
    currentFile = fileName
  end
end

function M.exportGlobals()
  _G.it = M.it
  _G.describe = M.describe
  _G.expect = M.expect
end

return M