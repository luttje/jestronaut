describe('mocks', function()
    describe('function mocks', function()
        it('can be created', function()
            local mockFn = jestronaut:fn()
            expect(mockFn):toBeType('function')
        end)

        it('can be called', function()
            local mockFn = jestronaut:fn()
            mockFn()
            expect(mockFn):toHaveBeenCalled()
        end)

        it:failing('when not called', function()
            local mockFn = jestronaut:fn()
            expect(mockFn):toHaveBeenCalled()
        end)

        it('can be called with arguments', function()
            local mockFn = jestronaut:fn()
            mockFn(1, 2, 3)
            expect(mockFn):toHaveBeenCalledWith(1, 2, 3)
        end)

        it:failing('when called with no arguments', function()
            local mockFn = jestronaut:fn()
            mockFn(1, 2, 3)
            expect(mockFn):toHaveBeenCalledWith()
        end)

        it:failing('when called with wrong arguments', function()
            local mockFn = jestronaut:fn()
            mockFn(1, 2, 3)
            expect(mockFn):toHaveBeenCalledWith(1, 2, 4)
        end)

        it('can return one mocked value', function()
            local mockFn = jestronaut:fn()
            mockFn:mockReturnValueOnce(4)
            expect(mockFn(1, 2, 3)):toEqual(4)
        end)

        it:failing('when called and it returns one incorrect mocked value', function()
            local mockFn = jestronaut:fn()
            mockFn:mockReturnValueOnce(4)
            expect(mockFn(1, 2, 3)):toEqual(5)
        end)

        it('can return values in a table', function()
            local mockFn = jestronaut:fn()
            mockFn:mockReturnValueOnce({ 4, 5, 6 })
            expect(mockFn(1, 2, 3)):toEqual({ 4, 5, 6 })
        end)

        it('can return values in multiple tables', function()
            local mockFn = jestronaut:fn()
            mockFn:mockReturnValueOnce({ 1, 2, 3 }, { 4, 5, 6 })
            expect(mockFn(1, 2, 3)):toEqual({ 1, 2, 3 }, { 4, 5, 6 })
        end)

        it('can return vararg values', function()
            local mockFn = jestronaut:fn()
            mockFn:mockReturnValueOnce(4, 5, 6)
            expect(mockFn(1, 2, 3)):toEqual(4, 5, 6)
        end)

        it('can return explicit vararg values', function()
            local mockFn = jestronaut:fn()
            mockFn:mockReturnValueOnce(4, 5, 6)
            expect(mockFn(1, 2, 3)):toEqual(expect:varargsMatching(4, 5, 6))
        end)

        it('can return argument and match one explicit vararg', function()
            local mockFn = jestronaut:fn()
            mockFn:mockReturnValueOnce(4)
            expect(mockFn(1, 2, 3)):toEqual(expect:varargsMatching(4))
        end)

        it:failing('matching some incorrect varargs', function()
            local mockFn = jestronaut:fn()
            mockFn:mockReturnValueOnce(4, 5, 8)
            expect(mockFn(1, 2, 3)):toEqual(4, 5, 3)
        end)

        it:failing('matches only if return values and expection match exactly (prevents table matching varargs)',
            function()
                local mockFn = jestronaut:fn()
                mockFn:mockReturnValueOnce({ 4, 5, 6 }) -- Should not match varargs!
                expect(mockFn(1, 2, 3)):toEqual(expect:varargsMatching(4, 5, 6))
            end)

        it('can mock the function name shown when failing', function()
            local defualtMockFn = jestronaut:fn()

            local function errors()
                expect(defualtMockFn):toHaveBeenCalled()
            end

            expect(errors):toThrow('jestronaut.fn()')

            local mockFn = jestronaut:fn():mockName('mockedFunction')

            local function alsoErrors()
                expect(mockFn):toHaveBeenCalled()
            end

            expect(alsoErrors):toThrow('mockedFunction')
        end)

        it('can return all arguments it was called with (internal, not available in Jest API)', function()
            local mockFn = jestronaut:fn()
            mockFn(1, 2, 3)
            mockFn(4, 5, 6)

            local allCallArgs = mockFn:getAllCallArgs()

            expect(allCallArgs[1]):toEqual(1, 2, 3)
            expect(allCallArgs[2]):toEqual(4, 5, 6)
        end)

        it:failing('when arguments it was called with aren\'t expected (internal, not available in Jest API)', function()
            local mockFn = jestronaut:fn()
            mockFn(1, 2, 3)

            local allCallArgs = mockFn:getAllCallArgs()

            expect(allCallArgs[1]):toEqual(1, 9, 3)
        end)

        it('can return all values it returned (internal, not available in Jest API)', function()
            local mockFn = jestronaut:fn()
            mockFn:mockReturnValueOnce(4, 5, 6)
            mockFn:mockReturnValueOnce(7, 8, 9)

            mockFn()
            mockFn()

            local allReturnValues = mockFn:getAllReturnValues()

            expect(allReturnValues[1]):toEqual(4, 5, 6)
            expect(allReturnValues[2]):toEqual(7, 8, 9)
        end)

        it('can return a specific value it returned (internal, not available in Jest API)', function()
            local mockFn = jestronaut:fn()
            mockFn:mockReturnValueOnce(4, 5, 6)
            mockFn:mockReturnValueOnce(7, 8, 9)

            mockFn()
            mockFn()

            local allReturnValue = mockFn:getReturnedValue(2)

            expect(allReturnValue):toEqual(7, 8, 9)
        end)

        it:failing('when return values weren\'t expected (internal, not available in Jest API)', function()
            local mockFn = jestronaut:fn()
            mockFn:mockReturnValueOnce(4, 5, 6)

            mockFn()

            local allReturnValues = mockFn:getAllReturnValues()

            expect(allReturnValues[1]):toEqual(4, 5, 9)
        end)

        it('records returns of functions that return nothing', function()
            local mockFn = jestronaut:fn()
            mockFn()
            mockFn()

            expect(mockFn):toHaveReturned()
            expect(mockFn):toHaveReturnedTimes(2)
            expect(mockFn.mock.results[1]):toEqual({ type = 'return' })
        end)

        it('records returned values in mock.results', function()
            local mockFn = jestronaut:fn(function(a) return a * 2 end)
            mockFn(2)

            expect(mockFn.mock.results[1]):toEqual({ type = 'return', value = 4 })
            expect(mockFn):toHaveLastReturnedWith(4)
            expect(mockFn):toHaveNthReturnedWith(1, 4)
        end)

        it('can spy on a property getter', function()
            local obj = { foo = 1 }
            local spy = jestronaut:spyOn(obj, 'foo', 'get')
            print(obj.foo)
            expect(spy):toHaveBeenCalled()
        end)

        it('can spy on a property getter leaving unspied properties alone', function()
            local obj = { foo = 1, bar = 2 }
            local spy = jestronaut:spyOn(obj, 'foo', 'get')
            print(obj.bar)
            expect(spy)['not']:toHaveBeenCalled()
        end)

        it('can spy on a property setter', function()
            local obj = { foo = 1 }
            local spy = jestronaut:spyOn(obj, 'foo', 'set')
            obj.foo = 2
            expect(spy):toHaveBeenCalled()
        end)

        it('can spy on a property setter leaving unspied properties alone', function()
            local obj = { foo = 1, bar = 2 }
            local spy = jestronaut:spyOn(obj, 'foo', 'set')
            obj.bar = 3
            expect(spy)['not']:toHaveBeenCalled()
        end)

        it('can spy on a property setter leaving getter', function()
            local obj = { foo = 1, bar = 2 }
            local spy = jestronaut:spyOn(obj, 'foo', 'set')
            print(obj.foo)
            expect(spy)['not']:toHaveBeenCalled()
            obj.foo = 3
            expect(spy):toHaveBeenCalled()
        end)

        it('can spy on a nil property setter just fine', function()
            local obj = { foo = nil }
            local spy = jestronaut:spyOn(obj, 'foo', 'set')
            obj.foo = 3
            expect(spy):toHaveBeenCalled()
        end)

        it('can spy on a nil property getter just fine', function()
            local obj = { foo = nil }
            local spy = jestronaut:spyOn(obj, 'foo', 'get')
            print(obj.foo)
            expect(spy):toHaveBeenCalled()
        end)
    end)
end)

describe('restoring mocks', function()
    it('puts the original method back with mockRestore', function()
        local original = function(value) return value * 2 end
        local object = { double = original }
        local spy = jestronaut:spyOn(object, 'double')

        expect(object.double(2)):toBe(4)
        expect(spy):toHaveBeenCalledWith(2)

        spy:mockRestore()
        expect(object.double):toBe(original)
    end)

    it('puts all spied methods back with restoreAllMocks', function()
        local original = function() end
        local object = { a = original, b = original }
        jestronaut:spyOn(object, 'a')
        jestronaut:spyOn(object, 'b')

        jestronaut:restoreAllMocks()
        expect(object.a):toBe(original)
        expect(object.b):toBe(original)
    end)

    it('puts a spied property back with mockRestore, keeping its value', function()
        local metatable = {}
        local object = setmetatable({ volume = 1 }, metatable)
        local spy = jestronaut:spyOn(object, 'volume', 'set')

        object.volume = 5
        spy:mockRestore()

        expect(getmetatable(object)):toBe(metatable)
        expect(rawget(object, 'volume')):toBe(5)
    end)

    it('leaves other properties alone while spying on one', function()
        local object = setmetatable({ volume = 1 }, { __index = { inherited = 'x' } })
        jestronaut:spyOn(object, 'volume', 'get')

        expect(object.missing):toBeNil()
        expect(object.inherited):toBe('x')

        object.added = 2
        expect(rawget(object, 'added')):toBe(2)
    end)

    it('returns nothing after mockReset instead of failing', function()
        local mockFn = jestronaut:fn(function() return 1 end)
        mockFn:mockReset()

        expect(mockFn()):toBeNil()
        expect(mockFn):toHaveBeenCalledTimes(1)
    end)
end)
