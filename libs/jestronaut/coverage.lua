local callRespectingRequireOverride = require "jestronaut/utils/require".callRespectingRequireOverride

--- @param testRoots string[]
--- @param coverageDirectory string
--- @param coverageProvider string
local function setupCoverage(testRoots, coverageDirectory, coverageProvider)
  if coverageProvider ~= nil then
    error("Coverage provider is not supported yet.")
  end
  
  local statsFile, reportFile

  if coverageDirectory ~= nil then
    statsFile = coverageDirectory .. "/luacov.stats.out"
    reportFile = coverageDirectory .. "/luacov.report.out"

    -- We don't support this because running luacov inside ./coverage will cause it to not find the source files. 
    -- I have not found a way to prefix the paths in the stats file with ./coverage/ so that luacov can find the source files.
    error("Coverage directory is not supported yet.")
  end

  -- Pass modified require's on through
  local success, luacov = callRespectingRequireOverride(function()
    return pcall(require, 'luacov.runner')
  end)

  if not success then
    error("Could not load luacov. Make sure it is installed and available in your package.path or avoid using the --coverage option.")
  end

  local excludes = {}

  for _, testRoot in ipairs(testRoots) do
    -- Trim ./ from the start of the path
    testRoot = testRoot:gsub("^%./", "")

    table.insert(excludes, testRoot)
  end

  luacov.init({
    exclude = excludes,
    includeuntestedfiles = true,

    statsfile = statsFile,
    reportfile = reportFile,
  })
end

return {
  setupCoverage = setupCoverage,
}