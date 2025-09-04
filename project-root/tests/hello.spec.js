const { test, expect } = require('@playwright/test');

test('hello world test', async ({ page }) => {
    await page.goto('http://localhost:3000'); // 替換為你的應用程式 URL
    const title = await page.title();
    expect(title).toBe('預期的標題'); // 替換為預期的標題
});