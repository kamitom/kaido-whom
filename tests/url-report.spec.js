const { test, expect } = require('@playwright/test');

test('生成詳細的URL檢查報告', async ({ page }) => {
    console.log('\n🔍 開始詳細的URL檢查...\n');
    
    await page.goto('https://kaido.helenfit.com');
    await page.waitForLoadState('networkidle');
    
    // 檢查所有 meta 標籤中的 URL
    const metaUrls = await page.$$eval('meta[content*="http"], meta[content*="//"]', metas =>
        metas.map(meta => ({
            name: meta.getAttribute('name') || meta.getAttribute('property') || 'unknown',
            content: meta.getAttribute('content')
        })).filter(meta => meta.content && (meta.content.includes('http') || meta.content.includes('//')))
    );
    
    // 檢查所有 link 標籤
    const linkTags = await page.$$eval('link[href]', links =>
        links.map(link => ({
            rel: link.getAttribute('rel'),
            href: link.href,
            type: link.getAttribute('type') || ''
        }))
    );
    
    // 檢查所有 a 標籤
    const anchorLinks = await page.$$eval('a[href]', anchors =>
        anchors.map(anchor => ({
            href: anchor.href,
            text: anchor.textContent.trim().substring(0, 50),
            title: anchor.getAttribute('title') || ''
        }))
    );
    
    // 檢查所有 script 標籤
    const scriptTags = await page.$$eval('script[src]', scripts =>
        scripts.map(script => script.src).filter(src => src)
    );
    
    // 檢查所有 img 標籤
    const imageTags = await page.$$eval('img[src]', images =>
        images.map(img => ({
            src: img.src,
            alt: img.getAttribute('alt') || ''
        }))
    );
    
    console.log('📋 URL檢查報告:');
    console.log('==================================================');
    
    console.log(`\n📍 Meta 標籤 URL (${metaUrls.length} 個):`);
    metaUrls.forEach(meta => {
        const status = meta.content.includes('localhost:1313') ? '❌' : '✅';
        console.log(`  ${status} ${meta.name}: ${meta.content}`);
    });
    
    console.log(`\n🔗 Link 標籤 (${linkTags.length} 個):`);
    linkTags.forEach(link => {
        const status = link.href.includes('localhost:1313') ? '❌' : '✅';
        console.log(`  ${status} ${link.rel}: ${link.href} ${link.type}`);
    });
    
    console.log(`\n🌐 錨點連結 (${anchorLinks.length} 個):`);
    anchorLinks.forEach(anchor => {
        const status = anchor.href.includes('localhost:1313') ? '❌' : '✅';
        console.log(`  ${status} "${anchor.text}" -> ${anchor.href}`);
    });
    
    console.log(`\n📜 腳本連結 (${scriptTags.length} 個):`);
    scriptTags.forEach(script => {
        const status = script.includes('localhost:1313') || script.includes('livereload') ? '❌' : '✅';
        console.log(`  ${status} ${script}`);
    });
    
    console.log(`\n🖼️ 圖片連結 (${imageTags.length} 個):`);
    imageTags.forEach(img => {
        const status = img.src.includes('localhost:1313') ? '❌' : '✅';
        console.log(`  ${status} ${img.alt || 'no-alt'}: ${img.src}`);
    });
    
    // 檢查頁面HTML源碼中的問題
    const pageContent = await page.content();
    const issues = [];
    
    if (pageContent.includes('localhost:1313')) {
        issues.push('包含 localhost:1313 引用');
    }
    
    if (pageContent.includes('livereload')) {
        issues.push('包含 livereload 腳本');
    }
    
    if (pageContent.includes('mindelay=')) {
        issues.push('包含 LiveReload 參數');
    }
    
    console.log('\n⚠️  發現的問題:');
    if (issues.length === 0) {
        console.log('  ✅ 沒有發現問題！');
    } else {
        issues.forEach(issue => {
            console.log(`  ❌ ${issue}`);
        });
    }
    
    console.log('\n==================================================');
    
    // 確保沒有問題
    expect(issues).toHaveLength(0);
});