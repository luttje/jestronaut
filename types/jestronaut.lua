---@meta jestronaut

---@alias JestronautDone fun(err?: any)

---A test or hook function. Functions that take a `done` callback (or are wrapped with jestronaut:async) are asynchronous.
---@alias JestronautTestFunction fun(done?: JestronautDone)|JestronautAsyncFunction

---A function wrapped with jestronaut:async.
---@class JestronautAsyncFunction

---@class JestronautTestRunResults
---@field success boolean True if no test failed and the run did not bail.
---@field bailed boolean True if the run stopped early because of the `bail` option.
---@field totalCount number All tests, including skipped and todo tests.
---@field passedCount number
---@field failedCount number
---@field skippedCount number Skipped tests, not including todo tests.
---@field todoCount number
---@field duration number In seconds.

---@class JestronautEventLoop
---@field tick? fun() Called repeatedly while a test waits for done, e.g. to run one iteration of your event loop.
---@field external? boolean For applications that run their own loop: call jestronaut:tick() regularly instead.
---@field now? fun(): number The current time in seconds, used for timeouts. Defaults to os.clock.

---@class JestronautOptions
---@field roots string[] The directories that contain the tests.
---@field testPathIgnorePatterns? string[] Skip tests in files whose path contains one of these (or matches it, when written as /pattern/).
---@field testNamePattern? string Only run tests whose full name matches this Lua pattern.
---@field bail? number|boolean Stop after this many failed tests. 0 or false runs all tests, true is the same as 1.
---@field testTimeout? number Timeout in milliseconds for tests and hooks that take a done callback (default 5000).
---@field eventLoop? JestronautEventLoop How to wait for tests and hooks that take a done callback.
---@field exitOnFailure? boolean Exit the process with status code 1 when a test fails (default true where os.exit exists).
---@field passWithNoTests? boolean Pass when there are no tests.
---@field verbose? boolean Show every test.
---@field silent? boolean Hide what tests print.
---@field ci? boolean Print a plain log instead of redrawing the output (default: true when the CI environment variable is set).
---@field colors? boolean Use colors (default: false when NO_COLOR is set or TERM is "dumb").
---@field reporter? table A custom reporter.
---@field coverage? boolean Collect coverage with LuaCov.

---@class JestronautExpect
---@field ["not"] JestronautExpect Inverts the matcher that follows, e.g. expect(1)["not"]:toBe(2).
local Expect = {}

---Checks that the received value is the expected value: the same table, or an equal string, number, boolean or nil.
---@param expected any
function Expect:toBe(expected) end

---Checks that a number is close to the expected number: their difference is less than 10^-numDigits / 2.
---@param expected number
---@param numDigits? number Defaults to 2.
function Expect:toBeCloseTo(expected, numDigits) end

---Checks that the received value is not nil.
function Expect:toBeDefined() end

---Checks that the received value is false or nil.
function Expect:toBeFalsy() end

---@param expected number
function Expect:toBeGreaterThan(expected) end

---@param expected number
function Expect:toBeGreaterThanOrEqual(expected) end

---Checks that the received value is an instance of a class (a table), or has the type with the given name.
---@param class table|string
function Expect:toBeInstanceOf(class) end

---@param expected number
function Expect:toBeLessThan(expected) end

---@param expected number
function Expect:toBeLessThanOrEqual(expected) end

---Checks that the received value is NaN.
function Expect:toBeNaN() end

---Checks that the received value is nil.
function Expect:toBeNil() end

---The same as toBeNil.
function Expect:toBeNull() end

---Checks that the received value is neither false nor nil.
function Expect:toBeTruthy() end

---Checks the type of the received value, as returned by `type`. Mock functions count as functions.
---@param expected type
function Expect:toBeType(expected) end

---The same as toBeNil.
function Expect:toBeUndefined() end

---Checks that an array contains the item (compared like toBe), or that a string contains the substring.
---@param expected any
function Expect:toContain(expected) end

---Checks that an array contains an item that equals the expected item (compared like toEqual).
---@param expected any
function Expect:toContainEqual(expected) end

---Checks that the received value recursively equals the expected value. Metatables are ignored.
---@param ... any
function Expect:toEqual(...) end

---Checks that the mock function was called.
function Expect:toHaveBeenCalled() end

---@param times number
function Expect:toHaveBeenCalledTimes(times) end

---Checks that the mock function was called with these arguments at least once.
---@param ... any
function Expect:toHaveBeenCalledWith(...) end

---@param ... any
function Expect:toHaveBeenLastCalledWith(...) end

---@param nthCall number
---@param ... any
function Expect:toHaveBeenNthCalledWith(nthCall, ...) end

---@param ... any
function Expect:toHaveLastReturnedWith(...) end

---Checks the length of a table or string, as returned by the # operator.
---@param length number
function Expect:toHaveLength(length) end

---@param nthCall number
---@param ... any
function Expect:toHaveNthReturnedWith(nthCall, ...) end

---Checks that a table has a (nested) property like "a.b[1]", optionally with the given value.
---@param propertyPath string|any[]
---@param value? any
function Expect:toHaveProperty(propertyPath, value) end

function Expect:toHaveReturned() end

---@param times number
function Expect:toHaveReturnedTimes(times) end

---@param ... any
function Expect:toHaveReturnedWith(...) end

---Checks that a string matches a Lua pattern.
---@param pattern string
function Expect:toMatch(pattern) end

---Checks that a table has the properties of the expected table (recursively). Arrays must have the same length.
---@param expected table
function Expect:toMatchObject(expected) end

---Checks that the received value equals the expected value, with the same metatables at every level.
---@param expected any
function Expect:toStrictEqual(expected) end

---Checks that calling the function throws, optionally with a message containing the text (or matching it as a Lua
---pattern), or with an error that is an instance of the class.
---@param expected? string|table
function Expect:toThrow(expected) end

---The same as toThrow.
---@param expected? string|table
function Expect:toThrowError(expected) end

---A custom matcher for expect.extend. It receives the received value and the arguments passed to the matcher.
---@alias JestronautCustomMatcher fun(received: any, ...: any): { pass: boolean, message?: string|fun(isNot: boolean): string }

---@class JestronautExpectStatic
---@overload fun(...: any): JestronautExpect
---@field ["not"] JestronautExpectStatic Inverts the asymmetric matcher that follows.
local ExpectStatic = {}

---Matches anything except nil.
---@return table
function ExpectStatic:anything() end

---Matches values created with the class (a table), or with the given type name.
---@param classOrType table|type
---@return table
function ExpectStatic:any(classOrType) end

---Matches arrays that contain all of the items.
---@param items any[]
---@return table
function ExpectStatic:arrayContaining(items) end

---Matches numbers that are close to the number.
---@param number number
---@param numDigits? number
---@return table
function ExpectStatic:closeTo(number, numDigits) end

---Matches tables that have the properties of the table.
---@param properties table
---@return table
function ExpectStatic:objectContaining(properties) end

---Matches strings that contain the substring.
---@param substring string
---@return table
function ExpectStatic:stringContaining(substring) end

---Matches strings that match the Lua pattern.
---@param pattern string
---@return table
function ExpectStatic:stringMatching(pattern) end

---Matches several values, like those returned by a function.
---@param ... any
---@return table
function ExpectStatic:varargsMatching(...) end

---Checks that the test makes exactly this many assertions.
---@param count number
function ExpectStatic:assertions(count) end

---Checks that the test makes at least one assertion.
function ExpectStatic:hasAssertions() end

---Adds custom matchers.
---@param matchers table<string, JestronautCustomMatcher>
function ExpectStatic:extend(matchers) end

---Adds functions that decide whether two values are equal for toEqual. They return true or false, or nil to let
---the next tester or the default comparison decide.
---@param testers (fun(a: any, b: any): boolean?)[]
function ExpectStatic:addEqualityTesters(testers) end

---@class JestronautDescribe
---@overload fun(name: string, fn: fun())
local Describe = {}

---Runs only this describe (and other describes and tests marked only) in the test file.
---@param name string
---@param fn fun()
function Describe:only(name, fn) end

---Skips the tests in this describe.
---@param name string
---@param fn fun()
function Describe:skip(name, fn) end

---Creates a describe for each item in the table. The name can use %s, %d, %i, %f, %j, %o, %p, %# and $variable.
---@param items table
---@return fun(name: string, fn: fun(...: any))
function Describe:each(items) end

---@class JestronautTest
---@overload fun(name: string, fn: JestronautTestFunction, timeout?: number)
---@field concurrent JestronautTest Runs like test, one test after another.
---@field failing JestronautTest Passes when the test fails.
local Test = {}

---Runs only this test (and other tests and describes marked only) in the test file.
---@param name string
---@param fn JestronautTestFunction
---@param timeout? number
function Test:only(name, fn, timeout) end

---Skips this test.
---@param name string
---@param fn JestronautTestFunction
---@param timeout? number
function Test:skip(name, fn, timeout) end

---A test that passes when it fails.
---@param name string
---@param fn JestronautTestFunction
---@param timeout? number
function Test:failing(name, fn, timeout) end

---A test that is still to be written.
---@param name string
function Test:todo(name) end

---Creates a test for each item in the table. The name can use %s, %d, %i, %f, %j, %o, %p, %# and $variable.
---@param items table
---@return fun(name: string, fn: fun(...: any), timeout?: number)
function Test:each(items) end

---@class JestronautMock
---@field calls { args: any }[]
---@field results { type: "return", value: any }[]
---@field lastCall { args: any }?

---@class JestronautMockFunction
---@overload fun(...: any): ...
---@field mock JestronautMock
local MockFunction = {}

---@param name string
---@return JestronautMockFunction
function MockFunction:mockName(name) end

---@return string
function MockFunction:getMockName() end

---Forgets the calls and results.
---@return JestronautMockFunction
function MockFunction:mockClear() end

---Forgets the calls and results, and removes mocked implementations and return values.
---@return JestronautMockFunction
function MockFunction:mockReset() end

---Like mockReset, and puts the original back for spies.
function MockFunction:mockRestore() end

---@param fn function
---@return JestronautMockFunction
function MockFunction:mockImplementation(fn) end

---@param fn function
---@return JestronautMockFunction
function MockFunction:mockImplementationOnce(fn) end

---@return JestronautMockFunction
function MockFunction:mockReturnThis() end

---@param ... any
---@return JestronautMockFunction
function MockFunction:mockReturnValue(...) end

---@param ... any
---@return JestronautMockFunction
function MockFunction:mockReturnValueOnce(...) end

---Uses the implementation while the callback runs.
---@param fn function
---@param callback fun()
function MockFunction:withImplementation(fn, callback) end

---@class JestronautFakeTimersConfig
---@field doNotFake? string[] Functions to keep real: "os.time", "os.clock", "os.date", "setTimeout", "setInterval", "clearTimeout" or "clearInterval".
---@field now? number The fake system time to start at, in milliseconds.
---@field advanceTimers? boolean Let tests that wait for done move the fake time to their timers.

---@class Jestronaut
---@field version string
---@field results JestronautTestRunResults? The results of the last run.
---@field describe JestronautDescribe
---@field it JestronautTest
---@field test JestronautTest
---@field expect JestronautExpectStatic
---@field beforeAll fun(fn: JestronautTestFunction, timeout?: number)
---@field beforeEach fun(fn: JestronautTestFunction, timeout?: number)
---@field afterAll fun(fn: JestronautTestFunction, timeout?: number)
---@field afterEach fun(fn: JestronautTestFunction, timeout?: number)
local Jestronaut = {}

---@param options JestronautOptions
---@return Jestronaut
function Jestronaut:configure(options) end

---Registers the tests: by calling the function, which loads the test files, or by loading the given test files.
---@param testsOrRegistrar fun()|string[]
---@return Jestronaut
function Jestronaut:registerTests(testsOrRegistrar) end

---Runs the tests, then calls the callback with the results.
---@param onFinished? fun(results: JestronautTestRunResults)
---@return Jestronaut
function Jestronaut:runTests(onFinished) end

---Continues tests that wait for done, when the eventLoop option has `external` set. Returns true when done.
---@return boolean
function Jestronaut:tick() end

---Marks a test or hook function as asynchronous. Needed on Lua 5.1, where function(done) can't be detected.
---@param fn fun(done: JestronautDone)
---@return JestronautAsyncFunction
function Jestronaut:async(fn) end

---Puts describe, it, test, expect, the hooks and jestronaut in the global environment.
function Jestronaut:withGlobals() end

---@return table
function Jestronaut:getGlobals() end

---Retries failing tests in the current test file or describe.
---@param numRetries number
---@param options? { logErrorsBeforeRetry?: boolean }
function Jestronaut:retryTimes(numRetries, options) end

---Sets the default timeout, in milliseconds, for tests and hooks that take a done callback in the current test file or
---describe.
---@param timeout number
function Jestronaut:setTimeout(timeout) end

---Creates a mock function, optionally with an implementation.
---@param implementation? function
---@return JestronautMockFunction
function Jestronaut:fn(implementation) end

---Replaces a method with a mock function that calls it, or spies on getting or setting a property.
---@param object table
---@param key string
---@param accessType? "get"|"set"
---@return JestronautMockFunction
function Jestronaut:spyOn(object, key, accessType) end

---@param object table
---@param key any
---@param value any
function Jestronaut:replaceProperty(object, key, value) end

---@param value any
---@return boolean
function Jestronaut:isMockFunction(value) end

---Restores all spies and replaced properties.
function Jestronaut:restoreAllMocks() end

---Makes require return the result of the factory for the module.
---@param moduleName string
---@param factory? fun(): any
function Jestronaut:mock(moduleName, factory) end

---@param moduleName string
---@param factory? fun(): any
function Jestronaut:doMock(moduleName, factory) end

---@param moduleName string
---@return any
function Jestronaut:requireActual(moduleName) end

---@param moduleName string
---@return any
function Jestronaut:createMockFromModule(moduleName) end

function Jestronaut:resetModules() end

---@param fn fun()
function Jestronaut:isolateModules(fn) end

---Replaces os.time, os.clock and os.date with a fake clock, and adds setTimeout, setInterval, clearTimeout and
---clearInterval globals.
---@param config? JestronautFakeTimersConfig
---@return Jestronaut
function Jestronaut:useFakeTimers(config) end

---@return Jestronaut
function Jestronaut:useRealTimers() end

---@param milliseconds number
function Jestronaut:advanceTimersByTime(milliseconds) end

---@param steps? number
function Jestronaut:advanceTimersToNextTimer(steps) end

function Jestronaut:runAllTimers() end

function Jestronaut:runOnlyPendingTimers() end

function Jestronaut:clearAllTimers() end

---@return number
function Jestronaut:getTimerCount() end

---The fake system time in milliseconds.
---@return number
function Jestronaut:now() end

---@param milliseconds number
function Jestronaut:setSystemTime(milliseconds) end

---@return number
function Jestronaut:getRealSystemTime() end

---@type Jestronaut
jestronaut = nil

---@type JestronautDescribe
describe = nil

---@type JestronautTest
it = nil

---@type JestronautTest
test = nil

---@type JestronautExpectStatic
expect = nil

---@param fn JestronautTestFunction
---@param timeout? number
function beforeAll(fn, timeout) end

---@param fn JestronautTestFunction
---@param timeout? number
function beforeEach(fn, timeout) end

---@param fn JestronautTestFunction
---@param timeout? number
function afterAll(fn, timeout) end

---@param fn JestronautTestFunction
---@param timeout? number
function afterEach(fn, timeout) end

---Fake timer globals, available while jestronaut:useFakeTimers() is used.
---@param callback function
---@param delay? number In milliseconds.
---@param ... any Passed to the callback.
---@return number
function setTimeout(callback, delay, ...) end

---@param callback function
---@param delay? number In milliseconds.
---@param ... any Passed to the callback.
---@return number
function setInterval(callback, delay, ...) end

---@param id number
function clearTimeout(id) end

---@param id number
function clearInterval(id) end

return Jestronaut
