-- .toBeDefined



local tests = {

    (function()
        -- Use `.toBeDefined` to check that a variable is not undefined. For example, if you want to check that a function `fetchNewFlavorIdea()` returns _something_, you can write:
        -- -- You could write `expect(fetchNewFlavorIdea()).not.toBe(undefined)`, but it's better practice to avoid referring to `undefined` directly in your code.
        test(
            "there is a new flavor idea",
            function()
                expect(fetchNewFlavorIdea()):toBeDefined()
            end
        )
    end)(),


}

return tests
