import { expect, test, type Page } from '@playwright/test';

async function openDashboard(page: Page) {
  await page.goto('/');
  await page.waitForFunction(
    () => document.querySelectorAll('flt-semantics[role="checkbox"]').length >= 2,
    undefined,
    { timeout: 60_000 },
  );
}

test.describe('Disaster archive', () => {
  test.beforeEach(async ({ page }) => {
    await openDashboard(page);
  });

  test('opens via toolbar and lists events', async ({ page }) => {
    await page.getByRole('button', { name: '災害アーカイブ' }).click();
    await expect(
      page.locator('flt-semantics').filter({ hasText: '災害アーカイブ' }).first(),
    ).toBeVisible({ timeout: 10_000 });
    await expect(
      page.locator('flt-semantics').filter({ hasText: '能登半島地震' }).first(),
    ).toBeVisible({ timeout: 10_000 });
    await expect(
      page.locator('flt-semantics').filter({ hasText: '熱海' }).first(),
    ).toBeVisible();
  });
});

test.describe('Multi-sensor comparison', () => {
  test.beforeEach(async ({ page }) => {
    await openDashboard(page);
  });

  test('opens via toolbar and shows sensors and scenes', async ({ page }) => {
    await page.getByRole('button', { name: 'マルチセンサー比較' }).click();
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'マルチセンサー比較' }).first(),
    ).toBeVisible({ timeout: 10_000 });
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'PALSAR-2' }).first(),
    ).toBeVisible({ timeout: 10_000 });
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'ASNARO-1' }).first(),
    ).toBeVisible();
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'Landsat' }).first(),
    ).toBeVisible();
  });
});

test.describe('TelluSAR InSAR job', () => {
  test.beforeEach(async ({ page }) => {
    await openDashboard(page);
  });

  test('opens via toolbar, submits dry-run and shows interferogram', async ({ page }) => {
    await page.getByRole('button', { name: 'TelluSAR InSAR デモ' }).click();
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'TelluSAR InSAR デモ' }).first(),
    ).toBeVisible({ timeout: 10_000 });
    await expect(page.getByRole('button', { name: /TelluSAR ジョブ投入/ })).toBeVisible({
      timeout: 10_000,
    });

    await page.getByRole('button', { name: /TelluSAR ジョブ投入/ }).click();

    await expect
      .poll(
        async () =>
          (await page.locator('flt-semantics').filter({ hasText: 'SUCCEEDED' }).count()) > 0,
        { timeout: 20_000 },
      )
      .toBe(true);

    await expect(
      page.locator('flt-semantics').filter({ hasText: '干渉解析サマリー' }).first(),
    ).toBeVisible({ timeout: 10_000 });
    await expect(
      page.locator('flt-semantics').filter({ hasText: '平均コヒーレンス' }).first(),
    ).toBeVisible();
  });
});

test.describe('Industry template switcher', () => {
  test.beforeEach(async ({ page }) => {
    await openDashboard(page);
  });

  test('default Toyama template is loaded', async ({ page }) => {
    await expect(
      page.locator('flt-semantics').filter({ hasText: '富山インフラ監視' }).first(),
    ).toBeVisible({ timeout: 10_000 });
  });
});
