-- .toBeInstanceOf



local tests = {

    (function()
        test(".toBeInstanceOf 0", function()
            local ____lualib = require("lualib_bundle")
            local __TS__Class = ____lualib.__TS__Class
            local __TS__New = ____lualib.__TS__New
            local A = __TS__Class()
            A.name = "A"
            function A.prototype.____constructor(self)
            end

            expect(__TS__New(A)):toBeInstanceOf(A)
            expect(function()
            end):toBeInstanceOf(Function)
        end);
    end)(),


}

return tests
