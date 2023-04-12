local M = {}

M.printer = function(text, depthOffset, withNewline)
  local depth = depthOffset or 0
  local tabs = string.rep('\t', depth)
  print((withNewline and '\n' or '') .. tabs .. text)
end

function M.expect(value)
  local expect = {}

  function expect.toBe(expected)
    if value == expected then
      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end
  expect.toEqual = expect.toBe

  function expect.toBeFalsy()
    if not value then
      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected falsy but got ' .. tostring(value), 2)
    end
  end

  function expect.toBeGreaterThan(expected)
    if value > expected then
      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end

  function expect.toBeGreaterThanOrEqual(expected)
    if value >= expected then
      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end

  function expect.toBeLessThan(expected)
    if value < expected then
      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end

  function expect.toBeLessThanOrEqual(expected)
    if value <= expected then
      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end

  function expect.toBeNil()
    if value == nil then
      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected nil but got ' .. tostring(value), 2)
    end
  end

  function expect.toBeTruthy()
    if value then
      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected truthy but got ' .. tostring(value), 2)
    end
  end

  function expect.toContain(expected)
    if type(value) == 'table' then
      for _, v in ipairs(value) do
        if v == expected then
          M.printer('[v] PASS ' .. M.currentTest, 2)
          return
        end
      end
    end

    M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
  end

  function expect.toContainEqual(expected)
    local function deepCompare(t1, t2)
      if type(t1) ~= "table" or type(t2) ~= "table" then
        return t1 == t2
      end
      for k, v in pairs(t1) do
        if not deepCompare(v, t2[k]) then
          return false
        end
      end
      for k, v in pairs(t2) do
        if not deepCompare(v, t1[k]) then
          return false
        end
      end
      return true
    end
    
    if type(value) == 'table' then
      for i, v in ipairs(value) do
        if deepCompare(v, expected) then
          M.printer('[v] PASS ' .. M.currentTest, 2)
          return
        end
      end
    elseif value == expected then
      M.printer('[v] PASS ' .. M.currentTest, 2)
      return
    end
    M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
  end

  function expect.toMatch(expected)
    if type(value) == 'string' then
      if string.match(value, expected) then
        M.printer('[v] PASS ' .. M.currentTest, 2)
      else
        M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
      end
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end

  function expect.toMatchObject(expected)
    if type(value) == 'table' then
      for k, v in pairs(expected) do
        if value[k] ~= v then
          M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
          return
        end
      end

      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end

  function expect.toBeType(expected)
    if type(value) == expected or (expected == 'function' and type(value) == 'table' and value._isMockFunction) then
      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end

  function expect.toHaveProperty(expected)
    if value[expected] ~= nil then
      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end

  function expect.toHaveLength(expected)
    if #value == expected then
      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end

  function expect.toHaveBeenCalled()
    if value.calls ~= nil then
      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end

  function expect.toHaveBeenCalledTimes(expected)
    if value.calls ~= nil and #value.calls == expected then
      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end

  function expect.toHaveBeenCalledWith(...)
    if value.calls ~= nil then
      local args = {...}
      local found = false

      for _, call in ipairs(value.calls) do
        local match = true

        for i, arg in ipairs(args) do
          if call[i] ~= arg then
            match = false
            break
          end
        end

        if match then
          found = true
          break
        end
      end

      if found then
        M.printer('[v] PASS ' .. M.currentTest, 2)
      else
        M.printer('[×] FAIL ' .. M.currentTest .. ' expected to be called with ' .. table.concat({...}, ', ') .. ' but got ' .. tostring(value), 2)
      end
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected to be called with ' .. table.concat({...}, ', ') .. ' but got ' .. tostring(value), 2)
    end
  end

  function expect.toHaveReturned()
    if value.returns ~= nil then
      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected to have returned but got ' .. tostring(value) .. ' instead', 2)
    end
  end

  function expect.toHaveReturnedTimes(expected)
    if value.returns ~= nil and #value.returns == expected then
      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end

  function expect.toHaveReturnedWith(...)
    if value.returns ~= nil then
      local args = {...}
      local found = false

      for _, call in ipairs(value.returns) do
        local match = true

        for i, arg in ipairs(args) do
          if call[i] ~= arg then
            match = false
            break
          end
        end

        if match then
          found = true
          break
        end
      end

      if found then
        M.printer('[v] PASS ' .. M.currentTest, 2)
      else
        M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
      end
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end

  function expect.toHaveLastReturnedWith(...)
    if value.returns ~= nil then
      local args = {...}
      local lastCall = value.returns[#value.returns]
      local match = true

      for i, arg in ipairs(args) do
        if lastCall[i] ~= arg then
          match = false
          break
        end
      end

      if match then
        M.printer('[v] PASS ' .. M.currentTest, 2)
      else
        M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
      end
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end

  function expect.toHaveNthReturnedWith(n, ...)
    if value.returns ~= nil then
      local args = {...}
      local nthCall = value.returns[n]
      local match = true

      for i, arg in ipairs(args) do
        if nthCall[i] ~= arg then
          match = false
          break
        end
      end

      if match then
        M.printer('[v] PASS ' .. M.currentTest, 2)
      else
        M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
      end
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end

  function expect.toThrow()
    local success, err = pcall(value)

    if not success then
      M.printer('[v] PASS ' .. M.currentTest, 2)
    else
      M.printer('[×] FAIL ' .. M.currentTest .. ' expected ' .. tostring(expected) .. ' but got ' .. tostring(value), 2)
    end
  end
  expect.toThrowError = expect.toThrow

  return expect
end

return M