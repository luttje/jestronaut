# Jestronaut

A Lua library for testing your code. It tries to work similarly to [Jest](https://jestjs.io/).

## Testing

In order to match the Jest API, Jestronaut has a script that will scrape the Jest documentation and generate the tests for Jestronaut. You can run the script with `npm run generate-tests`. All tests in `src/generated-tests` will be overwritten.