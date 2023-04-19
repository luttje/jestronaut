--- Adds a 'each' function to the table that can be used to run a function for each item in a table.
--- @param target table
local function bindTo(target, baseTarget)
  --- Runs a function for each item in a table.
  --- @param table table
  local function each(target, table)
    return function(name, fn, timeout)
      local desc = baseTarget(name, function()
        for index, item in pairs(table) do
          baseTarget(name:format(unpack(item)), function()
            fn(unpack(item))
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