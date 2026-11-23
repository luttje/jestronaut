local unpack = table.unpack or unpack

--- The real time functions, kept before they can be replaced.
local realOsTime, realOsClock, realOsDate = os.time, os.clock, os.date

--- The functions that useFakeTimers replaces, as named in its `doNotFake` option.
local FAKEABLE_NAMES = { "os.time", "os.clock", "os.date", "setTimeout", "setInterval", "clearTimeout", "clearInterval" }

--- How many timers runAllTimers runs before it assumes timers keep scheduling new ones forever.
local MAX_TIMER_RUNS = 100000

--- The state of the installed fake timers, or nil when real timers are used.
local fake = nil

local function assertInstalled(functionName)
    if not fake then
        error(functionName .. " was called, but fake timers are not installed. Call jestronaut:useFakeTimers() first.", 3)
    end
end

--- Gets the pending timer that is due first (the earliest one scheduled when several are due at the same time).
--- @return table?
local function getNextTimer()
    local nextTimer

    for _, timer in pairs(fake.timers) do
        if not nextTimer or timer.at < nextTimer.at or (timer.at == nextTimer.at and timer.id < nextTimer.id) then
            nextTimer = timer
        end
    end

    return nextTimer
end

--- Moves the fake time to when the timer is due and runs it. Intervals are scheduled again.
--- @param timer table
local function runTimer(timer)
    fake.elapsed = math.max(fake.elapsed, timer.at)

    if timer.interval then
        timer.at = timer.at + math.max(timer.interval, 1)
    else
        fake.timers[timer.id] = nil
    end

    timer.callback(unpack(timer.args, 1, timer.args.n))
end

--- Schedules a timer and returns its id.
local function schedule(callback, delay, isInterval, ...)
    if type(callback) ~= "function" and not (type(callback) == "table" and getmetatable(callback)
            and getmetatable(callback).__call) then
        error("Expected a function to schedule, got " .. type(callback), 3)
    end

    delay = math.max(tonumber(delay) or 0, 0)

    local id = fake.nextId
    fake.nextId = fake.nextId + 1

    fake.timers[id] = {
        id = id,
        at = fake.elapsed + delay,
        interval = isInterval and delay or nil,
        callback = callback,
        args = { n = select("#", ...), ... },
    }

    return id
end

local fakeFunctions = {
    ["os.time"] = function(time)
        if time ~= nil then
            return realOsTime(time)
        end

        return math.floor((fake.systemTimeAtStart + fake.elapsed) / 1000)
    end,
    ["os.clock"] = function()
        return fake.clockAtStart + fake.elapsed / 1000
    end,
    ["os.date"] = function(format, time)
        if time == nil then
            time = math.floor((fake.systemTimeAtStart + fake.elapsed) / 1000)
        end

        return realOsDate(format or "%c", time)
    end,
    setTimeout = function(callback, delay, ...)
        return schedule(callback, delay, false, ...)
    end,
    setInterval = function(callback, delay, ...)
        return schedule(callback, delay, true, ...)
    end,
    clearTimeout = function(id)
        if id ~= nil then
            fake.timers[id] = nil
        end
    end,
    clearInterval = function(id)
        if id ~= nil then
            fake.timers[id] = nil
        end
    end,
}

--- Gets the table and key a fakeable name refers to, e.g. os and "time" for "os.time".
--- @param name string
--- @return table, string
local function getLocation(name)
    local tableName, key = name:match("^(%w+)%.(%w+)$")

    if tableName then
        return _G[tableName], key
    end

    return _G, name
end

--- Puts the real functions back and removes the fake timers, if they are installed.
local function uninstall()
    if not fake then
        return
    end

    for name, original in pairs(fake.originals) do
        local target, key = getLocation(name)
        target[key] = original.value
    end

    fake = nil
end

--- Replaces os.time, os.clock and os.date with a fake clock, and adds setTimeout, setInterval, clearTimeout and
--- clearInterval globals that schedule timers on it. Calling it again starts over with new fake timers.
--- @param config? { doNotFake?: string[], now?: number, advanceTimers?: boolean }
local function install(config)
    config = config or {}
    uninstall()

    local doNotFake = {}

    for _, name in ipairs(config.doNotFake or {}) do
        doNotFake[name] = true
    end

    fake = {
        elapsed = 0,
        systemTimeAtStart = config.now or realOsTime() * 1000,
        clockAtStart = realOsClock(),
        timers = {},
        nextId = 1,
        originals = {},
        advanceTimers = config.advanceTimers == true,
    }

    for _, name in ipairs(FAKEABLE_NAMES) do
        if not doNotFake[name] then
            local target, key = getLocation(name)

            fake.originals[name] = { value = rawget(target, key) }
            target[key] = fakeFunctions[name]
        end
    end
end

--- Runs the timers that are due within the given number of milliseconds, in the order they are due.
--- @param milliseconds number
local function advanceTimersByTime(milliseconds)
    assertInstalled("advanceTimersByTime")

    local target = fake.elapsed + math.max(tonumber(milliseconds) or 0, 0)

    while true do
        local timer = getNextTimer()

        if not timer or timer.at > target then
            break
        end

        runTimer(timer)
    end

    fake.elapsed = target
end

--- Moves the fake time to the next timer and runs the timers due then. Does this `steps` times (default 1).
--- @param steps? number
local function advanceTimersToNextTimer(steps)
    assertInstalled("advanceTimersToNextTimer")

    for _ = 1, steps or 1 do
        local timer = getNextTimer()

        if not timer then
            break
        end

        advanceTimersByTime(timer.at - fake.elapsed)
    end
end

--- Runs timers until none are left, including the ones they schedule.
local function runAllTimers()
    assertInstalled("runAllTimers")

    for _ = 1, MAX_TIMER_RUNS do
        local timer = getNextTimer()

        if not timer then
            return
        end

        runTimer(timer)
    end

    error("Aborting after running " .. MAX_TIMER_RUNS .. " timers, assuming an infinite loop!", 2)
end

--- Runs the timers that are pending now, but not the ones they schedule.
local function runOnlyPendingTimers()
    assertInstalled("runOnlyPendingTimers")

    local pending = {}

    for id in pairs(fake.timers) do
        pending[id] = true
    end

    while true do
        local nextTimer

        for id in pairs(pending) do
            local timer = fake.timers[id]

            if not timer then
                pending[id] = nil
            elseif not nextTimer or timer.at < nextTimer.at or (timer.at == nextTimer.at and timer.id < nextTimer.id) then
                nextTimer = timer
            end
        end

        if not nextTimer then
            return
        end

        pending[nextTimer.id] = nil
        runTimer(nextTimer)
    end
end

--- Removes all pending timers.
local function clearAllTimers()
    assertInstalled("clearAllTimers")

    fake.timers = {}
end

--- Gets the number of pending timers.
--- @return number
local function getTimerCount()
    assertInstalled("getTimerCount")

    local count = 0

    for _ in pairs(fake.timers) do
        count = count + 1
    end

    return count
end

--- Gets the fake system time in milliseconds.
--- @return number
local function now()
    assertInstalled("now")

    return fake.systemTimeAtStart + fake.elapsed
end

--- Sets the fake system time (as returned by os.time and os.date), in milliseconds. Timers are not affected.
--- @param milliseconds number
local function setSystemTime(milliseconds)
    assertInstalled("setSystemTime")

    fake.systemTimeAtStart = (tonumber(milliseconds) or realOsTime() * 1000) - fake.elapsed
end

--- Gets the real system time in milliseconds, even while fake timers are installed.
--- @return number
local function getRealSystemTime()
    return realOsTime() * 1000
end

--- Checks whether fake timers are installed.
--- @return boolean
local function isInstalled()
    return fake ~= nil
end

--- Gets an event loop (see the eventLoop option) that runs on the fake timers, for tests that wait for done while fake
--- timers with `advanceTimers` are installed. Each tick moves the fake time to the next timer, or 10 ms ahead when
--- there is none, so timeouts are reached too.
--- @return table?
local function getEventLoop()
    if not fake or not fake.advanceTimers then
        return nil
    end

    return {
        tick = function()
            local timer = getNextTimer()

            if timer then
                advanceTimersByTime(timer.at - fake.elapsed)
            else
                advanceTimersByTime(10)
            end
        end,
        now = function()
            return fake and fake.elapsed / 1000 or 0
        end,
    }
end

return {
    realOsClock = realOsClock,
    install = install,
    uninstall = uninstall,
    isInstalled = isInstalled,
    advanceTimersByTime = advanceTimersByTime,
    advanceTimersToNextTimer = advanceTimersToNextTimer,
    runAllTimers = runAllTimers,
    runOnlyPendingTimers = runOnlyPendingTimers,
    clearAllTimers = clearAllTimers,
    getTimerCount = getTimerCount,
    now = now,
    setSystemTime = setSystemTime,
    getRealSystemTime = getRealSystemTime,
    getEventLoop = getEventLoop,
}
