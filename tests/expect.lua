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
