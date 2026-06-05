import { expect, test } from '@playwright/test';

async function openDashboard(page: import('@playwright/test').Page) {
  await page.goto('/');
  await page.waitForFunction(
    () => document.querySelectorAll('flt-semantics[role="checkbox"]').length >= 2,
    undefined,
    { timeout: 60_000 },
  );
}

async function timelineAriaLabel(page: import('@playwright/test').Page) {
  return page
    .locator('flt-semantics[aria-label*="衛星観測タイムライン"]')
    .first()
    .getAttribute('aria-label');
}

async function scrollCatalogToRegions(page: import('@playwright/test').Page) {
  for (let i = 0; i < 10; i += 1) {
    const found = await page
      .locator('flt-semantics')
      .filter({ hasText: '常願寺川流域' })
      .first()
      .isVisible()
      .catch(() => false);
    if (found) return;
    await page.mouse.wheel(0, 900);
    await page.waitForTimeout(150);
  }
}

test.describe('Architecture explainer', () => {
  test.beforeEach(async ({ page }) => {
    await openDashboard(page);
  });

  test('header opens tutorial overlay with three tabs', async ({ page }) => {
    await page.getByRole('button', { name: 'システム解説' }).click();
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'システム解説（チュートリアル）' }).first(),
    ).toBeVisible({ timeout: 10_000 });
    await expect(page.getByRole('tab', { name: '構成図' })).toBeVisible();
    await expect(page.getByRole('tab', { name: 'データフロー' })).toBeVisible();
    await expect(page.getByRole('tab', { name: '設計の強み' })).toBeVisible();
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'Flutter Web' }).first(),
    ).toBeVisible();
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'ステップ 1 / 3' }).first(),
    ).toBeVisible();
    await page.getByRole('button', { name: '閉じる' }).click();
    await expect(page.getByRole('button', { name: 'システム解説' })).toBeVisible();
  });

  test('toolbar architecture icon opens overlay and full page', async ({ page }) => {
    await page.getByRole('button', { name: 'アーキテクチャ' }).click();
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'システム構成の解説' }).first(),
    ).toBeVisible({ timeout: 10_000 });
    await page.getByRole('tab', { name: 'データフロー' }).click();
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'Fetch' }).first(),
    ).toBeVisible({ timeout: 10_000 });
    await page.getByRole('button', { name: '全画面で見る' }).click();
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'システム構成' }).first(),
    ).toBeVisible({ timeout: 10_000 });
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'docs/ARCHITECTURE.md' }).first(),
    ).toBeVisible();
  });

  test('design benefits tab toggles plain and technical copy', async ({ page }) => {
    await page.getByRole('button', { name: 'システム解説' }).click();
    await page.getByRole('tab', { name: '設計の強み' }).click();
    await expect(
      page.locator('flt-semantics[aria-label*="サーバーレス"]').first(),
    ).toBeVisible({ timeout: 10_000 });
    await page.getByRole('radio', { name: '技術' }).first().click();
    await expect(
      page.locator('flt-semantics[aria-label*="Firebase Hosting"]').first(),
    ).toBeVisible({ timeout: 10_000 });
  });
});

test.describe('Catalog and procurement', () => {
  test.beforeEach(async ({ page }) => {
    await openDashboard(page);
  });

  test('catalog page lists datasets and regions', async ({ page }) => {
    await page.getByRole('button', { name: 'カタログ' }).click();
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'データカタログ' }).first(),
    ).toBeVisible({ timeout: 10_000 });
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'Tellus SAR データセット' }).first(),
    ).toBeVisible();
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'PALSAR-2' }).first(),
    ).toBeVisible();
    await scrollCatalogToRegions(page);
    await expect(
      page.locator('flt-semantics').filter({ hasText: '常願寺川流域' }).first(),
    ).toBeVisible({ timeout: 10_000 });
    await page.getByRole('button', { name: '戻る' }).click();
    await expect(page.getByRole('button', { name: 'システム解説' })).toBeVisible();
  });

  test('procurement demo adds to cart and submits dry-run order', async ({ page }) => {
    await page.getByRole('button', { name: '調達デモ' }).click();
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'データ調達 (デモ)' }).first(),
    ).toBeVisible({ timeout: 10_000 });
    await page.getByRole('button', { name: 'カートに追加' }).first().click();
    await expect(page.getByRole('button', { name: 'カートから削除' }).first()).toBeVisible({
      timeout: 10_000,
    });
    for (let i = 0; i < 12; i += 1) {
      const orderButton = page.getByRole('button', { name: /デモ発注.*1.*件/ });
      if (await orderButton.count()) {
        await orderButton.first().scrollIntoViewIfNeeded();
        await orderButton.first().click();
        break;
      }
      await page.mouse.wheel(0, 700);
      await page.waitForTimeout(120);
    }
    await expect(
      page.locator('flt-semantics').filter({ hasText: 'デモ注文 ID' }).first(),
    ).toBeVisible({ timeout: 10_000 });
  });
});

test.describe('Scenario and playback', () => {
  test.beforeEach(async ({ page }) => {
    await openDashboard(page);
  });

  test('long-term scenario chip is selectable', async ({ page }) => {
    await page.getByRole('checkbox', { name: /長期/ }).click();
    await expect(page.getByRole('checkbox', { name: /長期/ })).toBeVisible();
  });

  test('timeline play advances observation date', async ({ page }) => {
    const slider = page.getByRole('slider');
    const box = await slider.boundingBox();
    expect(box).not.toBeNull();
    await page.mouse.click(box!.x + 8, box!.y + box!.height / 2);

    const before = await timelineAriaLabel(page);
    await page.getByRole('button', { name: '再生' }).click();
    await expect
      .poll(async () => timelineAriaLabel(page), { timeout: 15_000 })
      .not.toEqual(before);
  });
});
