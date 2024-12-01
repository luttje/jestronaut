-- expect.hasAssertions



local tests = {

    (function()
        -- For example, let's say that we have a few functions that all deal with state. `prepareState` calls a callback with a state object, `validateState` runs on that state object, and `waitOnState` returns a promise that waits until all `prepareState` callbacks complete. We can test this with:
        -- -- The `expect.hasAssertions()` call ensures that the `prepareState` callback actually gets called.
        test(
            "prepareState prepares a valid state",
            function()
                expect:hasAssertions()
                prepareState(function(state)
                    expect(validateState(state)):toBeTruthy()
                end)
                return waitOnState()
            end
        )
    end)(),


}

return tests
