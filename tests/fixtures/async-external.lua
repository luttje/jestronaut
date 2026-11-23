-- Asynchronous tests for an application that runs its own loop and calls jestronaut:tick(), run by
-- tests/integration.lua with a fake event loop in ASYNC_LOOP.
local setTimeout = ASYNC_LOOP.setTimeout

it("waits for the host to call tick", jestronaut:async(function(done)
    print("from the test")

    setTimeout(50, function()
        expect(1):toBe(1)
        done()
    end)
end))

it("times out while the host calls tick", jestronaut:async(function(done) end), 100)

it("runs after the asynchronous tests", function() end)
