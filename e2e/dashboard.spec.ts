import { expect, test } from '@playwright/test';

async function timelineAriaLabel(page: import('@playwright/test').Page) {
  return page
    .locator('flt-semantics[aria-label*="衛星観測タイムライン"]')
    .first()
    .getAttribute('aria-label');
}

test.describe('Tellus Infrastructure Monitor (Flutter Web)', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForFunction(
      () => document.querySelectorAll('flt-semantics[role="checkbox"]').length >= 2,
      undefined,
      { timeout: 60_000 },
    );
  });

  test('loads dashboard with summary card and map', async ({ page }) => {
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'TELLUS INFRASTRUCTURE MONITOR' }).first(),
    ).toBeVisible();
    await expect(
      page.locator('flt-semantics').filter({ hasText: '富山県インフラ SAR 衛星監視デモ' }).first(),
    ).toBeVisible();
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'データ品質' }).first(),
    ).toBeVisible();
    await expect(page.locator('flt-semantics[aria-label*="衛星観測タイムライン"]').first()).toBeVisible();

    await expect(page.getByRole('checkbox', { name: '常願寺川流域（佐々堤付近）' })).toBeVisible();
    await expect(page.getByRole('checkbox', { name: '立山室堂（斜面）' })).toBeVisible();

    const mapTileRequest = page.waitForResponse(
      (response) =>
        response.url().includes('tile.openstreetmap.org') && response.status() === 200,
      { timeout: 45_000 },
    );
    await page.mouse.wheel(0, 1);
    await mapTileRequest;

    const slider = page.getByRole('slider');
    await expect(slider).toBeVisible();
    const max = Number(await slider.getAttribute('aria-valuemax'));
    expect(max).toBeGreaterThanOrEqual(1);
  });

  test('switching region and moving timeline slider updates state', async ({ page }) => {
    await page.getByRole('checkbox', { name: '立山室堂（斜面）' }).click();
    await expect(page.locator('flt-semantics[aria-label*="斜面・地盤監視"]').first()).toBeVisible({
      timeout: 10_000,
    });

    const slider = page.getByRole('slider');
    const box = await slider.boundingBox();
    expect(box).not.toBeNull();

    const before = await timelineAriaLabel(page);
    await page.mouse.click(box!.x + 8, box!.y + box!.height / 2);
    await expect
      .poll(async () => timelineAriaLabel(page), { timeout: 10_000 })
      .not.toEqual(before);

    const mid = await timelineAriaLabel(page);
    await page.mouse.click(box!.x + box!.width - 8, box!.y + box!.height / 2);
    await expect
      .poll(async () => timelineAriaLabel(page), { timeout: 10_000 })
      .not.toEqual(mid);

    await page.getByRole('checkbox', { name: '常願寺川流域（佐々堤付近）' }).click();
    await expect(page.locator('flt-semantics[aria-label*="堤防インフラ監視"]').first()).toBeVisible({
      timeout: 10_000,
    });
  });

  test('Explorer/Analyst mode toggle is visible', async ({ page }) => {
    await expect(page.getByRole('radio', { name: 'Explorer' })).toBeVisible();
    await expect(page.getByRole('radio', { name: 'Analyst' })).toBeVisible();
  });
});
