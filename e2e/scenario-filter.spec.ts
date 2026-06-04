import { expect, test } from '@playwright/test';

test.describe('Scenario filters', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForFunction(
      () => document.querySelectorAll('flt-semantics[role="checkbox"]').length >= 2,
      undefined,
      { timeout: 60_000 },
    );
  });

  test('rainy season chip is selectable', async ({ page }) => {
    await page.getByRole('checkbox', { name: '梅雨' }).click();
    await expect(page.getByRole('checkbox', { name: '梅雨' })).toBeVisible();
  });
});
