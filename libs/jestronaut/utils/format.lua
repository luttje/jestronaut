local MAX_DEPTH = 4
local MAX_ITEMS = 20

local STRING_ESCAPES = {
    ["\\"] = "\\\\",
    ['"'] = '\\"',
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
}

local format

--- @param value string
--- @return string
local function formatString(value)
    return '"' .. (value:gsub('[\\"\n\r\t]', STRING_ESCAPES)) .. '"'
end

--- @param value number
--- @return string
local function formatNumber(value)
    if value ~= value then
        return "NaN"
    elseif value == math.huge then
        return "math.huge"
    elseif value == -math.huge then
        return "-math.huge"
    end

    return tostring(value)
end

--- Formats a table key the way it would be written in a table constructor, e.g. `name`, `[1]` or `["some key"]`.
--- @param key any
--- @return string
local function formatKey(key)
    if type(key) == "string" and key:match("^[%a_][%w_]*$") then
        return key
    elseif type(key) == "string" then
        return "[" .. formatString(key) .. "]"
    end

    return "[" .. format(key) .. "]"
end

--- Formats a table key as a step in a path, e.g. `.name`, `[1]` or `["some key"]`.
--- @param key any
--- @return string
local function formatPathKey(key)
    if type(key) == "string" and key:match("^[%a_][%w_]*$") then
        return "." .. key
    end

    return formatKey(key)
end

local KEY_TYPE_ORDER = { number = 1, string = 2 }

--- Sorts keys so tables are always shown the same way: numbers first, then strings, then anything else.
local function compareKeys(a, b)
    local typeA, typeB = type(a), type(b)
    local orderA, orderB = KEY_TYPE_ORDER[typeA] or 3, KEY_TYPE_ORDER[typeB] or 3

    if orderA ~= orderB then
        return orderA < orderB
    elseif typeA == "number" or typeA == "string" then
        return a < b
    end

    return tostring(a) < tostring(b)
end

--- Checks whether the table only has the keys 1 to n.
--- @param value table
--- @return boolean
local function isSequence(value)
    local count = 0

    for _ in pairs(value) do
        count = count + 1
    end

    return count == #value
end

--- @param value table
--- @param depth number
--- @param seen table
--- @return string
local function formatTable(value, depth, seen)
    local metatable = getmetatable(value)

    if type(metatable) == "table" and rawget(metatable, "__tostring") then
        return tostring(value)
    elseif seen[value] then
        return "<cycle>"
    elseif next(value) == nil then
        return "{}"
    elseif depth >= MAX_DEPTH then
        return "{...}"
    end

    seen[value] = true

    local parts = {}
    local itemCount = 0

    if isSequence(value) then
        for _, item in ipairs(value) do
            itemCount = itemCount + 1

            if itemCount <= MAX_ITEMS then
                table.insert(parts, format(item, depth + 1, seen))
            end
        end
    else
        local keys = {}

        for key in pairs(value) do
            table.insert(keys, key)
        end

        table.sort(keys, compareKeys)

        for _, key in ipairs(keys) do
            itemCount = itemCount + 1

            if itemCount <= MAX_ITEMS then
                table.insert(parts, formatKey(key) .. " = " .. format(value[key], depth + 1, seen))
            end
        end
    end

    if itemCount > MAX_ITEMS then
        table.insert(parts, "... (" .. (itemCount - MAX_ITEMS) .. " more)")
    end

    seen[value] = nil

    return "{ " .. table.concat(parts, ", ") .. " }"
end

--- Formats any value for use in a message.
--- @param value any
--- @param depth? number
--- @param seen? table
--- @return string
function format(value, depth, seen)
    local valueType = type(value)

    if valueType == "string" then
        return formatString(value)
    elseif valueType == "number" then
        return formatNumber(value)
    elseif valueType == "table" then
        return formatTable(value, depth or 0, seen or {})
    end

    return tostring(value)
end

--- Formats a list of values separated by commas, e.g. the arguments of a call. An empty list is shown as
--- "(no arguments)".
--- @param values any[]
--- @param count? number The number of values, so trailing nils are shown too. Defaults to #values.
--- @return string
local function formatList(values, count)
    count = count or #values

    if count == 0 then
        return "(no arguments)"
    end

    local parts = {}

    for i = 1, count do
        parts[i] = format(values[i])
    end

    return table.concat(parts, ", ")
end

return {
    format = format,
    formatList = formatList,
    formatKey = formatKey,
    formatPathKey = formatPathKey,
}
