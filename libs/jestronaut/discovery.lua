local stringsLib = require "jestronaut/utils/strings"

--- File names of test files, when the testMatch option isn't set.
local DEFAULT_TEST_MATCH = { "*_spec.lua", "*_test.lua", "*.spec.lua", "*.test.lua" }

--- Directories that never contain the project's own tests.
local IGNORED_DIRECTORIES = {
    ["node_modules"] = true,
    ["lua_modules"] = true,
}

--- Gets functions to list directories and check paths with, using LuaFileSystem or luv (as available in luvit).
--- Returns nil when neither is available.
--- @return { listDirectory: fun(path: string): { name: string, isDirectory: boolean }[], getPathType: fun(path: string): string? }?
local function getFileSystem()
    local hasLfs, lfs = pcall(require, "lfs")

    if hasLfs and type(lfs) == "table" and lfs.dir then
        return {
            listDirectory = function(path)
                local entries = {}

                for name in lfs.dir(path) do
                    if name ~= "." and name ~= ".." then
                        local attributes = lfs.attributes(path .. "/" .. name)

                        if attributes then
                            table.insert(entries, { name = name, isDirectory = attributes.mode == "directory" })
                        end
                    end
                end

                return entries
            end,
            getPathType = function(path)
                local attributes = lfs.attributes(path)

                return attributes and (attributes.mode == "directory" and "directory" or "file") or nil
            end,
        }
    end

    for _, moduleName in ipairs({ "luv", "uv" }) do
        local hasUv, uv = pcall(require, moduleName)

        if hasUv and type(uv) == "table" and uv.fs_scandir then
            return {
                listDirectory = function(path)
                    local entries = {}
                    local request = uv.fs_scandir(path)

                    while request do
                        local name, entryType = uv.fs_scandir_next(request)

                        if not name then
                            break
                        end

                        table.insert(entries, { name = name, isDirectory = entryType == "directory" })
                    end

                    return entries
                end,
                getPathType = function(path)
                    local stat = uv.fs_stat(path)

                    return stat and (stat.type == "directory" and "directory" or "file") or nil
                end,
            }
        end
    end
end

--- Converts a glob for file names to a Lua pattern: `*` matches any characters and `?` matches one character.
--- @param glob string
--- @return string
local function globToPattern(glob)
    local pattern = glob:gsub("[%^%$%(%)%%%.%[%]%+%-]", "%%%0"):gsub("%*", ".*"):gsub("%?", ".")

    return "^" .. pattern .. "$"
end

--- Checks whether a path matches any of the patterns. Like testPathIgnorePatterns, patterns that start and end with a
--- slash are Lua patterns, others are matched as plain text.
--- @param path string
--- @param patterns string[]
--- @return boolean
local function matchesAnyPathPattern(path, patterns)
    for _, pattern in ipairs(patterns) do
        local plain = not pattern:find("^/.*/$")
        pattern = plain and pattern or pattern:sub(2, -2)

        if path:find(pattern, 1, plain) then
            return true
        end
    end

    return false
end

--- Checks whether a file is a test file according to testMatch. Globs match the file name, patterns that start and end
--- with a slash are Lua patterns matched against the whole path.
--- @param path string
--- @param fileName string
--- @param testMatch string[]
--- @return boolean
local function isTestFile(path, fileName, testMatch)
    for _, match in ipairs(testMatch) do
        if match:find("^/.*/$") then
            if path:find(match:sub(2, -2)) then
                return true
            end
        elseif fileName:find(globToPattern(match)) then
            return true
        end
    end

    return false
end

--- Joins a directory and a name into a path.
--- @param directory string
--- @param name string
--- @return string
local function joinPath(directory, name)
    if directory:sub(-1) == "/" then
        return directory .. name
    end

    return directory .. "/" .. name
end

--- Finds the test files in the roots, sorted by path. Hidden directories (starting with a dot), node_modules and
--- lua_modules are skipped.
--- @param options { roots: string[], testMatch?: string|string[], testPathIgnorePatterns?: string[], testPathPattern?: string[] }
--- @return string[]
local function findTestFiles(options)
    local fileSystem = getFileSystem()

    if not fileSystem then
        error("Finding test files requires LuaFileSystem (luarocks install luafilesystem). You can also pass the " ..
            "test files to load to jestronaut:registerTests.", 2)
    end

    local testMatch = options.testMatch or DEFAULT_TEST_MATCH

    if type(testMatch) == "string" then
        testMatch = { testMatch }
    end

    local files, seen = {}, {}

    local function walk(directory)
        for _, entry in ipairs(fileSystem.listDirectory(directory)) do
            local path = joinPath(directory, entry.name)

            if entry.isDirectory then
                if entry.name:sub(1, 1) ~= "." and not IGNORED_DIRECTORIES[entry.name] then
                    walk(path)
                end
            elseif not seen[path] and isTestFile(path, entry.name, testMatch)
                and not matchesAnyPathPattern(path, options.testPathIgnorePatterns or {})
                and (not options.testPathPattern or #options.testPathPattern == 0
                    or matchesAnyPathPattern(path, options.testPathPattern)) then
                seen[path] = true
                table.insert(files, path)
            end
        end
    end

    for _, root in ipairs(options.roots) do
        root = stringsLib.normalizePath(root)

        if fileSystem.getPathType(root) == "directory" then
            walk(root)
        end
    end

    table.sort(files)

    return files
end

--- Gets whether the path is a "file" or "directory", or nil when it doesn't exist. Without LuaFileSystem or luv, it
--- can only tell whether a file can be opened.
--- @param path string
--- @return string?
local function getPathType(path)
    local fileSystem = getFileSystem()

    if fileSystem then
        return fileSystem.getPathType(path)
    end

    local file = io.open(path, "r")

    if file then
        file:close()

        return "file"
    end
end

return {
    DEFAULT_TEST_MATCH = DEFAULT_TEST_MATCH,
    findTestFiles = findTestFiles,
    getPathType = getPathType,
    globToPattern = globToPattern,
}
