local expect = require "jestronaut.expect"
local mock = require "jestronaut.mock"

local M = {}

local currentFile = nil
local currentDescribe = nil

local function printer(text, depthOffset, withNewline)
  local depth = (currentDescribe and currentDescribe.depth or 0) + (depthOffset or 0)
  local tabs = string.rep('\t', depth)
  print((withNewline and '\n' or '') .. tabs .. text)
end
expect.printer = printer

local function printFileIfChanged()
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

function M.it(description, callback)
  printFileIfChanged()

  expect.currentTest = description

  printer('it: ' .. description, 1, true)

  callback()

  expect.currentTest = nil
end

function M.describe(description, callback)
  printFileIfChanged()

  currentDescribe = {
    description = description,
    depth = currentDescribe and currentDescribe.depth + 1 or 0
  }

  printer('> ' .. description)

  callback()

  currentDescribe = nil
end

function M.withGlobals()
  _G.it = M.it
  _G.describe = M.describe
  _G.expect = expect.expect
 
  return M
end

return M