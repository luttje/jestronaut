include("gmod-jestronaut.lua"):withGlobals()

local simplifiedReporter = callWithRequireCompat(function()
  return require "gmod-reporter".GmodReporter
end)

jestronaut
  :configure({
    roots = {
      "addons/jestronaut/lua/tests/",
      "addons/jestronaut/lua/tests/generated/",
    },

    reporter = simplifiedReporter
  })
  :registerTests(function()
    callWithRequireCompat(function()
      -- require "tests/generated/init" -- TODO: fails atm
      require "tests/init"
    end)
  end)
  :runTests()