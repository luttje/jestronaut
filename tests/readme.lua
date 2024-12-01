describe('readme examples', function()
    describe("test organization into suites", function()
        it("should confirm basic math", function()
            expect(1 + 1):toBe(2)
        end)
    end)

    it("should let sums NOT match", function()
        expect(1 + 1)['not']:toBe(3)
        expect(1 + 5)['not']:toBeGreaterThan(7)
    end)

    it("should have all the matchers Jest has", function()
        expect(1 + 1):toBe(2)
        expect(0.1 + 5.2):toBeCloseTo(5.3)
        expect({}):toBeDefined()
        expect(nil):toBeFalsy()
        expect(1 + 1):toBeGreaterThan(1)
        expect(1 + 1):toBeGreaterThanOrEqual(2)
        expect(1 + 1):toBeLessThan(3)
        expect(1 + 1):toBeLessThanOrEqual(2)
        expect(0 / 0):toBeNaN()
        expect(nil):toBeNil()
        expect(nil):toBeNull()
        expect(1 + 1):toBeTruthy()
        expect(1 + 1):toBeType('number')
        expect(nil):toBeUndefined()
        expect({ 1, 2, 3 }):toContain(2)
        expect({ 1, 2, 3 }):toContainEqual(2)
        expect({ 1, 2, 3 }):toEqual({ 1, 2, 3 })
        expect({ 1, 2, 3 }):toHaveLength(3)
        expect({
            a = 1,
            b = 2,
            c = 3
        }):toHaveProperty('a')
        expect("abc"):toMatch("c$") -- Lua patterns
        expect({
            a = 1,
            b = 2,
            c = 3
        }):toMatchObject({
            a = 1,
            b = 2
        })
        expect({}):toStrictEqual({})
        expect(function() error('test') end):toThrow('test')
        expect(function() error('testing') end):toThrowError('testing')
    end)

    it('should be able to mock function implementations', function()
        local mockFn = jestronaut:fn(function() return 'x', 'y', 'z' end)
        mockFn(1, 2, 3)

        expect(mockFn):toHaveBeenCalled()
        expect(mockFn):toHaveBeenCalledTimes(1)
        expect(mockFn):toHaveBeenCalledWith(1, 2, 3)

        mockFn(3, 2, 1)
        expect(mockFn):toHaveBeenLastCalledWith(3, 2, 1)
        expect(mockFn):toHaveBeenNthCalledWith(1, 1, 2, 3)
        expect(mockFn):toHaveLastReturnedWith('x', 'y', 'z')
        expect(mockFn):toHaveNthReturnedWith(1, 'x', 'y', 'z')
        expect(mockFn):toHaveReturned()
        expect(mockFn):toHaveReturnedTimes(2)
        expect(mockFn):toHaveReturnedWith('x', 'y', 'z')
    end)

    local ranBefore = 0
    beforeAll(function()
        ranBefore = ranBefore + 1
    end)

    it('should run beforeAll for each "it" this checks how many (so far)', function()
        expect(ranBefore):toEqual(5)
    end)

    it('can spy on a property setter', function()
        local audio = {
            volume = 0,
        }
        local spy = jestronaut:spyOn(audio, 'volume', 'set')
        audio.volume = 100

        expect(spy):toHaveBeenCalled()
        expect(audio.volume):toBe(100)
    end)

    it('can spy on a property getter', function()
        local audio = {
            volume = 0,
        }
        local spy = jestronaut:spyOn(audio, 'volume', 'get')
        print(audio.volume)

        expect(spy):toHaveBeenCalled()
        expect(audio.volume):toBe(0)
    end)

    it:failing('should be able to expected failures', function()
        expect(1 + 1):toEqual(1)
    end)

    it:skip('should be able to skip tests', function()
        expect(1 + 1):toEqual(1)
    end)

    it:each({ { 1, 1, 2 }, { 1, 2, 3 }, { 2, 1, 3 } })(
        "can loop data (%i, %i = %i)",
        function(a, b, expected)
            expect(a + b):toBe(expected)
        end
    )
end)
