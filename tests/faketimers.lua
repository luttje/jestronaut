describe('fake timers', function()
    afterEach(function()
        jestronaut:useRealTimers()
    end)

    it('runs timers only when the fake time is advanced', function()
        jestronaut:useFakeTimers()

        local calls = {}
        setTimeout(function(value) table.insert(calls, value) end, 100, 'first')
        setTimeout(function(value) table.insert(calls, value) end, 50, 'second')

        expect(calls):toEqual({})

        jestronaut:advanceTimersByTime(60)
        expect(calls):toEqual({ 'second' })

        jestronaut:advanceTimersByTime(40)
        expect(calls):toEqual({ 'second', 'first' })
    end)

    it('repeats intervals until they are cleared', function()
        jestronaut:useFakeTimers()

        local count = 0
        local id = setInterval(function() count = count + 1 end, 10)

        jestronaut:advanceTimersByTime(35)
        expect(count):toBe(3)

        clearInterval(id)
        jestronaut:advanceTimersByTime(100)
        expect(count):toBe(3)
    end)

    it('does not run cleared timeouts', function()
        jestronaut:useFakeTimers()

        local ran = false
        local id = setTimeout(function() ran = true end, 10)
        clearTimeout(id)

        jestronaut:runAllTimers()
        expect(ran):toBe(false)
    end)

    it('runs all timers, including the ones they schedule', function()
        jestronaut:useFakeTimers()

        local calls = {}
        setTimeout(function()
            table.insert(calls, 'outer')
            setTimeout(function() table.insert(calls, 'inner') end, 1000)
        end, 10)

        jestronaut:runAllTimers()
        expect(calls):toEqual({ 'outer', 'inner' })
    end)

    it('stops runAllTimers when timers keep scheduling new ones', function()
        jestronaut:useFakeTimers()

        setInterval(function() end, 1)

        expect(function() jestronaut:runAllTimers() end):toThrow('assuming an infinite loop')
    end)

    it('runs only the pending timers, not the ones they schedule', function()
        jestronaut:useFakeTimers()

        local calls = {}
        setTimeout(function()
            table.insert(calls, 'pending')
            setTimeout(function() table.insert(calls, 'new') end, 0)
        end, 10)

        jestronaut:runOnlyPendingTimers()
        expect(calls):toEqual({ 'pending' })
        expect(jestronaut:getTimerCount()):toBe(1)
    end)

    it('advances to the next timer', function()
        jestronaut:useFakeTimers()

        local calls = {}
        setTimeout(function() table.insert(calls, 1) end, 100)
        setTimeout(function() table.insert(calls, 2) end, 200)

        jestronaut:advanceTimersToNextTimer()
        expect(calls):toEqual({ 1 })

        jestronaut:advanceTimersToNextTimer()
        expect(calls):toEqual({ 1, 2 })
    end)

    it('counts and clears timers', function()
        jestronaut:useFakeTimers()

        setTimeout(function() end, 10)
        setInterval(function() end, 10)
        expect(jestronaut:getTimerCount()):toBe(2)

        jestronaut:clearAllTimers()
        expect(jestronaut:getTimerCount()):toBe(0)
    end)

    it('fakes os.time, os.date and os.clock', function()
        local realClock = os.clock
        jestronaut:useFakeTimers({ now = 1000 * 1000 })

        expect(os.time()):toBe(1000)
        expect(os.date('!%Y-%m-%d', os.time())):toBe(os.date('!%Y-%m-%d', 1000))
        expect(os.time({ year = 2020, month = 1, day = 1, hour = 12 })):toBeType('number')

        local clockBefore = os.clock()
        jestronaut:advanceTimersByTime(2500)

        expect(os.time()):toBe(1002)
        expect(os.clock() - clockBefore):toBeCloseTo(2.5)
        expect(jestronaut:now()):toBe(1002500)

        jestronaut:useRealTimers()
        expect(os.clock):toBe(realClock)
        expect(rawget(_G, 'setTimeout')):toBeNil()
    end)

    it('sets the system time without running timers', function()
        jestronaut:useFakeTimers()

        local ran = false
        setTimeout(function() ran = true end, 10)
        jestronaut:setSystemTime(5000 * 1000)

        expect(os.time()):toBe(5000)
        expect(ran):toBe(false)
        expect(math.abs(jestronaut:getRealSystemTime() / 1000 - os.time({ year = 2000, month = 1, day = 1 })))
            :toBeGreaterThan(0)
    end)

    it('keeps the functions listed in doNotFake real', function()
        local realTime = os.time
        jestronaut:useFakeTimers({ doNotFake = { 'os.time', 'setInterval' } })

        expect(os.time):toBe(realTime)
        expect(rawget(_G, 'setInterval')):toBeNil()
        expect(setTimeout):toBeType('function')
    end)

    it('requires fake timers to be installed before advancing them', function()
        expect(function() jestronaut:advanceTimersByTime(10) end):toThrow('fake timers are not installed')
    end)

    it('lets tests wait for done on fake timers with advanceTimers', jestronaut:async(function(done)
        jestronaut:useFakeTimers({ advanceTimers = true })

        setTimeout(function()
            expect(os.time()):toBeType('number')
            done()
        end, 60 * 1000)
    end))
end)
