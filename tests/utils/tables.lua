local tablesLib = require "jestronaut/utils/tables"

describe('table utils', function()
  it('equals', function()
    expect(tablesLib.equals({1, 2, 3}, {1, 2, 3})):toBe(true)
    expect(tablesLib.equals({1, 2, 3}, {1, 2, 3, 4})):toBe(false)
    expect(tablesLib.equals({1, 2, 3}, {1, 2, 4})):toBe(false)
    expect(tablesLib.equals({1, 2, 3}, {1, 2, 3}, true)):toBe(true)
  end)

  it('count', function()
    expect(tablesLib.count({1, 2, 3})):toBe(3)
    expect(tablesLib.count({test=1, test2=2, test3=3})):toBe(3)
  end)

  it('keys', function()
    expect(tablesLib.keys({1, 2, 3})):toEqual({1, 2, 3})
    -- expect(tablesLib.keys({test=1, test2=2, test3=3})):toEqual({'test', 'test2', 'test3'}) -- TODO: shouldnt fail
  end)

  it('implode', function()
    expect(tablesLib.implode({1, 2, 3}, ', ', false)):toBe('1, 2, 3')
    -- Wont work because order is not reliable:
    -- expect(tablesLib.implode({test=1, test2=2, test3=3}, ', ')):toBe('test=1, test2=2, test3=3')
    -- expect(tablesLib.implode({test=1, test2=2, test3=3}, ', ', true)):toBe('test=1, test2=2, test3=3')
    -- expect(tablesLib.implode({test=1, test2=2, test3=3}, ', ', false)):toBe('1, 2, 3')
  end)

  it('copy', function()
    local t1 = {1, 2, 3}
    local t2 = tablesLib.copy(t1)
    expect(t1):toEqual(t2)
    expect(t1)['not']:toBe(t2)
  end)

  it('accessByPath', function()
    local t1 = {
      livingroom = {
        amenities = {
          {couch = {{dimensions = {1, 2, 3}}}},
          {couch = {{dimensions = {4, 5, 6}}}},
        }
      }
    }
    expect(tablesLib.accessByPath(t1, 'livingroom.amenities[1].couch[1].dimensions[1]')):toBe(1)
    expect(tablesLib.accessByPath(t1, 'livingroom.amenities[2].couch[1].dimensions[1]')):toBe(4)
    expect(tablesLib.accessByPath(t1, 'livingroom.amenities[2].couch[1].dimensions[2]')):toBe(5)
  end)

  it('isSubset', function()
    expect(tablesLib.isSubset({1, 2, 3}, {1, 2, 3, 4})):toBe(true)
    expect(tablesLib.isSubset({1, 2, 3}, {1, 2, 3})):toBe(true)
    expect(tablesLib.isSubset({1, 2, 3}, {1, 2, 4})):toBe(false)
    expect(tablesLib.isSubset({1, 2, 3}, {1, 2, 3, 4}, true)):toBe(true)
    expect(tablesLib.isSubset({1, 2, 3}, {1, 2, 3}, true)):toBe(true)
  end)

  it('contains', function()
    expect(tablesLib.contains({1, 2, 3}, {1, 2})):toBe(true)
    expect(tablesLib.contains({1, 2, 3}, {1, 2, 3})):toBe(true)
    expect(tablesLib.contains({1, 2, 3}, {1, 2, 4})):toBe(false)
    expect(tablesLib.contains({1, 2, 3}, {1, 2, 3, 4})):toBe(false)
    expect(tablesLib.contains({1, 2, 3}, {1, 2, 3}, true)):toBe(true)
  end)
end)
    