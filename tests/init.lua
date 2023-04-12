require "jestronaut.init".withGlobals()

-- Other tests
require "tests.expect"
require "tests.mock"

describe('basics', function()
  it('has a describe function', function()
    expect('describe').toEqual('describe')
  end)

  it('has an it function', function()
    expect('it').toEqual('it')
  end)

  it('has an expect function', function()
    expect('expect').toEqual('expect')
  end)

  it('exported globals', function()
    expect(_G).toHaveProperty('it')
    expect(_G).toHaveProperty('describe')
    expect(_G).toHaveProperty('expect')
  end)

  it('adds 1 + 2 to equal 3', function()
    expect(1 + 2).toBe(3);
  end)

  it('function equals test', function()
    expect('test').toBe('test');
  end)

  it('has a toEqual function', function()
    expect('test').toEqual('test');
  end)
end)