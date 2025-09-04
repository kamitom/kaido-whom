const { test, expect } = require('@playwright/test');

test('檢查網站是否有無效的URL', async ({ page }) => {
    // 監聽網路請求
    const failedRequests = [];
    const invalidUrls = [];
    
    page.on('response', response => {
        // 記錄失敗的請求
        if (!response.ok() && response.status() !== 404) {
            failedRequests.push({
                url: response.url(),
                status: response.status()
            });
        }
        
        // 檢查是否包含 localhost:1313
        if (response.url().includes('localhost:1313')) {
            invalidUrls.push({
                type: 'localhost:1313',
                url: response.url()
            });
        }
    });

    // 訪問主頁
    await page.goto('https://kaido.helenfit.com');
    
    // 等待頁面完全載入
    await page.waitForLoadState('networkidle');
    
    // 檢查頁面內容中的無效URL
    const pageContent = await page.content();
    
    // 檢查是否有 localhost:1313 引用
    const localhostMatches = pageContent.match(/localhost:1313/g);
    if (localhostMatches) {
        invalidUrls.push({
            type: 'content_localhost:1313',
            count: localhostMatches.length
        });
    }
    
    // 檢查是否有 LiveReload 腳本
    const livereloadMatches = pageContent.match(/livereload\.js/g);
    if (livereloadMatches) {
        invalidUrls.push({
            type: 'livereload_script',
            count: livereloadMatches.length
        });
    }
    
    // 檢查是否有 mindelay 參數
    const mindelayMatches = pageContent.match(/mindelay=/g);
    if (mindelayMatches) {
        invalidUrls.push({
            type: 'mindelay_params',
            count: mindelayMatches.length
        });
    }
    
    // 獲取頁面中所有的連結
    const links = await page.$$eval('a[href]', links => 
        links.map(link => link.href).filter(href => href)
    );
    
    // 檢查連結是否有效
    for (const link of links) {
        if (link.includes('localhost:1313')) {
            invalidUrls.push({
                type: 'link_localhost:1313',
                url: link
            });
        }
        
        // 檢查是否為外部連結或內部連結
        if (link.startsWith('https://kaido.helenfit.com') || link.startsWith('/')) {
            // 內部連結，可以進一步檢查
            continue;
        }
    }
    
    // 檢查 meta 標籤中的URL
    const metaUrls = await page.$$eval('meta[content*="http"]', metas =>
        metas.map(meta => meta.getAttribute('content')).filter(content => content)
    );
    
    for (const metaUrl of metaUrls) {
        if (metaUrl.includes('localhost:1313')) {
            invalidUrls.push({
                type: 'meta_localhost:1313',
                url: metaUrl
            });
        }
    }
    
    // 檢查 link 標籤中的URL
    const linkUrls = await page.$$eval('link[href]', links =>
        links.map(link => link.href).filter(href => href)
    );
    
    for (const linkUrl of linkUrls) {
        if (linkUrl.includes('localhost:1313')) {
            invalidUrls.push({
                type: 'link_tag_localhost:1313',
                url: linkUrl
            });
        }
    }
    
    // 輸出檢查結果
    console.log('\n=== URL 驗證報告 ===');
    console.log(`檢查的連結總數: ${links.length}`);
    console.log(`失敗的請求: ${failedRequests.length}`);
    console.log(`發現的無效URL: ${invalidUrls.length}`);
    
    if (failedRequests.length > 0) {
        console.log('\n失敗的請求:');
        failedRequests.forEach(req => {
            console.log(`  ${req.status}: ${req.url}`);
        });
    }
    
    if (invalidUrls.length > 0) {
        console.log('\n無效的URL:');
        invalidUrls.forEach(invalid => {
            console.log(`  ${invalid.type}: ${invalid.url || invalid.count + ' 個'}`);
        });
    }
    
    // 斷言檢查
    expect(invalidUrls, '不應該有 localhost:1313 引用').toHaveLength(0);
    expect(failedRequests, '不應該有失敗的請求（除了404）').toHaveLength(0);
});

test('檢查各個頁面的URL有效性', async ({ page }) => {
    const pagesToCheck = [
        '/',
        '/categories/',
        '/tags/',
        '/search/'
    ];
    
    const allInvalidUrls = [];
    
    for (const pagePath of pagesToCheck) {
        console.log(`檢查頁面: ${pagePath}`);
        
        try {
            await page.goto(`https://kaido.helenfit.com${pagePath}`);
            await page.waitForLoadState('networkidle');
            
            const pageContent = await page.content();
            
            // 檢查 localhost:1313
            const localhostCount = (pageContent.match(/localhost:1313/g) || []).length;
            if (localhostCount > 0) {
                allInvalidUrls.push({
                    page: pagePath,
                    type: 'localhost:1313',
                    count: localhostCount
                });
            }
            
            // 檢查 LiveReload
            const livereloadCount = (pageContent.match(/livereload/g) || []).length;
            if (livereloadCount > 0) {
                allInvalidUrls.push({
                    page: pagePath,
                    type: 'livereload',
                    count: livereloadCount
                });
            }
            
        } catch (error) {
            console.log(`頁面 ${pagePath} 檢查失敗: ${error.message}`);
        }
    }
    
    console.log('\n=== 多頁面URL驗證報告 ===');
    if (allInvalidUrls.length > 0) {
        console.log('發現問題:');
        allInvalidUrls.forEach(issue => {
            console.log(`  ${issue.page}: ${issue.type} (${issue.count} 個)`);
        });
    } else {
        console.log('所有頁面都沒有無效URL！');
    }
    
    expect(allInvalidUrls, '所有頁面都不應該有無效URL').toHaveLength(0);
});