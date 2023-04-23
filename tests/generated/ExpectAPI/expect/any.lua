-- expect.any



local tests = {

	(function()
		-- `expect.any(constructor)` matches anything that was created with the given constructor or if it's a primitive that is of the passed type. You can use it inside `toEqual` or `toBeCalledWith` instead of a literal value. For example, if you want to check that a mock function is called with a number:
		-- 
		local ____lualib = require("lualib_bundle")
		local __TS__Class = ____lualib.__TS__Class
		local __TS__New = ____lualib.__TS__New
		local Cat = __TS__Class()
		Cat.name = "Cat"
		function Cat.prototype.____constructor(self)
		end
		local function getCat(fn)
		    return fn(__TS__New(Cat))
		end
		test(
		    "randocall calls its callback with a class instance",
		    function()
		        local mock = jestronaut:fn()
		        getCat(mock)
		        expect(mock):toHaveBeenCalledWith(expect:any(Cat))
		    end
		)
		local function randocall(fn)
		    return fn(math.floor(math.random() * 6 + 1))
		end
		test(
		    "randocall calls its callback with a number",
		    function()
		        local mock = jestronaut:fn()
		        randocall(mock)
		        expect(mock):toHaveBeenCalledWith(expect:any(Number))
		    end
		)
		
	
	end)(),
	

}

return tests