-- expect.extend

generatedTestPreLoad('toBeWithinRange_js', function()
    -- You can use `expect.extend` to add your own matchers to Jest. For example, let's say that you're testing a number utility library and you're frequently asserting that numbers appear within particular ranges of other numbers. You could abstract that into a `toBeWithinRange` matcher:
    -- -- ```js title="__tests__/ranges.test.js"
    -- import {expect, test} from '@jest/globals';
    -- import '../toBeWithinRange';
    --
    -- test('is within range', () => expect(100).toBeWithinRange(90, 110));
    --
    -- test('is NOT within range', () => expect(101).not.toBeWithinRange(0, 100));
    --
    -- test('asymmetric ranges', () => {
    --   expect({apples: 6, bananas: 3}).toEqual({
    --     apples: expect.toBeWithinRange(1, 10),
    --     bananas: expect.not.toBeWithinRange(11, 20),
    --   });
    -- });
    -- ```
    --
    -- ```ts title="toBeWithinRange.d.ts"
    -- // optionally add a type declaration, e.g. it enables autocompletion in IDEs
    -- declare module 'expect' {
    --   interface AsymmetricMatchers {
    --     toBeWithinRange(floor: number, ceiling: number): void;
    --   }
    --   interface Matchers<R> {
    --     toBeWithinRange(floor: number, ceiling: number): R;
    --   }
    -- }
    --
    -- export {};
    -- ```
    --
    -- ```ts tab={"span":2} title="toBeWithinRange.ts"
    -- import {expect} from '@jest/globals';
    -- import type {MatcherFunction} from 'expect';
    --
    -- const toBeWithinRange: MatcherFunction<[floor: unknown, ceiling: unknown]> =
    --   // `floor` and `ceiling` get types from the line above
    --   // it is recommended to type them as `unknown` and to validate the values
    --   function (actual, floor, ceiling) {
    --     if (
    --       typeof actual !== 'number' ||
    --       typeof floor !== 'number' ||
    --       typeof ceiling !== 'number'
    --     ) {
    --       throw new Error('These must be of type number!');
    --     }
    --
    --     const pass = actual >= floor && actual <= ceiling;
    --     if (pass) {
    --       return {
    --         message: () =>
    --           // `this` context will have correct typings
    --           `expected ${this.utils.printReceived(
    --             actual,
    --           )} not to be within range ${this.utils.printExpected(
    --             `${floor} - ${ceiling}`,
    --           )}`,
    --         pass: true,
    --       };
    --     } else {
    --       return {
    --         message: () =>
    --           `expected ${this.utils.printReceived(
    --             actual,
    --           )} to be within range ${this.utils.printExpected(
    --             `${floor} - ${ceiling}`,
    --           )}`,
    --         pass: false,
    --       };
    --     }
    --   };
    --
    -- expect.extend({
    --   toBeWithinRange,
    -- });
    --
    -- declare module 'expect' {
    --   interface AsymmetricMatchers {
    --     toBeWithinRange(floor: number, ceiling: number): void;
    --   }
    --   interface Matchers<R> {
    --     toBeWithinRange(floor: number, ceiling: number): R;
    --   }
    -- }
    -- ```
    --
    -- ```ts tab title="__tests__/ranges.test.ts"
    -- import {expect, test} from '@jest/globals';
    -- import '../toBeWithinRange';
    --
    -- test('is within range', () => expect(100).toBeWithinRange(90, 110));
    --
    -- test('is NOT within range', () => expect(101).not.toBeWithinRange(0, 100));
    --
    -- test('asymmetric ranges', () => {
    --   expect({apples: 6, bananas: 3}).toEqual({
    --     apples: expect.toBeWithinRange(1, 10),
    --     bananas: expect.not.toBeWithinRange(11, 20),
    --   });
    -- });
    -- ```
    --
    -- :::tip
    --
    -- The type declaration of the matcher can live in a `.d.ts` file or in an imported `.ts` module (see JS and TS examples above respectively). If you keep the declaration in a `.d.ts` file, make sure that it is included in the program and that it is a valid module, i.e. it has at least an empty `export {}`.
    local ____lualib = require("lualib_bundle")
    local Error = ____lualib.Error
    local RangeError = ____lualib.RangeError
    local ReferenceError = ____lualib.ReferenceError
    local SyntaxError = ____lualib.SyntaxError
    local TypeError = ____lualib.TypeError
    local URIError = ____lualib.URIError
    local __TS__New = ____lualib.__TS__New
    local ____exports = {}
    local ____globals = require("@jestronaut_globals")
    local expect = ____globals.expect
    local function toBeWithinRange(actual, floor, ceiling)
        if type(actual) ~= "number" or type(floor) ~= "number" or type(ceiling) ~= "number" then
            error(
                __TS__New(Error, "These must be of type number!"),
                0
            )
        end
        local pass = actual >= floor and actual <= ceiling
        if pass then
            return {
                message = function() return (("expected " .. tostring(self.utils:printReceived(actual))) .. " not to be within range ") ..
                    tostring(self.utils:printExpected((tostring(floor) .. " - ") .. tostring(ceiling))) end,
                pass = true
            }
        else
            return {
                message = function() return (("expected " .. tostring(self.utils:printReceived(actual))) .. " to be within range ") ..
                    tostring(self.utils:printExpected((tostring(floor) .. " - ") .. tostring(ceiling))) end,
                pass = false
            }
        end
    end
    expect:extend({ toBeWithinRange = toBeWithinRange })
    return ____exports
end)



local tests = {



    (function()
        -- Instead of importing `toBeWithinRange` module to the test file, you can enable the matcher for all tests by moving the `expect.extend` call to a [`setupFilesAfterEnv`](Configuration.md/#setupfilesafterenv-array) script:
        --
        local ____exports = {}
        local ____globals = require("@jestronaut_globals")
        local expect = ____globals.expect
        local ____toBeWithinRange = require("toBeWithinRange")
        local toBeWithinRange = ____toBeWithinRange.toBeWithinRange
        expect:extend({ toBeWithinRange = toBeWithinRange })
        return ____exports
    end)(),



}

return tests
