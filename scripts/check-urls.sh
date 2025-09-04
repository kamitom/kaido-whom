#!/bin/bash

echo "🔍 正在執行網站 URL 有效性檢查..."
echo "=============================================="

# 執行 URL 驗證測試
echo "📊 執行基礎 URL 驗證..."
npx playwright test tests/url-validation.spec.js --reporter=line

echo ""
echo "📋 生成詳細 URL 報告..."
npx playwright test tests/url-report.spec.js --reporter=line

echo ""
echo "✅ URL 檢查完成！"