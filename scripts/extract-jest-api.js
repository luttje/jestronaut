import * as tstl from 'typescript-to-lua';
import path from 'path';
import fs from 'fs';

const cacheDirectory = 'cache';

/**
 * Converts a markdown file to an API object.
 * 
 * @param {file} file
 * @returns {object}
 */
function objectFromMarkdownFile(file) {
  const markdown = fs.readFileSync(file, 'utf8');
  
  return {
    file: path.basename(file),
    ...objectFromGlobalApiMarkdown(markdown)
  };
}

function objectFromGlobalApiMarkdown(markdown) {
  const exampleRegex = /(?<description>.*?:\s*)?(?<example>```js(?<attributes>([^\n]*))?[\s\S]*?```)(?<descriptionAfter>\s*[\s\S\.\w]*?\.)?(?=\n\n|$)/g;
  const functionRegex = /### `(?<functionName>[\w\.]+(?:[^`])*)\((?<parameters>[^)]*)\)`\s*(?<description>[\s\S]*?)\s*(?=###|$)/g;
  const aliasRegex = /Also (under the alias|under the aliases): (?<aliases>[\s\S]*?)(?=\n|$)/g;
  const attributeRegex = /(?<key>(\S*))=(?<value>(("[^"]*"))|([^\s]*))/g;
  const matches = [...markdown.matchAll(functionRegex)];

  const methods = matches.map(match => {
    const name = match.groups.functionName.split('(')[0].trim();
    const params = match.groups.parameters;
    const description = match.groups.description.trim();
    const examples = [];

    const aliases = [...description.matchAll(aliasRegex)].map(aliasMatch => aliasMatch.groups.aliases.split(', ').map(alias => alias.replace(/`/g, '')));
    const exampleMatches = [...description.matchAll(exampleRegex)];

    exampleMatches.forEach(exampleMatch => {
      let example = exampleMatch.groups.example;
      const description = exampleMatch.groups.description;
      const descriptionAfter = exampleMatch.groups.descriptionAfter;
      const attributes = {};
      
      const attributeMatches = [...example.split('\n')[0].matchAll(attributeRegex)];

      attributeMatches.forEach(attributeMatch => {
        const key = attributeMatch.groups.key;
        let value = attributeMatch.groups.value.replace(/"/g, '');

        if (key === 'title')
          value = value.replace(/\./g, '_');

        attributes[key] = value.trim('"');
      });

      examples.push({
        example: example.replace(/```js[^\n]*\n/, '').replace(/```[^\n]*\n|```$/, '').trim(),
        attributes,
        description: description?.trim() || '',
        descriptionAfter: descriptionAfter?.trim() || '',
      });
    });

    // Removes the examples and aliases from the description.
    const descriptionWithoutExamples = description.replace(exampleRegex, '').replace(aliasRegex, '').trim();

    return {
      name,
      aliases,
      params,
      descriptionWithoutExamples,
      examples,
    };
  });

  return {
    methods
  };
}

/**
 * Collects all API pages from the cache and returns them as objects.
 * 
 * @param {string} cacheDirectory
 * @returns {object[]}
 */
function getApi(cacheDirectory) {
  const files = fs.readdirSync(cacheDirectory, {
    withFileTypes: true
  });

  return files.filter(file => file.isFile() && file.name.endsWith('.md'))
    .map(file => ({
      file: file.name,
      ...objectFromMarkdownFile(`${cacheDirectory}/${file.name}`)
    }));
}

/**
 * Prefixes each line in a string with a prefix.
 * 
 * @param {string} string
 * @param {string} prefix
 * 
 * @returns {string}
 */
function prefixLines(string, prefix) {
  return string.split('\n').map(line => `${prefix}${line}`).join('\n');
}

function transpileString(main) {
  const { diagnostics, transpiledFiles } = tstl.transpileVirtualProject({
    "main.ts": main,
  }, {
    luaTarget: tstl.LuaTarget.Lua51,
    luaLibImport: tstl.LuaLibImportKind.Require,
    noHeader: true,
    noImplicitGlobalVariables: true,
    noImplicitSelf: true,
  });

  let file;
  let luaLibFile;

  transpiledFiles.forEach(transpiledFile => {
    if (transpiledFile.outPath === "lualib_bundle.lua")
      luaLibFile = transpiledFile;
    else if (transpiledFile.outPath === "main.lua")
      file = transpiledFile;
  });

  return {
    diagnostics,
    lua: file.lua,
    luaLib: luaLibFile?.lua,
  };
}

/**
 * Builds a Lua test from an examples.
 * 
 * @param {object} example
 * @param {string} testDirectory
 * 
 * @returns {string}
 */
function luaTestFromExample(example, testDirectory) {
  const { example: exampleCode, description, descriptionAfter } = example;
  const { lua, luaLib } = transpileString(exampleCode);

  const luaLibFilePath = path.join(testDirectory, 'lualib_bundle.lua');
  if (!fs.existsSync(luaLibFilePath) && luaLib)
    fs.writeFileSync(luaLibFilePath, luaLib);

  let comments = description ? prefixLines(`${description}\n`, '-- ') : '';
  comments += descriptionAfter ? prefixLines(descriptionAfter, '-- ') : '';

  // Match jest as a whole word and replace it with jestronaut
  let luaCode = lua.replace(/(?<!\w)jest(?!\w)/g, 'jestronaut');

  luaCode = luaCode.replaceAll(/require\(['"]([^'"]*)['"]\)/g, (match, p1) => {
    return `require('${p1.replace(/\.\/|\.+/g, '_')}')`;
  });

  return `${comments}\n${luaCode}`;
}

/**
 * Builds Lua tests from a list of examples.
 * 
 * @param {object} method
 * @param {string} testDirectory
 * 
 * @returns {string}
 */
function luaTestsFromMethod(method, testDirectory) {
  let packagePreLoads = '';
  
  let tests = method.examples.map((example, index) => {
    const luaTestBase = luaTestFromExample(example, testDirectory);
    let luaTest = luaTestBase;

    // Workarounds for specific methods.
    // In most cases Regex fixes because TypescriptToLua doesn't transpile them for us.
    const lineReplacements = [];

    if (method.name === 'describe') {
      // Workaround the fact of regex not being transpiled.
      // JS: if not /^[01]+$/:test(binString) then
      lineReplacements.push({ 'if not nil:test(binString) then': 'if not string.match(binString, "^[01]+$") then' });
    } else if (method.name === '.toMatch') {
      // JS:
      // expect(essayOnTheBestFlavor()).toMatch(/grapefruit/);
      // expect(essayOnTheBestFlavor()).toMatch(new RegExp('grapefruit'));
      lineReplacements.push({ 'expect(essayOnTheBestFlavor()):toMatch(nil)': 'expect(essayOnTheBestFlavor()):toMatch("grapefruit")' });
      lineReplacements.push({ 'expect(essayOnTheBestFlavor()):toMatch(__TS__New(RegExp, "grapefruit"))': '' }); // This line is not needed. 
    } else if (method.name === '.toHaveProperty') {
      // JS: 
      // - expect(houseForSale).toHaveProperty(['kitchen', 'amenities', 0], 'oven');
      // - expect(houseForSale).toHaveProperty('livingroom.amenities[0].couch[0][1].dimensions[0]', 20 );
      // - expect(houseForSale).toHaveProperty(['ceiling.height'], 'tall'); // mistake in the jest docs, should be 2
      lineReplacements.push({ 'expect(houseForSale):toHaveProperty({"kitchen", "amenities", 0}, "oven")': 'expect(houseForSale):toHaveProperty({"kitchen", "amenities", 1}, "oven")' });
      lineReplacements.push({ 'expect(houseForSale):toHaveProperty("livingroom.amenities[0].couch[0][1].dimensions[0]", 20)': `expect(houseForSale):toHaveProperty("livingroom.amenities[1].couch[1][2].dimensions[1]", 20)` });
      lineReplacements.push({ 'expect(houseForSale):toHaveProperty({"ceiling.height"}, "tall")': 'expect(houseForSale):toHaveProperty({"ceiling.height"}, 2)' });
    } else if (method.name === '.toBeInstanceOf') {
      lineReplacements.push({ 'expect(__TS__New(A)):toBeInstanceOf(Function)': '' }); // Only Javascript objects are also Functions, this is not the case in Lua.
    } else if (method.name === 'expect.stringMatching') {
      // JS:
      // - expect.stringMatching(/^Alic/)
      // - expect.stringMatching(/^[BR]ob/)
      lineReplacements.push({ 'expect:stringMatching(nil)': "expect:stringMatching('^Alic')" });
      lineReplacements.push({ 'expect:stringMatching(nil)': "expect:stringMatching('^[BR]ob')" });
    } else if (method.name === 'expect.not.stringMatching') {
      // JS: const expected = /Hello world!/;
      lineReplacements.push({ 'local expected = nil': 'local expected = "Hello world!"' });
    }
    
    for (const lineReplacement of lineReplacements) {
      const [ from, to ] = Object.entries(lineReplacement)[0];
      luaTest = luaTest.replace(from, to);
    }

    // Find top-level returns (no indentation before them), wrap them in a function, along with related code (up until first 3 empty newlines before it).
    const returnRegex = /(?<code>[\s\S]*?)(?<return>^return\s*[\s\S]*?)(?=\n\n\n|$)/gm;
    const containsExportRegex = /____module_0|module/g;
    // Match both test and it (followed by .*( so it also matches test.only and it.failing.each, etc)
    const containsTestRegex = /(test|it)(\s|\.\*)?\(/;
    const allMatches = [ ...luaTest.matchAll(returnRegex) ];
    
    for (const match of allMatches) {
      const { code, return: returnCode } = match.groups;
      let fullCode = prefixLines(`${code}${returnCode}`, '\t');

      // Replace the code with the fullCode wrapped in a test if it is not already wrapped in a test.
      luaTest = luaTest.replace(returnCode, '');

      if (!fullCode.match(containsTestRegex))
        fullCode = fullCode.replace(code, prefixLines(`test("${method.name} ${index}", function()\n${fullCode}\n\nend);\n`, '\t'));
      
      luaTest = luaTest.replace(code, `(function()\n${fullCode}\n\nend)(),\n`);
    }

    // If there were no returns matches in allMatches, wrap the whole test in a function that is immediately called.
    if (allMatches.length === 0) {
      luaTest = prefixLines(luaTest, '\t');
      
      if (!luaTest.match(containsTestRegex))
        luaTest = prefixLines(`test("${method.name} ${index}", function()\n${luaTest}\n\nend);\n`, '\t');
      
      luaTest = `(function()\n${luaTest}\n\nend)(),\n`;
    }

    // Check the attributes to see if if we need to preload it
    if (example.attributes['title']) {
      const title = example.attributes['title'];
      let luaTestWithExport = luaTestBase;
      const match = luaTestWithExport.match(containsExportRegex)
      
      // If it has an export, add a return that returns that export
      if (match) {
        luaTestWithExport = luaTestWithExport.replaceAll(/local ____module_0 = module/g, 'local exports = {}');
        luaTestWithExport = luaTestWithExport.replaceAll(/local ____module_0 =/g, 'local exports =');
        luaTestWithExport = luaTestWithExport.replaceAll(/module\.exports =/g, 'local exports =');
        luaTestWithExport = luaTestWithExport.replaceAll(/____module_0\.exports =/g, 'local exports =');
        luaTestWithExport = luaTestWithExport.replaceAll(/module\.exports =/g, 'local exports =');

        // if it doesnt already have a return, add one
        if (!luaTestWithExport.trimEnd().endsWith('return exports') && !luaTestWithExport.trimEnd().endsWith('return exports;')
          && !luaTestWithExport.trimEnd().endsWith('return ____exports') && !luaTestWithExport.trimEnd().endsWith('return ____exports;'))
          luaTestWithExport += `\nreturn exports`;
      }

      packagePreLoads += `generatedTestPreLoad('${title}', function()\n${prefixLines(luaTestWithExport, '\t')}\nend)\n\n`;

      // Dont use exports as tests
      luaTest = '';
    }

    if (luaTest.match(containsExportRegex)) {
      luaTest = luaTest.replaceAll(/local ____module_0 = module/g, 'local exports = {}');
      luaTest = luaTest.replaceAll(/local ____module_0 =/g, 'local exports =');
      luaTest = luaTest.replaceAll(/module\.exports =/g, 'local exports =');
      luaTest = luaTest.replaceAll(/____module_0\.exports =/g, 'local exports =');
      luaTest = luaTest.replaceAll(/module\.exports =/g, 'local exports =');
    }

    return luaTest;
  }).join('\n\n');

  tests = prefixLines(tests, '\t');

  return `${packagePreLoads}\n\nlocal tests = \{\n\n${tests}\n\n\}\n\nreturn tests`;
}

function main(cacheDirectory) {
  const testDirectory = path.join(cacheDirectory, 'tests');
  const allTestsFilePath = path.join(testDirectory, 'all.lua');
  console.log('Extracting Jest API docs from cache...');

  const apis = getApi(cacheDirectory);

  console.log('Done extracting from cache! Building tests...');

  // Clear the testDirectory we have only the latest version.
  if (fs.existsSync(testDirectory))
    fs.rmSync(testDirectory, { force: true, recursive: true });
  
  fs.mkdirSync(testDirectory, { recursive: true });

  fs.writeFileSync(allTestsFilePath, '');

  // Build Lua tests using all the examples.
  apis.forEach(api => {
    const apiDirectoryPath = api.file.replace('.md', '');
    const apiDirectory = path.join(testDirectory, apiDirectoryPath);

    if (!fs.existsSync(apiDirectory))
      fs.mkdirSync(apiDirectory, { recursive: true });

    api.methods.forEach(method => {
      const { name } = method;

      // Not supported due to problems with C - Lua interop. For example 'require' cant be called in an async function.
      if (name.endsWith('Async'))
        return;

      const testsFile = path.join(apiDirectory, `${name.replace(/\./g, '/')}.lua`);
      const tests = luaTestsFromMethod(method, testDirectory);

      // Also not supported due to same problem with async described above.
      if (tests.includes('__TS__AsyncAwaiter') || tests.includes('__TS__Await'))
        return;

      if (!fs.existsSync(path.dirname(testsFile)))
        fs.mkdirSync(path.dirname(testsFile), { recursive: true });
      
      fs.writeFileSync(testsFile, `-- ${name}\n\n${tests}`);
      fs.appendFileSync(allTestsFilePath, `require "${apiDirectoryPath}.${name}"\n`);
    });
  });

  return apis;
}

export default main(path.resolve(cacheDirectory));