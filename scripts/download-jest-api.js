import fetch from 'node-fetch';
import fs from 'fs';

const ref = process.argv[2] || 'main';
const docsUrl = `https://api.github.com/repos/facebook/jest/contents/docs?ref=${ref}`;

const cacheDir = 'cache';

/**
 * Collects all URL's that may be API pages from the provided page URL.
 * 
 * @param {string} url
 */
async function getApiPages(url) {
  const response = await fetch(url);
  const json = await response.json();
  
  return json.filter(item => item.name.endsWith('API.md'))
    .map(item => ({
      name: item.name,
      url: item.download_url
    }));
}

async function main(docsUrl) {
  console.log('Downloading Jest API docs to cache...');

  if (!fs.existsSync(cacheDir))
    fs.mkdirSync(cacheDir);

  const apiPages = await getApiPages(docsUrl);

  await Promise.all(apiPages.map(async page => {
    const response = await fetch(page.url);
    const text = await response.text();
    const filePath = `${cacheDir}/${page.name}`;

    fs.writeFileSync(filePath, text);
  }));

  console.log('Done downloading to cache!');
}

main(docsUrl);