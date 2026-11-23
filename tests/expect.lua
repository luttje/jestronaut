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
        end):toThrow('Expected "1" to equal 1')
    end)

    it('passes with not when only some values differ', function()
        expect({ a = 1, b = 2 })['not']:toEqual({ a = 1, b = 3 })
    end)

    it('fails with not when the values are equal', function()
        expect(function()
            expect({ a = 1 })['not']:toEqual({ a = 1 })
        end):toThrow('not to equal')
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
