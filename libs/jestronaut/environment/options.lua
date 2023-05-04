local copy = require "jestronaut/utils/tables".copy

--- @class RunnerOptions
local RUNNER_DEFAULT_OPTIONS = {
  bail = 1,
  -- cache = true,
  -- changedFilesWithAncestor = true,
  -- changedSince = true,
  -- ci = false,
  -- clearCache = true,
  -- clearMocks = true,
  -- collectCoverageFrom = ".",
  -- colors = true,
  -- config = ".",
  -- coverage = true,
  -- coverageDirectory = ".",
  -- coverageProvider = "lua",
  -- debug = true,
  -- detectOpenHandles = true,
  -- env = "lua",
  -- errorOnDeprecated = true, 
  -- expand = true,
  -- filter = "",
  -- findRelatedTests = "", --spaceSeparatedListOfSourceFiles
  -- forceExit = true,
  -- help = true, -- shows help
  -- ignoreProjects = "", --project1 ... projectN
  -- init = true, -- creates a jest config file
  -- injectGlobals = true,
  -- json = true,
  -- lastCommit = true,
  -- listTests = true,
  -- logHeapUsage = true,
  -- maxConcurrency = 1,
  -- maxWorkers = 1,
  -- noStackTrace = true,
  -- notify = true,
  -- onlyChanged = true,
  -- openHandlesTimeout = 1000,
  -- outputFile = "",
  -- passWithNoTests = true,
  -- projects = "", --path1 ... pathN
  -- randomize = true,
  -- reporters = "",
  -- resetMocks = true,
  -- restoreMocks = true,
  -- roots = "",
  -- runInBand = true,
  -- runTestsByPath = true,
  -- seed = 1324,
  -- selectProjects = "", --project1 ... projectN
  -- setupFilesAfterEnv = "", --path1 ... pathN
  -- shard = true,
  -- showConfig = true,
  -- showSeed = true,
  -- silent = true,
  -- testEnvironmentOptions = "",
  -- testLocationInResults = true,
  -- testMatch = "",
  -- testNamePattern = "",
  --- @type string[]
  testPathIgnorePatterns = nil,
  -- testPathPattern = "",
  -- testRunner = "",
  -- testSequencer = "",
  -- testTimeout = 5000,
  -- updateSnapshot = true,
  -- useStderr = true,
  -- verbose = true,
  -- version = true,
  -- watch = true,
  -- watchAll = true,
  -- watchman = true,
  -- workerThreads = true,
}

--- @param options RunnerOptions
--- @return RunnerOptions
local function merge(options)
  local mergedOptions = copy(RUNNER_DEFAULT_OPTIONS)

  for key, value in pairs(options) do
    mergedOptions[key] = value
  end

  return mergedOptions
end

return {
  RUNNER_DEFAULT_OPTIONS = RUNNER_DEFAULT_OPTIONS,
  merge = merge
}