local discoveryLib = require "jestronaut/discovery"

local USAGE = [[
Usage: jestronaut [paths...] [options]

Runs the tests in the given test files. Directories are searched for test files, other paths only run the test files
whose path contains them. Without paths, the test files in the roots (default: the current directory) are run.

Options:
  --roots=<directory>                  Where to find test files (repeatable)
  --testMatch=<glob>                   File names of test files (repeatable, default: *_spec.lua *_test.lua
                                       *.spec.lua *.test.lua)
  --testPathIgnorePatterns=<text>      Skip test files whose path contains this (repeatable, /pattern/ for a Lua
                                       pattern)
  --testNamePattern=<pattern>          Only run tests whose full name matches this Lua pattern
  --bail[=<count>]                     Stop after this many failed tests (default: 1 when given without a count)
  --testTimeout=<milliseconds>         Timeout for tests that take a done callback (default: 5000)
  --verbose                            Show every test
  --silent                             Hide what tests print
  --ci / --no-ci                       Print a plain log, instead of redrawing the output (default: on when CI is set)
  --colors / --no-colors               Use colors (default: on, unless NO_COLOR is set)
  --passWithNoTests                    Pass when no tests are found
  --coverage                           Collect coverage with LuaCov
  --help                               Show this help
  --version                            Show the version of Jestronaut
]]

--- Options that can be given more than once, collected in a list.
local LIST_OPTIONS = {
    roots = true,
    testMatch = true,
    testPathIgnorePatterns = true,
    testPathPattern = true,
}

--- Options with a number value.
local NUMBER_OPTIONS = {
    testTimeout = true,
}

--- Parses command line arguments into runner options and the paths that were given.
--- @param args string[]
--- @return table options, string[] paths, table flags
local function parseArguments(args)
    local options, paths, flags = {}, {}, {}

    for _, argument in ipairs(args) do
        local key, value = argument:match("^%-%-([%w_]+)=(.*)$")

        if not key then
            key = argument:match("^%-%-([%w_%-]+)$")

            if key and key:sub(1, 3) == "no-" then
                key, value = key:sub(4), false
            elseif key then
                value = true
            end
        end

        if key == "help" or argument == "-h" then
            flags.help = true
        elseif key == "version" or argument == "-v" then
            flags.version = true
        elseif key then
            if value == "true" then
                value = true
            elseif value == "false" then
                value = false
            elseif NUMBER_OPTIONS[key] then
                value = tonumber(value) or value
            end

            if LIST_OPTIONS[key] then
                options[key] = options[key] or {}
                table.insert(options[key], value)
            else
                options[key] = value
            end
        else
            table.insert(paths, argument)
        end
    end

    return options, paths, flags
end

--- Runs Jestronaut from the command line.
--- @param args string[] The command line arguments.
--- @param overrides? table Options that take precedence over the arguments (used to test the command line).
--- @return number # The exit code: 0 when all tests passed, 1 otherwise.
local function run(args, overrides)
    local jestronaut = require "jestronaut"
    local options, paths, flags = parseArguments(args or {})

    if flags.help then
        print(USAGE)
        return 0
    elseif flags.version then
        print("Jestronaut " .. jestronaut.version)
        return 0
    end

    local testFiles = {}
    options.roots = options.roots or {}
    options.testPathPattern = options.testPathPattern or {}

    for _, path in ipairs(paths) do
        local pathType = discoveryLib.getPathType(path)

        if pathType == "file" then
            table.insert(testFiles, path)
        elseif pathType == "directory" then
            table.insert(options.roots, path)
        else
            table.insert(options.testPathPattern, path)
        end
    end

    -- Explicitly given test files are in the roots, so their tests are recognized
    for _, path in ipairs(testFiles) do
        table.insert(options.roots, (path:match("^(.*)[/\\][^/\\]*$") or "."))
    end

    if #options.roots == 0 then
        options.roots = { "./" }
    end

    for key, value in pairs(overrides or {}) do
        options[key] = value
    end

    -- The process exits with the code returned here, so runTests doesn't have to
    options.exitOnFailure = false

    -- Let test files require modules relative to the current directory, like the project's own code
    package.path = "./?.lua;./?/init.lua;" .. package.path

    jestronaut:withGlobals()

    local exitCode = 1

    jestronaut
        :configure(options)
        :registerTests(#testFiles > 0 and testFiles or nil)
        :runTests(function(results)
            exitCode = results.success and 0 or 1
        end)

    return exitCode
end

return {
    USAGE = USAGE,
    parseArguments = parseArguments,
    run = run,
}
