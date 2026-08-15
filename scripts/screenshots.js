// Regenerate docs/screenshots/ from the running app.
//
//   scripts/run-app.sh
//   NODE_PATH=/opt/node22/lib/node_modules node scripts/screenshots.js
//
// The solved and completion shots are real: the script plays the board out with
// Hint rather than faking a finished state.
const { chromium } = require('playwright');
const path = require('path');
const OUT = path.join(__dirname, '..', 'docs', 'screenshots');

(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
  const p = await b.newPage({ viewport: { width: 1280, height: 980 }, deviceScaleFactor: 2 });
  require('fs').mkdirSync(OUT, { recursive: true });
  // Clip to the content: these pages are much shorter than the viewport, and a
  // screenshot that is two-thirds empty background reads as a broken layout.
  const shot = async (name) => {
    const h = await p.evaluate(() => {
      // Ignore full-height wrappers — they stretch to the viewport and would
      // report the viewport height back as "content".
      const vh = window.innerHeight;
      let bottom = 0;
      document.querySelectorAll('body *').forEach(n => {
        const r = n.getBoundingClientRect();
        if (r.width > 2 && r.height > 2 && r.height < vh * 0.9 && r.bottom > bottom)
          bottom = r.bottom;
      });
      return Math.ceil(bottom + 28);
    });
    await p.screenshot({ path: `${OUT}/${name}.png`,
                         clip: { x: 0, y: 0, width: 1280, height: Math.min(h, 1400) } });
    console.log('  ->', name, `(${h}px)`);
  };

  await p.goto('http://127.0.0.1:8080/', { waitUntil: 'networkidle', timeout: 60000 });
  await p.waitForTimeout(2500);
  await shot('01-home');

  await p.getByText('Start medium game').first().click();
  await p.waitForSelector('.sd-cell', { timeout: 120000 });
  await p.waitForTimeout(3000);

  // Board with a filled square selected, so the same-digit highlight is visible.
  const cells = () => p.locator('.sd-cell').evaluateAll(ns => ns.map((n, i) => ({
    i, t: (n.querySelector('.sd-num')?.textContent || '').trim(),
    open: n.className.includes('sd-open') })));
  let c = await cells();
  const digits = {};
  c.filter(x => x.t).forEach(x => digits[x.t] = (digits[x.t] || 0) + 1);
  const best = Object.entries(digits).sort((a, b2) => b2[1] - a[1])[0][0];
  await p.locator('.sd-cell').nth(c.find(x => x.t === best).i).click();
  await p.waitForTimeout(2500);
  await shot('02-board');

  // Notes mode: pencil marks in an empty square.
  const empty = (await cells()).filter(x => x.t === '' && x.open)[0].i;
  await p.getByText('NOTES', { exact: true }).first().click();
  await p.waitForTimeout(1500);
  await p.locator('.sd-cell').nth(empty).click();
  await p.waitForTimeout(1500);
  for (const k of [0, 3, 6]) {                       // digits 1, 4, 7
    await p.locator('.sd-key').nth(k).click();
    await p.waitForTimeout(1600);
  }
  await shot('03-notes');
  await p.getByText('NOTES', { exact: true }).first().click();
  await p.waitForTimeout(1500);

  // Solve it with Hint so the completion page is a real one.
  console.log('  solving with Hint …');
  for (let i = 0; i < 90; i++) {
    const left = (await cells()).filter(x => x.t === '').length;
    if (!left) break;
    await p.getByText('HINT', { exact: true }).first().click();
    await p.waitForTimeout(700);
  }
  await p.waitForTimeout(2500);
  await shot('04-solved');

  const result = p.getByText('RESULT', { exact: true }).first();
  if (await result.count()) {
    await result.click();
    await p.waitForTimeout(3500);
    await shot('05-done');
  }

  // The three variant boards. Each is dealt fresh from Home and shot with one
  // square selected, so the rule the variant adds is visible in the highlight:
  // the diagonal wash, the region tint, the shared block.
  const variant = async (card, name, cells) => {
    await p.goto('http://127.0.0.1:8080/', { waitUntil: 'networkidle', timeout: 60000 });
    await p.waitForTimeout(2000);
    await p.locator(`${card} .sd-cta`).click();
    await p.waitForFunction(
      n => document.querySelectorAll('.sd-board [class*="sd-cell"]').length >= n,
      cells, { timeout: 180000 });
    await p.waitForTimeout(3000);
    // Select a filled square so the same-digit highlight is in the frame.
    const filled = p.locator('.sd-board [class*="sd-cell"]')
                    .filter({ has: p.locator('.sd-num') });
    if (await filled.count()) {
      await filled.nth(Math.floor((await filled.count()) / 2)).click();
      await p.waitForTimeout(2500);
    }
    await shot(name);
  };

  await variant('.sd-card-diag', '06-diagonal', 81);
  await variant('.sd-card-jig',  '07-jigsaw',   81);
  await variant('.sd-card-mix',  '08-mix',      225);

  await b.close();
})().catch(e => { console.error('FATAL', e.message); process.exit(1); });
