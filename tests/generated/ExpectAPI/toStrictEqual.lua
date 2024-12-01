-- .toStrictEqual



local tests = {

    (function()
        local ____lualib = require("lualib_bundle")
        local __TS__Class = ____lualib.__TS__Class
        local __TS__New = ____lualib.__TS__New
        local LaCroix = __TS__Class()
        LaCroix.name = "LaCroix"
        function LaCroix.prototype.____constructor(self, flavor)
            self.flavor = flavor
        end

        describe(
            "the La Croix cans on my desk",
            function()
                test(
                    "are not semantically the same",
                    function()
                        expect(__TS__New(LaCroix, "lemon")):toEqual({ flavor = "lemon" })
                        expect(__TS__New(LaCroix, "lemon"))["not"]:toStrictEqual({ flavor = "lemon" })
                    end
                )
            end
        )
    end)(),


}

return tests
