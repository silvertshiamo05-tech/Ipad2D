// Render official free Live2D sample models to PNG with the official Cubism
// Web Core + pixi-live2d-display, driven by headless Chromium (Playwright).
// Used to produce screenshots of the models this project round-trips.
//
// Usage: node render_models.mjs <baseURL> <outDir> <name:model3url> [more...]
import { chromium } from 'playwright';
import fs from 'node:fs';

const [baseURL, outDir, ...pairs] = process.argv.slice(2);
fs.mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch({
  args: ['--use-gl=swiftshader', '--ignore-gpu-blocklist', '--no-sandbox'],
});
const page = await browser.newPage({ viewport: { width: 760, height: 960 }, deviceScaleFactor: 2 });
page.on('pageerror', e => console.log('PAGEERR', e.message));

for (const pair of pairs) {
  const i = pair.indexOf('=');
  const name = pair.slice(0, i), model = pair.slice(i + 1);
  const url = `${baseURL}/index.html?model=${encodeURIComponent(model)}&w=700&h=900`;
  try {
    await page.goto(url, { waitUntil: 'load', timeout: 60000 });
    await page.waitForFunction('window.__ok === true || window.__err !== null', { timeout: 60000 });
    const err = await page.evaluate('window.__err');
    if (err) { console.log(`FAIL ${name}: ${err.split('\n')[0]}`); continue; }
    const out = `${outDir}/${name}.png`;
    await page.locator('#c').screenshot({ path: out });
    console.log(`OK   ${name} -> ${out}`);
  } catch (e) {
    console.log(`FAIL ${name}: ${String(e).split('\n')[0]}`);
  }
}
await browser.close();
