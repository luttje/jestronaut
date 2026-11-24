package.path = "./libs/?.lua;" .. package.path -- Try our local version first

local exitCode = require "jestronaut/cli".run(args)

-- os.exit is looked up after the run, since LuaCov (the coverage option) replaces it to save its stats on exit
if exitCode ~= 0 then
    os.exit(exitCode)
end
