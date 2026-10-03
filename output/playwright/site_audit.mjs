import { chromium, devices } from 'playwright';
import fs from 'node:fs/promises';
import path from 'node:path';

const outDir = path.resolve('output/playwright');
await fs.mkdir(outDir, { recursive: true });

const seeds = [
  { label: 'home', url: 'https://astrozura.com/' },
  { label: 'tarot', url: 'https://astrozura.com/services/tarot-reading' },
  { label: 'shop', url: 'https://shop.astrozura.com/' },
  { label: 'astrologers', url: 'https://astrozura.com/astrologers' },
  { label: 'kundali', url: 'https://astrozura.com/services/detailed-kundali' },
  { label: 'matchmaking', url: 'https://astrozura.com/services/detailed-matchmaking' },
  { label: 'panchang', url: 'https://astrozura.com/panchang?view=daily' },
  { label: 'vedic-calculators', url: 'https://astrozura.com/vedic-calculators' },
  { label: 'matching-calculators', url: 'https://astrozura.com/matching-calculators' },
  { label: 'rituals', url: 'https://astrozura.com/rituals' },
];

const viewports = [
  { name: 'mobile', width: 390, height: 844, isMobile: true, hasTouch: true },
  { name: 'desktop', width: 1366, height: 768, isMobile: false, hasTouch: false },
];

function cleanName(label) {
  return label.replace(/[^a-z0-9-]+/gi, '-') || 'page';
}

const browser = await chromium.launch({ headless: true });
const results = [];

for (const viewport of viewports) {
  const context = await browser.newContext({
    viewport: { width: viewport.width, height: viewport.height },
    isMobile: viewport.isMobile,
    hasTouch: viewport.hasTouch,
    userAgent: viewport.isMobile ? devices['Pixel 5'].userAgent : undefined,
  });

  for (const seed of seeds) {
    const page = await context.newPage();
    const consoleErrors = [];
    const failedRequests = [];
    const url = seed.url;

    page.on('console', (msg) => {
      if (['error', 'warning'].includes(msg.type())) {
        consoleErrors.push(`${msg.type()}: ${msg.text()}`.slice(0, 300));
      }
    });
    page.on('requestfailed', (request) => {
      failedRequests.push(`${request.method()} ${request.url()} ${request.failure()?.errorText || ''}`.slice(0, 300));
    });

    const started = Date.now();
    let status = null;
    let loadError = '';
    try {
      const response = await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 45000 });
      status = response?.status() ?? null;
      await page.waitForTimeout(7000);
    } catch (error) {
      loadError = error.message;
    }

    const metrics = await page.evaluate(() => {
      const doc = document.documentElement;
      const body = document.body;
      const selectors = Array.from(document.querySelectorAll('body *'));
      const overflow = selectors
        .map((el) => {
          const rect = el.getBoundingClientRect();
          return {
            tag: el.tagName.toLowerCase(),
            text: (el.innerText || el.alt || el.getAttribute('aria-label') || '').trim().replace(/\s+/g, ' ').slice(0, 90),
            left: Math.round(rect.left),
            right: Math.round(rect.right),
            width: Math.round(rect.width),
          };
        })
        .filter((item) => item.width > 0 && (item.left < -4 || item.right > window.innerWidth + 4))
        .slice(0, 8);
      const brokenImages = Array.from(document.images)
        .filter((img) => img.complete && img.naturalWidth === 0)
        .map((img) => img.src)
        .slice(0, 8);
      const skeletonCount = Array.from(document.querySelectorAll('*'))
        .filter((el) => {
          const cls = String(el.className || '');
          return /skeleton|animate-pulse|loading/i.test(cls);
        }).length;
      return {
        title: document.title,
        url: location.href,
        bodyText: (body.innerText || '').replace(/\s+/g, ' ').slice(0, 700),
        scrollWidth: doc.scrollWidth,
        clientWidth: doc.clientWidth,
        scrollHeight: doc.scrollHeight,
        brokenImages,
        overflow,
        skeletonCount,
      };
    }).catch((error) => ({ error: error.message }));

    const file = path.join(outDir, `${viewport.name}-${cleanName(seed.label)}.png`);
    await page.screenshot({ path: file, fullPage: false }).catch(() => {});

    results.push({
      viewport: viewport.name,
      route: seed.label,
      url,
      status,
      elapsedMs: Date.now() - started,
      loadError,
      consoleErrors,
      failedRequests,
      screenshot: file,
      ...metrics,
    });

    await page.close();
  }

  await context.close();
}

await browser.close();
await fs.writeFile(path.join(outDir, 'site-audit-results.json'), JSON.stringify(results, null, 2));
console.log(JSON.stringify(results.map((r) => ({
  viewport: r.viewport,
  route: r.route,
  status: r.status,
  elapsedMs: r.elapsedMs,
  width: `${r.clientWidth}/${r.scrollWidth}`,
  skeletonCount: r.skeletonCount,
  consoleErrors: r.consoleErrors?.length || 0,
  failedRequests: r.failedRequests?.length || 0,
  overflow: r.overflow?.length || 0,
  brokenImages: r.brokenImages?.length || 0,
  screenshot: r.screenshot,
})), null, 2));
