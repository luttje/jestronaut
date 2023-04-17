--- Adds a 'each' function to the table that can be used to run a function for each item in a table.
--- @param target table
local function bindTo(target)
  --- Runs a function for each item in a table.
  --- @param table table
  local function each(target, table)
    return function(name, fn, timeout, x)
      for index, item in pairs(table) do
        target(target, name:format(unpack(item)), fn, timeout)
      end
    end
  end
  
  target.each = each
end

return {
  bindTo = bindTo,
}