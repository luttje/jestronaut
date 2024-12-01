//
// Copies the files from inside libs/, and the tests/ directory, into the gmod-addon/ directory
// Takes a --clean argument to clean the destination locations first, or fails if the destination locations already exist
//
// Example usage:
//   node scripts/generate-gmod-addon.js --clean
//
import fs from 'fs';
import path from 'path';
import { zip } from 'zip-a-folder';

const addonDirectory = path.resolve('gmod-addon');
const intermediateDirectory = path.resolve(addonDirectory, 'lua');
const distDirectory = path.resolve('dist');

const filesAndDirsToCopy = [
  path.resolve('libs', 'jestronaut.lua'),
  path.resolve('libs', 'jestronaut'),
  path.resolve('tests'),
];

const clean = process.argv.includes('--clean');

// Check if any of the destinations exist
const destExists = filesAndDirsToCopy.some(
  (fileOrDir) => fs.existsSync(
    path.join(intermediateDirectory, path.basename(fileOrDir))
  )
);

if (!clean && destExists) {
  throw new Error('Destination files already exist! Use --clean to clear them first.');
}

if (clean) {
  filesAndDirsToCopy.forEach((fileOrDir) => {
    const dest = path
      .join(intermediateDirectory, path.basename(fileOrDir));

    if (fs.existsSync(dest)) {
      fs.rmSync(dest, { recursive: true });
    }
  });
}

function copyRecursiveSync(source, destination) {
  try {
    const exists = fs.existsSync(source);
    const stats = exists && fs.statSync(source);
    const isDirectory = exists && stats.isDirectory();

    if (isDirectory) {
      if (!fs.existsSync(destination)) {
        fs.mkdirSync(destination, { recursive: true });
      }

      fs.readdirSync(source).forEach((childItemName) => {
        const sourcePath = path.join(source, childItemName);
        const destPath = path.join(destination, childItemName);

        copyRecursiveSync(sourcePath, destPath);
      });
    } else {
      fs.copyFileSync(source, destination);
    }
  } catch (error) {
    console.error(`Error copying ${source} to ${destination}:`, error);
  }
}

filesAndDirsToCopy.forEach((fileOrDir) => {
  const dest = path.join(
    intermediateDirectory,
    path.basename(fileOrDir)
  );
  copyRecursiveSync(fileOrDir, dest);
});

zip(addonDirectory, path.resolve(distDirectory, 'gmod-addon.zip'), {
  destPath: 'jestronaut',
});
