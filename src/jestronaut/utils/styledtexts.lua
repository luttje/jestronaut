--- ANSI Colors
local foregroundColorsCodeMap = {
  black = "30",
  red = "31",
  green = "32",
  yellow = "33",
  blue = "34",
  magenta = "35",
  cyan = "36",
  white = "37",
  default = "39",
}
local backgroundColorsCodeMap = {
  black = "40",
  red = "41",
  green = "42",
  yellow = "43",
  blue = "44",
  magenta = "45",
  cyan = "46",
  white = "47",
  default = "49",
}
local resetColorsCode = "0"

--- ANSI text styles
local textStylesCodeMap = {
  bold = "1",
  dim = "2",
  italic = "3",
  underline = "4",
  blink = "5",
  inverse = "7",
  hidden = "8",
  strikethrough = "9",
}

--- ANSI Cursor controls
local cursorCodesMap = {
  home = "H",
  moveToLineAndColumn = "%d;%dH", -- line #, column #
  moveUpLines = "%dA", -- # lines
  moveDownLines = "%dB", -- # lines
  moveForwardColumns = "%dC", -- # columns
  moveBackwardColumns = "%dD", -- # columns

  moveToBeginningOfNextLine = "%dE", -- # lines
  moveToBeginningOfPreviousLine = "%dF", -- # lines

  moveToColumn = "%dG", -- column #

  requestCursorPosition = "6n", -- response: ESC[#row;#columnR

  moveCursorUpOneLineWithScroll = "M", -- Scrolls if needed

  saveCursorPosition = "7", -- DEC
  restoreCursorPosition = "8", -- DEC
}

--- ANSI Erase commands
--- Note: Erasing the line won't move the cursor, meaning that the cursor will stay at 
--- the last position it was at before the line was erased. You can use \r after erasing 
--- the line, to return the cursor to the start of the current line.
local eraseCodesMap = {
  eraseBelow = "J",
  eraseCursorToEndOfScreen = "0J",
  eraseCursorToScreenStart = "1J",
  eraseScreen = "2J",
  eraseSavedLines = "3J",

  eraseCursorToEndOfLine = "0K",
  eraseCursorToLineStart = "1K",
  eraseLine = "2K",
}

--- ANSI Escape character
local startFunction = "\27["
local endFunction = "m"

--- @class StyledText
local STYLED_TEXT_META = {}
STYLED_TEXT_META.__index = STYLED_TEXT_META

function STYLED_TEXT_META:addText(text, code)
  if code then
    self.parts[#self.parts + 1] = startFunction .. code .. endFunction .. (text or "") .. startFunction .. resetColorsCode .. endFunction
  elseif text then
    self.parts[#self.parts + 1] = text
  end

  return self
end

function STYLED_TEXT_META:addCommand(code)
  self.parts[#self.parts + 1] = startFunction .. code .. "\r"
  return self
end

function STYLED_TEXT_META:newline()
  return self:addText("\n")
end

function STYLED_TEXT_META:plain(text)
  return self:addText(text, "")
end

function STYLED_TEXT_META:colored(text, foreground, background)
  if background then
    return self:addText(text, foreground .. ";" .. background)
  end

  return self:addText(text, foreground)
end

function STYLED_TEXT_META:background(text, background)
  return self:addText(text, background)
end

function STYLED_TEXT_META:styled(text, style)
  return self:addText(text, style)
end

function STYLED_TEXT_META:cursor(command, ...)
  return self:addCommand(command:format(...))
end

function STYLED_TEXT_META:erase(command, reps)
  reps = reps or 1
  for i = 1, reps do
    self:addCommand(command)
  end

  return self
end

function STYLED_TEXT_META:reset()
  return self:addCommand(resetColorsCode)
end

function STYLED_TEXT_META:getLineCount()
  local _, count = string.gsub(tostring(self), "\n", "")

  return count
end

function STYLED_TEXT_META:rep(reps)
  return tostring(self):rep(reps)
end

function STYLED_TEXT_META:__tostring()
  return table.concat(self.parts)
end

--- Creates a new styled text object
--- @param text string|StyledText
--- @return StyledText
local function new(text)
  if text == nil then
    text = ""
  elseif type(text) ~= "string" then
    text = tostring(text)
  end

  return setmetatable({
    parts = { text },
  }, STYLED_TEXT_META)
end

return {
  STYLED_TEXT_META = STYLED_TEXT_META,
  
  new = new,

  foregroundColors = foregroundColorsCodeMap,
  backgroundColors = backgroundColorsCodeMap,
  resetColorsCode = resetColorsCode,

  styles = textStylesCodeMap,

  cursorCodes = cursorCodesMap,
  eraseCodes = eraseCodesMap,
}