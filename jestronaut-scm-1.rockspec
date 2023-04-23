package = "jestronaut"
version = "scm-1"
source = {
   url = "git+https://github.com/luttje/jestronaut"
}
description = {
   summary = "Library for testing your Lua scripts.",
   detailed = "A Lua library for testing your scripts. It does for Lua what [Jest](https://jestjs.io/) does for JavaScript, with the same API.",
   homepage = "https://github.com/luttje/jestronaut",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      jestronaut = "src/jestronaut.lua",
      ["jestronaut.each"] = "src/jestronaut/each.lua",
      ["jestronaut.environment"] = "src/jestronaut/environment.lua",
      ["jestronaut.environment.describe"] = "src/jestronaut/environment/describe.lua",
      ["jestronaut.environment.init"] = "src/jestronaut/environment/init.lua",
      ["jestronaut.environment.options"] = "src/jestronaut/environment/options.lua",
      ["jestronaut.environment.state"] = "src/jestronaut/environment/state.lua",
      ["jestronaut.environment.test"] = "src/jestronaut/environment/test.lua",
      ["jestronaut.expect"] = "src/jestronaut/expect.lua",
      ["jestronaut.expect.asymmetricmatchers.any"] = "src/jestronaut/expect/asymmetricmatchers/any.lua",
      ["jestronaut.expect.asymmetricmatchers.anything"] = "src/jestronaut/expect/asymmetricmatchers/anything.lua",
      ["jestronaut.expect.asymmetricmatchers.arrayContaining"] = "src/jestronaut/expect/asymmetricmatchers/arrayContaining.lua",
      ["jestronaut.expect.asymmetricmatchers.asymmetricmatcher"] = "src/jestronaut/expect/asymmetricmatchers/asymmetricmatcher.lua",
      ["jestronaut.expect.asymmetricmatchers.closeTo"] = "src/jestronaut/expect/asymmetricmatchers/closeTo.lua",
      ["jestronaut.expect.asymmetricmatchers.objectContaining"] = "src/jestronaut/expect/asymmetricmatchers/objectContaining.lua",
      ["jestronaut.expect.asymmetricmatchers.stringContaining"] = "src/jestronaut/expect/asymmetricmatchers/stringContaining.lua",
      ["jestronaut.expect.asymmetricmatchers.stringMatching"] = "src/jestronaut/expect/asymmetricmatchers/stringMatching.lua",
      ["jestronaut.expect.asymmetricmatchers.varargsMatching"] = "src/jestronaut/expect/asymmetricmatchers/varargsMatching.lua",
      ["jestronaut.expect.init"] = "src/jestronaut/expect/init.lua",
      ["jestronaut.expect.matchers.toBe"] = "src/jestronaut/expect/matchers/toBe.lua",
      ["jestronaut.expect.matchers.toBeCloseTo"] = "src/jestronaut/expect/matchers/toBeCloseTo.lua",
      ["jestronaut.expect.matchers.toBeDefined"] = "src/jestronaut/expect/matchers/toBeDefined.lua",
      ["jestronaut.expect.matchers.toBeFalsy"] = "src/jestronaut/expect/matchers/toBeFalsy.lua",
      ["jestronaut.expect.matchers.toBeGreaterThan"] = "src/jestronaut/expect/matchers/toBeGreaterThan.lua",
      ["jestronaut.expect.matchers.toBeGreaterThanOrEqual"] = "src/jestronaut/expect/matchers/toBeGreaterThanOrEqual.lua",
      ["jestronaut.expect.matchers.toBeInstanceOf"] = "src/jestronaut/expect/matchers/toBeInstanceOf.lua",
      ["jestronaut.expect.matchers.toBeLessThan"] = "src/jestronaut/expect/matchers/toBeLessThan.lua",
      ["jestronaut.expect.matchers.toBeLessThanOrEqual"] = "src/jestronaut/expect/matchers/toBeLessThanOrEqual.lua",
      ["jestronaut.expect.matchers.toBeNaN"] = "src/jestronaut/expect/matchers/toBeNaN.lua",
      ["jestronaut.expect.matchers.toBeNil"] = "src/jestronaut/expect/matchers/toBeNil.lua",
      ["jestronaut.expect.matchers.toBeNull"] = "src/jestronaut/expect/matchers/toBeNull.lua",
      ["jestronaut.expect.matchers.toBeTruthy"] = "src/jestronaut/expect/matchers/toBeTruthy.lua",
      ["jestronaut.expect.matchers.toBeType"] = "src/jestronaut/expect/matchers/toBeType.lua",
      ["jestronaut.expect.matchers.toBeUndefined"] = "src/jestronaut/expect/matchers/toBeUndefined.lua",
      ["jestronaut.expect.matchers.toContain"] = "src/jestronaut/expect/matchers/toContain.lua",
      ["jestronaut.expect.matchers.toContainEqual"] = "src/jestronaut/expect/matchers/toContainEqual.lua",
      ["jestronaut.expect.matchers.toEqual"] = "src/jestronaut/expect/matchers/toEqual.lua",
      ["jestronaut.expect.matchers.toHaveBeenCalled"] = "src/jestronaut/expect/matchers/toHaveBeenCalled.lua",
      ["jestronaut.expect.matchers.toHaveBeenCalledTimes"] = "src/jestronaut/expect/matchers/toHaveBeenCalledTimes.lua",
      ["jestronaut.expect.matchers.toHaveBeenCalledWith"] = "src/jestronaut/expect/matchers/toHaveBeenCalledWith.lua",
      ["jestronaut.expect.matchers.toHaveBeenLastCalledWith"] = "src/jestronaut/expect/matchers/toHaveBeenLastCalledWith.lua",
      ["jestronaut.expect.matchers.toHaveBeenNthCalledWith"] = "src/jestronaut/expect/matchers/toHaveBeenNthCalledWith.lua",
      ["jestronaut.expect.matchers.toHaveLastReturnedWith"] = "src/jestronaut/expect/matchers/toHaveLastReturnedWith.lua",
      ["jestronaut.expect.matchers.toHaveLength"] = "src/jestronaut/expect/matchers/toHaveLength.lua",
      ["jestronaut.expect.matchers.toHaveNthReturnedWith"] = "src/jestronaut/expect/matchers/toHaveNthReturnedWith.lua",
      ["jestronaut.expect.matchers.toHaveProperty"] = "src/jestronaut/expect/matchers/toHaveProperty.lua",
      ["jestronaut.expect.matchers.toHaveReturned"] = "src/jestronaut/expect/matchers/toHaveReturned.lua",
      ["jestronaut.expect.matchers.toHaveReturnedTimes"] = "src/jestronaut/expect/matchers/toHaveReturnedTimes.lua",
      ["jestronaut.expect.matchers.toHaveReturnedWith"] = "src/jestronaut/expect/matchers/toHaveReturnedWith.lua",
      ["jestronaut.expect.matchers.toMatch"] = "src/jestronaut/expect/matchers/toMatch.lua",
      ["jestronaut.expect.matchers.toMatchObject"] = "src/jestronaut/expect/matchers/toMatchObject.lua",
      ["jestronaut.expect.matchers.toStrictEqual"] = "src/jestronaut/expect/matchers/toStrictEqual.lua",
      ["jestronaut.expect.matchers.toThrow"] = "src/jestronaut/expect/matchers/toThrow.lua",
      ["jestronaut.expect.matchers.toThrowError"] = "src/jestronaut/expect/matchers/toThrowError.lua",
      ["jestronaut.mock"] = "src/jestronaut/mock.lua",
      ["jestronaut.mock.init"] = "src/jestronaut/mock/init.lua",
      ["jestronaut.mock.mockfunction"] = "src/jestronaut/mock/mockfunction.lua",
      ["jestronaut.mock.mockmodule"] = "src/jestronaut/mock/mockmodule.lua",
      ["jestronaut.reporter"] = "src/jestronaut/reporter.lua",
      ["jestronaut.utils.functions"] = "src/jestronaut/utils/functions.lua",
      ["jestronaut.utils.metatables"] = "src/jestronaut/utils/metatables.lua",
      ["jestronaut.utils.strings"] = "src/jestronaut/utils/strings.lua",
      ["jestronaut.utils.styledtexts"] = "src/jestronaut/utils/styledtexts.lua",
      ["jestronaut.utils.tables"] = "src/jestronaut/utils/tables.lua",
   }
}
