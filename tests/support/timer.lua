-- For realistic testing we want some means of delaying functions.
-- Hence this tiny timer library
local timer = {
    timers = {},
}

--- Adds a delayed function to the timer.
--- @param delayInSeconds number
--- @param callback fun()
--- @return number # The timer ID
function timer.setTimeout(delayInSeconds, callback)
    local timerId = os.time() + delayInSeconds
    table.insert(timer.timers, { id = timerId, callback = callback })
    return timerId
end

--- Updates the timer library.
--- This should be called in a loop to ensure that the timers are executed.
function timer.update()
    local currentTime = os.time()
    for i = #timer.timers, 1, -1 do
        local timerData = timer.timers[i]
        if currentTime >= timerData.id then
            timerData.callback()
            table.remove(timer.timers, i)
        end
    end
end

return timer
