describe('expect simple', function()
    it('has an expect function', function()
        expect('expect'):toEqual('expect')
    end)

    it('has a toBe function', function()
        expect('test'):toBe('test');
    end)

    it('has a toEqual function', function()
        expect('test'):toEqual('test');
    end)

    it('has a toBeGreaterThan function', function()
        expect(2):toBeGreaterThan(1);
    end)

    it('has a toBeGreaterThanOrEqual function', function()
        expect(2):toBeGreaterThanOrEqual(2);
    end)

    it('has a toBeLessThan function', function()
        expect(1):toBeLessThan(2);
    end)

    it('has a toBeLessThanOrEqual function', function()
        expect(2):toBeLessThanOrEqual(2);
    end)

    it('has a toBeTruthy function', function()
        expect(true):toBeTruthy();
    end)

    it('has a toBeFalsy function', function()
        expect(false):toBeFalsy();
    end)

    it('has a toBeNil function', function()
        expect(nil):toBeNil();
    end)

    it('has a toBeType function', function()
        expect({}):toBeType('table');
    end)

    it('has a toContain function', function()
        expect({ 1, 2, 3 }):toContain(2);
    end)

    it('has a toContainEqual function', function()
        expect({ { 1 }, { 2 }, { 3 } }):toContainEqual({ 2 });
    end)

    it('has a toHaveLength function', function()
        expect({ 1, 2, 3 }):toHaveLength(3);
    end)

    it('has a toHaveProperty function', function()
        expect({ a = 1 }):toHaveProperty('a');
    end)

    it('has a toMatch function', function()
        expect('test'):toMatch('test');
    end)

    it('has a toMatchObject function', function()
        expect({ a = 1 }):toMatchObject({ a = 1 });
    end)

    it('has a toThrow function', function()
        expect(function() error('test') end):toThrow('test');
    end)

    it('has a toThrowError function', function()
        expect(function() error('test') end):toThrowError('test');
    end)
end)

describe('toEqual', function()
    it('passes for recursively equal tables', function()
        expect({ a = 1, b = { c = { 1, 2 } } }):toEqual({ a = 1, b = { c = { 1, 2 } } })
    end)

    it('fails when the actual table has extra keys', function()
        expect(function()
            expect({ a = 1, b = 2 }):toEqual({ a = 1 })
        end):toThrow('Difference at %.b: expected nil, received 2')
    end)

    it('fails when the actual table is missing keys', function()
        expect(function()
            expect({ a = 1 }):toEqual({ a = 1, b = 2 })
        end):toThrow('Difference at %.b: expected 2, received nil')
    end)

    it('fails when arrays have different lengths', function()
        expect(function()
            expect({ 1, 2, 3 }):toEqual({ 1, 2 })
        end):toThrow('Difference at %[3%]')
    end)

    it('reports the path to a nested difference', function()
        expect(function()
            expect({ a = { ['b c'] = { 1 } } }):toEqual({ a = { ['b c'] = { 2 } } })
        end):toThrow('Difference at %.a%["b c"%]%[1%]: expected 2, received 1')
    end)

    it('distinguishes strings from numbers', function()
        expect(function()
            expect('1'):toEqual(1)
        end):toThrow('Expected: 1\nReceived: "1"')
    end)

    it('passes with not when only some values differ', function()
        expect({ a = 1, b = 2 })['not']:toEqual({ a = 1, b = 3 })
    end)

    it('fails with not when the values are equal', function()
        expect(function()
            expect({ a = 1 })['not']:toEqual({ a = 1 })
        end):toThrow('Expected: not { a = 1 }')
    end)

    it('considers NaN equal to NaN', function()
        expect(0 / 0):toEqual(0 / 0)
    end)

    it('handles cyclic tables', function()
        local a, b = {}, {}
        a.self, b.self = a, b

        expect(a):toEqual(b)
    end)

    it('ignores metatables', function()
        expect(setmetatable({ a = 1 }, {})):toEqual({ a = 1 })
    end)

    it('supports asymmetric matchers inside tables', function()
        expect({ id = 5, name = 'x' }):toEqual({ id = expect:any('number'), name = 'x' })
    end)
end)

--- Checks that the function fails an assertion with a message containing all given texts.
local function expectFailure(fn, ...)
    local success, err = pcall(fn)

    expect(success):toBe(false)

    for _, text in ipairs({ ... }) do
        expect(tostring(err)):toContain(text)
    end
end

describe('matcher failure messages', function()
    it('start with a hint showing the matcher and not', function()
        expectFailure(function() expect(1):toBe(2) end, 'expect(received):toBe()', 'Expected: 2\nReceived: 1')
        expectFailure(function() expect(1)['not']:toBe(1) end, 'expect(received)["not"]:toBe()', 'Expected: not 1')
    end)

    it('point at the line of the failing expect', function()
        expectFailure(function() expect(1):toBe(2) end, 'tests/expect.lua:' .. (debug.getinfo(1, 'l').currentline))
    end)

    it('use not in the message of every matcher', function()
        expectFailure(function() expect(5)['not']:toBeGreaterThan(1) end, 'Expected: not > 1', 'Received: 5')
        expectFailure(function() expect(nil)['not']:toBeNil() end, 'Expected: not nil')
        expectFailure(function() expect('abc')['not']:toMatch('b') end, 'Expected pattern: not "b"')
        expectFailure(function() expect({ 1 })['not']:toHaveLength(1) end, 'Expected length: not 1')
    end)

    it('fail usage errors regardless of not', function()
        expectFailure(function() expect('5')['not']:toBeGreaterThan(1) end,
            'Matcher error: received value must be a number, got "5"')
    end)

    it('format tables and strings readably', function()
        expectFailure(function() expect({ b = 'x', a = { 1, 2 } }):toBe(true) end,
            'Received: { a = { 1, 2 }, b = "x" }')
    end)
end)

describe('matchers', function()
    it('toBe compares tables by identity and suggests toEqual', function()
        local t = {}
        expect(t):toBe(t)
        expectFailure(function() expect({ 1 }):toBe({ 1 }) end, 'Use toEqual')
    end)

    it('toBeCloseTo uses a difference of less than 10^-numDigits / 2', function()
        expect(0.1 + 0.2):toBeCloseTo(0.3)
        expect(0.3)['not']:toBeCloseTo(0.31)
        expect(0.3):toBeCloseTo(0.31, 1)
        expectFailure(function() expect(0.3):toBeCloseTo(0.31) end, 'Expected difference: < 0.005')
    end)

    it('toContain checks array items and substrings', function()
        expect({ 1, 2, 3 }):toContain(2)
        expect('hello world'):toContain('o w')
        expect('a.b'):toContain('.')
        expect({ 1, 2, 3 })['not']:toContain(4)
        expectFailure(function() expect({ 1, 2, 3 }):toContain(4) end, 'Expected value: 4')
    end)

    it('toContainEqual checks array items with toEqual', function()
        expect({ { a = 1 }, { b = 2 } }):toContainEqual({ b = 2 })
        expect({ { a = 1, b = 2 } })['not']:toContainEqual({ a = 1 })
    end)

    it('toHaveProperty finds nested properties, including false values', function()
        local value = { a = { b = { 10, 20 } }, enabled = false }

        expect(value):toHaveProperty('a.b[2]', 20)
        expect(value):toHaveProperty({ 'a', 'b', 1 })
        expect(value):toHaveProperty('enabled', false)
        expect(value)['not']:toHaveProperty('a.c')
        expectFailure(function() expect(value):toHaveProperty('a.c.d') end, 'Expected path: a.c.d',
            'Received path: a')
        expectFailure(function() expect(value):toHaveProperty('a.b', { 10 }) end, 'Expected value: { 10 }')
    end)

    it('toMatch fails cleanly when there is no match', function()
        expectFailure(function() expect('abc'):toMatch('^b') end, 'Expected pattern: "^b"')
        expectFailure(function() expect('abc'):toMatch('[') end, 'Matcher error: invalid pattern')
    end)

    it('toMatchObject checks a subset, with arrays matching in length', function()
        expect({ a = 1, b = { c = 2, d = 3 } }):toMatchObject({ b = { c = 2 } })
        expectFailure(function() expect({ list = { 1, 2 } }):toMatchObject({ list = { 1 } }) end,
            'Difference at .list')
    end)

    it('toStrictEqual compares metatables', function()
        local class = {}

        expect(setmetatable({ a = 1 }, class)):toStrictEqual(setmetatable({ a = 1 }, class))
        expectFailure(function() expect(setmetatable({ a = 1 }, class)):toStrictEqual({ a = 1 }) end,
            'their metatables differ')
    end)

    it('toThrow matches messages literally or as a pattern', function()
        expect(function() error('call a.b(c) failed') end):toThrow('a.b(c)')
        expect(function() error('code 42') end):toThrow('code %d+')
        expect(function() end)['not']:toThrow()
        expect(function() error('other') end)['not']:toThrow('expected')
        expectFailure(function() expect(function() end):toThrow() end, 'Received function did not throw')
    end)

    it('mock matchers list the calls that were received', function()
        local mockFn = jestronaut:fn():mockName('myMock')
        mockFn(1, 'a')
        mockFn()

        expectFailure(function() expect(mockFn):toHaveBeenCalledWith(2) end, 'expect(myMock)',
            'Expected: 2', '1: 1, "a"', '2: (no arguments)')
        expectFailure(function() expect(mockFn):toHaveBeenCalledTimes(1) end, 'Received number of calls: 2')
        expectFailure(function() expect({}):toHaveBeenCalled() end, 'must be a mock or spy function')
    end)
end)

describe('expect.extend', function()
    expect:extend({
        toBeEven = function(received)
            return {
                pass = received % 2 == 0,
                message = function(isNot)
                    return 'Expected ' .. received .. (isNot and ' not' or '') .. ' to be even'
                end,
            }
        end,
    })

    it('adds custom matchers that support not', function()
        expect(2):toBeEven()
        expect(3)['not']:toBeEven()
        expectFailure(function() expect(3):toBeEven() end, 'expect(received):toBeEven()', 'Expected 3 to be even')
        expectFailure(function() expect(2)['not']:toBeEven() end, 'Expected 2 not to be even')
    end)
end)
