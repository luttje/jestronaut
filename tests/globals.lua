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

    it.concurrent('runs concurrent tests', function()
        expect('it.concurrent'):toBe('it.concurrent')
    end)

    it:concurrent('runs concurrent tests called with a colon', function()
        expect('it:concurrent'):toBe('it:concurrent')
    end)
end)
