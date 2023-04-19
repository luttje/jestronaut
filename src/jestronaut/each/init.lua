--- Normalizes an item so it becomes an array.
--- @param item any
--- @return ...
local function normalizeItem(item)
  -- If it's an associative array, return the whole item.
  if type(item) == "table" then
    if #item == 0 then
      return item
    end

    return unpack(item)
  end

  -- If it's a single item, return it
  return item
end

--- Formats a name for a test.
--- Generate unique test titles by positionally injecting parameters with printf formatting:
---   - %p - pretty-format.
---   - %s- String.
---   - %d- Number.
---   - %i - Integer.
---   - %f - Floating point value.
---   - %j - JSON.
---   - %o - Object.
---   - %# - Index of the test case.
---   - %% - single percent sign ('%'). This does not consume an argument.
--- Or generate unique test titles by injecting properties of test case object with $variable
---   - To inject nested object values use you can supply a keyPath i.e. $variable.path.to.value
---   - You can use $# to inject the index of the test case
---   - You cannot use $variable with the printf formatting except for %%
---
--- @param name string
--- @param index number
--- @vararg any
--- @return string
local function formatName(name, index, ...)
  local args = {...}
  
  -- Replace %s, %d, %i, %f, %j, %o, %# and %%
  name = name:gsub("%%([sdifjo#])", function(match)
    local arg = table.remove(args, 1)
    if match == "s" then
      return tostring(arg)
    elseif match == "d" then
      return tostring(tonumber(arg))
    elseif match == "i" then
      return tostring(math.floor(tonumber(arg)))
    elseif match == "f" then
      return tostring(tonumber(arg))
    elseif match == "j" then
      return tostring(arg)
    elseif match == "o" then
      return tostring(arg)
    elseif match == "#" then
      return tostring(index)
    elseif match == "%" then
      return "%"
    end
  end)

  -- Replace $variable
  name = name:gsub("%$(%w+)", function(match)
    local arg = table.remove(args, 1)
    return tostring(arg[match])
  end)

  return name
end

--- Adds a 'each' function to the table that can be used to run a function for each item in a table.
--- @param target table
local function bindTo(target, baseTarget)
  --- Runs a function for each item in a table.
  --- @param table table
  local function each(target, table)
    return function(name, fn, timeout)
      baseTarget(name, function()
        for index, item in pairs(table) do
          baseTarget(formatName(name, index, normalizeItem(item)), function()
            fn(normalizeItem(item))
          end, timeout)
        end
      end)
    end
  end
  
  target.each = each
end

return {
  bindTo = bindTo,
}