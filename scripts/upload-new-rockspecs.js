import { execSync } from 'child_process';
import * as dotenv from 'dotenv'
import path from 'path';
import fs from 'fs';

dotenv.config();

const luarocks_api_key = process.env.LUAROCKS_API_KEY;

if (!luarocks_api_key) {
  throw new Error('Please provide a luarocks api key');
}

const packageName = 'jestronaut';
const onlineRockspecs = execSync(`luarocks search --porcelain ${packageName}`).toString();
const rockspecsDir = path.resolve('rockspecs');
const rockspecs = fs.readdirSync(rockspecsDir);
const uploadQueue = [];

rockspecs.forEach(rockspec => {
  const rockVersion = rockspec.match(/(\d+\.\d+-\d+)/)[0];
  const isOnline = onlineRockspecs.indexOf(rockVersion) !== -1;

  if (!isOnline)
    uploadQueue.push(path.join(rockspecsDir, rockspec));
});

if (uploadQueue.length) {
  console.log('Uploading...');
  
  uploadQueue.forEach(rockspecPath => {
    console.log(`Uploading ${rockspecPath}`);
    execSync(`luarocks upload ${rockspecPath} --api-key=${luarocks_api_key}`);
  });
} else {
  console.log('Nothing to upload. All rockspecs are online.');
}