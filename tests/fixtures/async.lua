-- Asynchronous tests and hooks, run by tests/integration.lua with a fake event loop in ASYNC_LOOP. They use
-- jestronaut:async, so they also run on Lua 5.1.
local CAN_COUNT_PARAMETERS = require "jestronaut/environment/async".CAN_COUNT_PARAMETERS
local async = function(fn) return jestronaut:async(fn) end
local setTimeout = ASYNC_LOOP.setTimeout

it("calls done right away", async(function(done)
    expect(1):toBe(1)
    done()
end))

it("calls done later", async(function(done)
    setTimeout(50, function()
        done()
    end)
end))

it("passes an error to done", async(function(done)
    setTimeout(10, function()
        done("something went wrong")
    end)
end))

it("never calls done", async(function(done) end), 100)

it("fails an expect in a callback", async(function(done)
    setTimeout(10, function()
        expect(1):toBe(2)
        done()
    end)
end))

it("counts assertions made in callbacks", async(function(done)
    expect:assertions(2)
    expect(1):toBe(1)

    setTimeout(10, function()
        expect(2):toBe(2)
        done()
    end)
end))

it("calls done more than once", async(function(done)
    done()
    done()
end))

it:failing("can be expected to fail", async(function(done)
    setTimeout(10, function()
        done("fails as expected")
    end)
end))

describe("async hooks", function()
    local value

    beforeEach(async(function(done)
        setTimeout(10, function()
            value = "ready"
            done()
        end)
    end))

    it("sees what an async beforeEach set up", function()
        expect(value):toBe("ready")
    end)
end)

if CAN_COUNT_PARAMETERS then
    it("detects functions that take done", function(done)
        setTimeout(10, done)
    end)
else
    it("explains how to mark functions on Lua 5.1", function(done)
        done()
    end)
end

it.concurrent("runs concurrent tests", function() end)
