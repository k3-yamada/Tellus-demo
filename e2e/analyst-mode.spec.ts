import { expect, test } from '@playwright/test';

test.describe('Analyst mode', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForFunction(
      () => document.querySelectorAll('flt-semantics[role="checkbox"]').length >= 2,
      undefined,
      { timeout: 60_000 },
    );
  });

  test('activates analyst filters on tateyama', async ({ page }) => {
    await page.getByRole('radio', { name: 'Analyst' }).click();
    await page.getByRole('checkbox', { name: '立山室堂（斜面）' }).click();
    await expect(page.getByRole('checkbox', { name: '軌道: 全て' })).toBeVisible({
      timeout: 15_000,
    });
    await expect(page.getByRole('checkbox', { name: '偏波: 全て' })).toBeVisible({
      timeout: 15_000,
    });
    await expect(
      page.locator('flt-semantics[aria-label*="解析パネル"]').first(),
    ).toBeVisible({ timeout: 15_000 });
  });
});
