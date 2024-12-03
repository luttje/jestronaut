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
            -- Simulate an async operation
            local timer = os.time()
            while os.time() - timer < 1 do
                -- Simulate some work
            end
            done()
        end)

        itAsync:failing("Async test with custom error", function(done)
            local timer = os.time()
            while os.time() - timer < 1 do
                -- Simulate some work
            end
            done("Something went wrong")
        end)

        itAsync:failing("Async test with thrown error passed through", function(done)
            local success, fault = pcall(function()
                error("This is an async error")
            end)
            if not success then
                done(fault)
                return
            end

            done()
        end)

        itAsync:failing("Async test should timeout", function(done)
            -- Simulate an async operation
            local timer = os.time()
            while os.time() - timer < 2 do
                -- Simulate some work
                coroutine.yield()
            end
        end, 1)
    end)
end)
