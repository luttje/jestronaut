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

function STYLED_TEXT_META:add(text, code)
  if code then
    self.parts[#self.parts + 1] = startFunction .. code .. endFunction .. text .. startFunction .. resetColorsCode .. endFunction
  else
    self.parts[#self.parts + 1] = text
  end

  return self
end

function STYLED_TEXT_META:plain(text)
  return self:add(text, "")
end

function STYLED_TEXT_META:colored(text, foreground, background)
  if background then
    return self:add(text, foreground .. ";" .. background)
  end

  return self:add(text, foreground)
end

function STYLED_TEXT_META:background(text, background)
  return self:add(text, background)
end

function STYLED_TEXT_META:styled(text, style)
  return self:add(text, style)
end

function STYLED_TEXT_META:cursor(text, command, ...)
  return self:add(text, string.format(command, ...))
end

function STYLED_TEXT_META:erase(text, command)
  return self:add(text, command)
end

function STYLED_TEXT_META:reset(text)
  return self:add(text, resetColorsCode)
end

function STYLED_TEXT_META:__tostring()
  return table.concat(self.parts)
end

--- Creates a new styled text object
--- @return StyledText
local function new()
  return setmetatable({
    parts = {},
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