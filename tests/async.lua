-- For realistic testing we want some means of delaying functions.
-- Hence this tiny timer library
local timerLib = require("tests/support/timer")
JESTRONAUT_TIMER_LIBRARY = timerLib

describe('async', function()
    describe('non-async', function()
        it("should test basic math", function()
            expect(1 + 1):toEqual(2)
        end)

        test:failing("should fail Incorrect math", function()
            expect(1 + 1):toEqual(3)
        end)

        it:failing("should fail Incorrect math with other alias", function()
            expect(1 + 1):toEqual(3)
        end)
    end)

    describe('yes-async', function()
        itAsync("Async test with immediate resolution", function(done)
            expect(1 + 1):toEqual(2)
            done()  -- Immediately pass
        end)

        testAsync("Async test with delayed resolution", function(done)
            timerLib.setTimeout(1, function()
                expect(1 + 1):toEqual(2)
                done()
            end)
        end)

        testAsync("Async test with delayed resolutions should match expected assertion count", function(done)
            expect:assertions(2)

            expect(1 + 1):toEqual(2)
            timerLib.setTimeout(1, function()
                expect(2 + 2):toEqual(4)
                done()
            end)
        end)

        itAsync:failing("Async test with delayed resolution should fail if assertion count is not met", function(done)
            expect:assertions(2)

            expect(1 + 1):toEqual(2)
            timerLib.setTimeout(1, function()
                done()
            end)
        end)

        itAsync:failing("Async test with custom error", function(done)
            timerLib.setTimeout(1, function()
                done("Something went wrong")
            end)
        end)

        itAsync:failing("Async test with thrown error passed through", function(done)
            timerLib.setTimeout(1, function()
                local success, fault = pcall(function()
                    error("This is an async error")
                end)

                if not success then
                    done(fault)
                    return
                end

                done()
            end)
        end)

        itAsync:failing("Async test should timeout", function(done)
            timerLib.setTimeout(2, function()
                done() -- too late
            end)
        end, 1)
    end)
end)
