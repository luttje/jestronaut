-- describe



local tests = {

    (function()
        -- `describe(name, fn)` creates a block that groups together several related tests. For example, if you have a `myBeverage` object that is supposed to be delicious but not sour, you could test it with:
        -- -- This isn't required - you can write the `test` blocks directly at the top level. But this can be handy if you prefer your tests to be organized into groups.
        local myBeverage = { delicious = true, sour = false }
        describe(
            "my beverage",
            function()
                test(
                    "is delicious",
                    function()
                        expect(myBeverage.delicious):toBeTruthy()
                    end
                )
                test(
                    "is not sour",
                    function()
                        expect(myBeverage.sour):toBeFalsy()
                    end
                )
            end
        )
    end)(),


    (function()
        -- You can also nest `describe` blocks if you have a hierarchy of tests:
        --
        local ____lualib = require("lualib_bundle")
        local __TS__New = ____lualib.__TS__New
        local __TS__ParseInt = ____lualib.__TS__ParseInt
        local function binaryStringToNumber(binString)
            if not string.match(binString, "^[01]+$") then
                error(
                    __TS__New(CustomError, "Not a binary number."),
                    0
                )
            end
            return __TS__ParseInt(binString, 2)
        end
        describe(
            "binaryStringToNumber",
            function()
                describe(
                    "given an invalid binary string",
                    function()
                        test(
                            "composed of non-numbers throws CustomError",
                            function()
                                expect(function() return binaryStringToNumber("abc") end):toThrow(CustomError)
                            end
                        )
                        test(
                            "with extra whitespace throws CustomError",
                            function()
                                expect(function() return binaryStringToNumber("  100") end):toThrow(CustomError)
                            end
                        )
                    end
                )
                describe(
                    "given a valid binary string",
                    function()
                        test(
                            "returns the correct number",
                            function()
                                expect(binaryStringToNumber("100")):toBe(4)
                            end
                        )
                    end
                )
            end
        )
    end)(),


}

return tests
