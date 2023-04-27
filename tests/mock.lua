require "jestronaut":withGlobals()

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
      mockFn:mockReturnValueOnce({4, 5, 6})
      expect(mockFn(1, 2, 3)):toEqual({4, 5, 6})
    end)
    
    it('can return values in multiple tables', function()
      local mockFn = jestronaut:fn()
      mockFn:mockReturnValueOnce({1, 2, 3}, {4, 5, 6})
      expect(mockFn(1, 2, 3)):toEqual({1, 2, 3}, {4, 5, 6})
    end)

    it('can return vararg values', function()
      local mockFn = jestronaut:fn()
      mockFn:mockReturnValueOnce(4, 5, 6)
      expect(mockFn(1, 2, 3)):toEqual(4, 5, 6)
    end)

    it('can return explicit vararg values', function()
      local mockFn = jestronaut:fn()
      mockFn:mockReturnValueOnce(4, 5, 6)
      expect(mockFn(1, 2, 3)):toEqual(expect:varargsmatching(4, 5, 6))
    end)
    
    it('can return argument and match one explicit vararg', function()
      local mockFn = jestronaut:fn()
      mockFn:mockReturnValueOnce(4)
      expect(mockFn(1, 2, 3)):toEqual(expect:varargsmatching(4))
    end)
    
    it:failing('matching some incorrect varargs', function()
      local mockFn = jestronaut:fn()
      mockFn:mockReturnValueOnce(4, 5, 8)
      expect(mockFn(1, 2, 3)):toEqual(4, 5, 3)
    end)

    it:failing('matches only if return values and expection match exactly (prevents table matching varargs)', function()
      local mockFn = jestronaut:fn()
      mockFn:mockReturnValueOnce({4, 5, 6}) -- Should not match varargs!
      expect(mockFn(1, 2, 3)):toEqual(expect:varargsmatching(4, 5, 6))
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

    it('can spy on a property getter', function()
      local obj = {foo = 1}
      local spy = jestronaut:spyOn(obj, 'foo', 'get')
      print(obj.foo)
      expect(spy):toHaveBeenCalled()
    end)

    it('can spy on a property getter leaving unspied properties alone', function()
      local obj = {foo = 1, bar = 2}
      local spy = jestronaut:spyOn(obj, 'foo', 'get')
      print(obj.bar)
      expect(spy)['not']:toHaveBeenCalled()
    end)

    it('can spy on a property setter', function()
      local obj = {foo = 1}
      local spy = jestronaut:spyOn(obj, 'foo', 'set')
      obj.foo = 2
      expect(spy):toHaveBeenCalled()
    end)

    it('can spy on a property setter leaving unspied properties alone', function()
      local obj = {foo = 1, bar = 2}
      local spy = jestronaut:spyOn(obj, 'foo', 'set')
      obj.bar = 3
      expect(spy)['not']:toHaveBeenCalled()
    end)

    it('can spy on a property setter leaving getter', function()
      local obj = {foo = 1, bar = 2}
      local spy = jestronaut:spyOn(obj, 'foo', 'set')
      print(obj.foo)
      expect(spy)['not']:toHaveBeenCalled()
      obj.foo = 3
      expect(spy):toHaveBeenCalled()
    end)

    it('can spy on a nil property setter just fine', function()
      local obj = {foo = nil}
      local spy = jestronaut:spyOn(obj, 'foo', 'set')
      obj.foo = 3
      expect(spy):toHaveBeenCalled()
    end)

    it('can spy on a nil property getter just fine', function()
      local obj = {foo = nil}
      local spy = jestronaut:spyOn(obj, 'foo', 'get')
      print(obj.foo)
      expect(spy):toHaveBeenCalled()
    end)
  end)
end)