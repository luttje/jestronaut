// Accepts an argument like ./libs and generates a rockspec file
// in the current directory.
import fs from 'fs';
import path from 'path';

const srcDir = process.argv[2];

if (!srcDir) {
  throw new Error('Please provide a source directory');
}

const rockspecTemplateFile = path.resolve('jestronaut-scm-0.rockspec.template');
const rockspecTemplate = fs.readFileSync(rockspecTemplateFile, 'utf8');

const modulePlaceholderRegex = /\n(\s*){{\s*MODULES\s*}}/;
const indentation = rockspecTemplate.match(modulePlaceholderRegex)[1];

function walkBuildModules(dir) {
  const files = fs.readdirSync(dir);
  // sort to first do files, then directories
  files.sort((a, b) => {
    const statA = fs.statSync(path.join(dir, a));
    const statB = fs.statSync(path.join(dir, b));

    return (statA.isDirectory() && !statB.isDirectory()) ? 1
      : (!statA.isDirectory() && statB.isDirectory()) ? -1
        : 0;
  });

  return files.reduce((acc, file) => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    if (stat.isDirectory()) {
      return acc.concat(walkBuildModules(filePath));
    }
    if (stat.isFile()) {
      const moduleName = filePath
        .replace(new RegExp(`^${path.normalize(srcDir)}`), '')
        .replace(/^[\/\\]/, '')
        .replace(/\.lua$/, '')
        .replace(/\\/g, '/');
      const unixPath = filePath.replace(/\\/g, '/');
      return acc.concat(`${indentation}["${moduleName}"] = "${unixPath}",`);
    }
    return acc;
  }, []);
}

const modules = walkBuildModules(srcDir).join('\n');
const rockspec = rockspecTemplate.replace(modulePlaceholderRegex, `\n${modules}`);

fs.writeFileSync('jestronaut-scm-0.rockspec', rockspec);
