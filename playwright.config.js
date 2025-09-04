module.exports = {
  testDir: 'tests',
  timeout: 30000,
  use: {
    headless: true,
    browserName: 'chromium',
    // ignoreHTTPSErrors: true, // 忽略 SSL 憑證錯誤 (因為目前使用 staging 憑證)
  },
  reporter: [['list'], ['json', { outputFile: 'test-results.json' }]]
};