const { test, expect } = require('@playwright/test');

test('hello world test', async ({ page }) => {
    await page.goto('https://kaido.helenfit.com');
    const title = await page.title();
    expect(title).toBe('Kaido-CSW');
});