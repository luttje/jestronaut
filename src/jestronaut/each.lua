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

  local argTable = table.remove(args, 1)

  if argTable == nil then
    return name
  end

  -- Replace $variable
  name = name:gsub("%$(%w+)", function(match)
    local value = argTable[match]
    if value == nil then
      return match
    end

    return tostring(value)
  end)

  return name
end

--- Adds a 'each' function to the table that can be used to run a function for each item in a table.
--- @param target table
local function bindTo(target)
  --- Runs a function for each item in a table.
  --- @param target table
  --- @param table table
  local function each(target, table)
    return function(name, fn, ...)
      local args = {...}

      for index, item in pairs(table) do
        local describeOrTest = target(target, formatName(name, index, normalizeItem(item)), function()
          fn(normalizeItem(item))
        end, unpack(args))

        -- Leave the isOnly flag only on the last test (so only the last each iteration will block the rest of the test suite)
        if describeOrTest.isOnly and index < #table then
          describeOrTest.isOnly = false
        end
      end
    end
  end
  
  target.each = each
end

return {
  bindTo = bindTo,
}