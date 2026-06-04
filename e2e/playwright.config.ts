import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: '.',
  timeout: 120_000,
  use: {
    baseURL: process.env.BASE_URL ?? 'http://127.0.0.1:8765',
    headless: true,
    viewport: { width: 1400, height: 900 },
  },
  webServer: process.env.BASE_URL
    ? undefined
    : {
        command: 'python3 -m http.server 8765',
        cwd: '../web_app/build/web',
        url: 'http://127.0.0.1:8765',
        reuseExistingServer: true,
        timeout: 120_000,
      },
});
