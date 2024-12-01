-- expect.arrayContaining



local tests = {

    (function()
        describe(
            "arrayContaining",
            function()
                local expected = { "Alice", "Bob" }
                it(
                    "matches even if received contains additional elements",
                    function()
                        expect({ "Alice", "Bob", "Eve" }):toEqual(expect:arrayContaining(expected))
                    end
                )
                it(
                    "does not match if received does not contain expected elements",
                    function()
                        expect({ "Bob", "Eve" })["not"]:toEqual(expect:arrayContaining(expected))
                    end
                )
            end
        )
    end)(),


    (function()
        describe(
            "Beware of a misunderstanding! A sequence of dice rolls",
            function()
                local expected = {
                    1,
                    2,
                    3,
                    4,
                    5,
                    6
                }
                it(
                    "matches even with an unexpected number 7",
                    function()
                        expect({
                            4,
                            1,
                            6,
                            7,
                            3,
                            5,
                            2,
                            5,
                            4,
                            6
                        }):toEqual(expect:arrayContaining(expected))
                    end
                )
                it(
                    "does not match without an expected number 2",
                    function()
                        expect({
                            4,
                            1,
                            6,
                            7,
                            3,
                            5,
                            7,
                            5,
                            4,
                            6
                        })["not"]:toEqual(expect:arrayContaining(expected))
                    end
                )
            end
        )
    end)(),


}

return tests
