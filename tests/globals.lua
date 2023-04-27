require "jestronaut":withGlobals()

it('exported globals', function()
  expect(_G):toHaveProperty('it')
  expect(_G):toHaveProperty('describe')
  expect(_G):toHaveProperty('expect')
end)

describe('describes', function()
  it('has a describe function', function()
    expect('describe'):toEqual('describe')
  end)
end)

describe('its', function()
  it('has an it function', function()
    expect('it'):toEqual('it')
  end)

  it:failing('fails on incorrect modifier', function()
    expect('it')['NOTVALIDMODIFIER']:toBeDefined()
  end)

  it:todo('this test is still to be written')
end)

describe('only tests can fail', function()
  it.failing:skip('skips failing test', function()
    expect('it')['NOTVALIDMODIFIER']:toBeDefined()
  end)

  it.failing:only('fails on incorrect modifier only to run', function()
    expect('it')['NOTVALIDMODIFIER']:toBeDefined()
  end)

  it('not run', function()
    error('Should not be run!')
  end)
end)