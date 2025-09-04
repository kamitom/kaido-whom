# Kaido Tech Blog

基於 Hugo + Nginx + Certbot 的技術部落格專案，使用 Docker Compose 部署。

## 專案特色

- 🚀 使用 Hugo 靜態網站生成器，快速且SEO友善
- ⚡ 即時更新功能，新增文章自動發布，無需重建映像檔
- 🔒 自動 SSL 憑證申請與續期 (Let's Encrypt)
- 🐳 完全 Docker 化部署
- 📦 版本化管理，可匯出部署到其他伺服器
- 🔧 提供 Makefile 和腳本兩種操作方式

## 技術棧

- **Hugo**: klakegg/hugo:ext-alpine
- **Nginx**: nginx:alpine
- **Certbot**: certbot/certbot
- **測試**: Playwright (E2E 測試)
- **設計**: 自訂響應式佈局

## 快速開始

### 1. 環境設定

複製環境變數範本並修改設定：

```bash
cp .env.example .env
```

編輯 `.env` 檔案，設定您的網域和 Email：

```env
DOMAIN_NAME=your-domain.com
EMAIL=your-email@example.com
VERSION=1.0.0

# Certbot 配置
# STAGING 控制是否使用 Let's Encrypt 的 staging（測試）環境
# - STAGING=true  : 使用 staging CA（測試憑證，不被瀏覽器信任）
# - STAGING=false : 使用 production CA（正式憑證，瀏覽器信任）
STAGING=false
```

### 2. 檢查系統需求

確認系統是否安裝必要工具：

```bash
# 檢查 Docker 和 Docker Compose
docker --version
docker compose version

# 檢查是否有 make（可選）
which make
```

### 3. 部署方式

本專案提供兩種操作方式，選擇其一即可：

#### 方式 A: 使用 Make 指令（推薦，需安裝 make）

如果系統沒有 make，可安裝：
```bash
sudo apt update && sudo apt install make
```

初次部署：
```bash
# 建置映像檔
make build

# 部署服務（包含 SSL 憑證申請）
make deploy
```

日常操作：
```bash
# 檢視可用指令
make help

# 檢查服務狀態
make status

# 檢視服務日誌
make logs

# 停止/啟動服務
make down
make up
```

#### 方式 B: 直接使用腳本（不需安裝 make）

初次部署：
```bash
# 建置映像檔
./scripts/build.sh

# 部署服務（包含 SSL 憑證申請）
./scripts/deploy.sh
```

日常操作：
```bash
# 檢查服務狀態
docker compose ps

# 檢視服務日誌
docker compose logs -f

# 停止/啟動服務
docker compose down
docker compose up -d

# 匯出部署套件
./scripts/export.sh
```

## 目錄結構

```
kaido-whom/
├── hugo/                 # Hugo 網站內容
│   ├── config.yaml      # Hugo 配置
│   ├── content/         # 網站內容
│   │   ├── posts/       # 文章目錄
│   │   ├── _index.md    # 首頁內容
│   │   └── search.md    # 搜尋頁面
│   ├── layouts/         # 自訂佈局模板
│   │   ├── _default/    # 預設模板
│   │   │   ├── baseof.html   # 基礎模板
│   │   │   ├── list.html     # 列表頁模板
│   │   │   └── single.html   # 單頁模板
│   │   └── index.html   # 首頁模板
│   └── static/          # 靜態檔案
├── nginx/               # Nginx 配置
│   ├── nginx.conf       # 主配置檔
│   └── conf.d/          # 網站配置
├── certbot/             # SSL 憑證管理
│   ├── init-letsencrypt.sh
│   └── renew-certs.sh
├── scripts/             # 管理腳本
│   ├── build.sh         # 建置腳本
│   ├── deploy.sh        # 部署腳本
│   ├── export.sh        # 匯出腳本
│   ├── hugo-watch.sh    # Hugo 監控腳本
│   └── update-version.sh # 版本更新腳本
├── tests/               # Playwright E2E 測試
│   └── hello.spec.js    # 基本網站測試
├── docker-compose.yml   # Docker Compose 配置
├── Dockerfile.hugo      # 自訂 Dockerfile
├── package.json         # Node.js 依賴配置
├── playwright.config.js # Playwright 測試配置
├── .env                 # 環境變數
└── Makefile            # Make 指令
```

## 新增文章

在 `hugo/content/posts/` 目錄下建立新的 Markdown 檔案：

```markdown
---
title: "文章標題"
date: 2024-01-01T00:00:00+08:00
draft: false
tags: ["標籤1", "標籤2"]
categories: ["分類"]
---

文章內容...
```

建立文章後，**不需要重建映像檔**！Hugo 會自動監控變更並即時更新網站。

## 測試

本專案使用 Playwright 進行端對端（E2E）測試，確保網站功能正常運作。

### 執行測試

**安裝測試依賴（僅首次需要）:**
```bash
npm install
```

**執行所有測試:**
```bash
npm test
# 或
npx playwright test
```

**以 UI 模式執行測試:**
```bash
npx playwright test --ui
```

### 測試項目

目前包含的測試：
- ✅ 網站可訪問性測試
- ✅ 頁面標題驗證
- ✅ SSL 憑證有效性（嚴格模式）

### 添加新測試

在 `tests/` 目錄下建立新的 `.spec.js` 檔案：

```javascript
const { test, expect } = require('@playwright/test');

test('新測試項目', async ({ page }) => {
    await page.goto('https://your-domain.com');
    // 添加測試邏輯
});
```

### 測試配置

測試配置位於 `playwright.config.js`：
- 預設使用 Chromium 瀏覽器
- headless 模式執行
- 嚴格 SSL 檢查（確保使用有效憑證）
- 30 秒測試超時時間

## 映像檔重建時機

### ❌ 不需要重建映像檔的情況

以下操作會**自動更新**，無需重建映像檔：

- ✅ **新增文章** - 在 `hugo/content/posts/` 新增 `.md` 檔案
- ✅ **修改文章** - 編輯現有的 `.md` 檔案內容
- ✅ **刪除文章** - 移除 `.md` 檔案
- ✅ **修改文章元資料** - 更改 front matter（標題、日期、標籤等）
- ✅ **新增靜態檔案** - 在 `hugo/static/` 新增圖片等檔案

### ⚠️ 需要重建映像檔的情況

以下變更需要重建映像檔：

#### 🔧 Hugo 配置變更
```bash
# 當修改這些檔案時需要重建
hugo/config.yaml          # Hugo 基礎配置
hugo/layouts/**/*.html     # 佈局模板檔案
```

#### 🐳 容器配置變更  
```bash
# 當修改這些檔案時需要重建
docker-compose.yml         # 服務配置
Dockerfile.hugo            # Hugo 建置配置
nginx/nginx.conf           # Nginx 主配置
nginx/conf.d/*.conf        # Nginx 虛擬主機配置
```

#### 📦 版本升級
```bash
# 當進行版本升級時需要重建
VERSION                    # 版本號檔案
.env                      # 環境變數中的 VERSION
```

### 🛠️ 如何重建映像檔

當需要重建時，執行以下指令：

**使用 Make 指令:**
```bash
make build    # 重建映像檔
make up       # 重新啟動服務
```

**使用腳本:**
```bash
./scripts/build.sh        # 重建映像檔
docker compose up -d      # 重新啟動服務
```

### 📝 快速判斷原則

- **內容變更**（文章、圖片）→ ❌ 不需重建
- **配置變更**（模板、設定）→ ⚠️ 需要重建
- **版本升級** → ⚠️ 需要重建

## 版本管理

### 更新版本號

**使用 Make 指令:**
```bash
make update-version VERSION=1.0.1
```

**使用腳本:**
```bash
./scripts/update-version.sh 1.0.1
```

### 匯出部署套件

**使用 Make 指令:**
```bash
make export
```

**使用腳本:**
```bash
./scripts/export.sh
```

這會在 `exports/` 目錄產生可移植到其他伺服器的部署套件。

## SSL 憑證管理

### 初始化 SSL 憑證（僅首次需要）

**使用 Make 指令:**
```bash
make ssl-init
```

**使用腳本:**
```bash
./certbot/init-letsencrypt.sh
```

### 手動續期憑證

**使用 Make 指令:**
```bash
make ssl-renew
```

**使用腳本:**
```bash
./certbot/renew-certs.sh
```

### 設定自動續期

建議在伺服器上設定 crontab：

```bash
# 編輯 crontab
crontab -e

# 新增以下行：每週日凌晨 3 點檢查憑證續期
0 3 * * 0 /path/to/project/certbot/renew-certs.sh
```

## 移植到其他伺服器

1. **匯出部署套件:**
   - 使用 Make: `make export`
   - 使用腳本: `./scripts/export.sh`

2. 將 `exports/` 目錄內容複製到目標伺服器

3. 依照 `exports/README-DEPLOYMENT.md` 指示部署

## 疑難排解

### 查看服務狀態

**使用 Make 指令:**
```bash
make status
```

**使用 Docker Compose:**
```bash
docker compose ps
```

### 查看日誌

**使用 Make 指令:**
```bash
make logs
```

**使用 Docker Compose:**
```bash
docker compose logs -f
```

### 重新申請 SSL 憑證

**使用 Make 指令:**
```bash
make down
rm -rf certbot/conf
make ssl-init
```

**使用腳本:**
```bash
docker compose down
rm -rf certbot/conf
./certbot/init-letsencrypt.sh
```

### 常見問題

1. **憑證申請失敗**: 確認網域 DNS 設定正確，且指向伺服器 IP
2. **服務無法啟動**: 檢查 `.env` 檔案設定是否正確
3. **Hugo 建置失敗**: 確認 `hugo/` 目錄下的內容完整
4. **SSL 憑證路徑錯誤**: 如果 nginx 顯示找不到憑證檔案，檢查 `/etc/letsencrypt/live/` 目錄下的實際路徑（可能為 `domain-0001` 格式）
5. **測試失敗**: 確認網站使用有效的 SSL 憑證，如果使用 staging 憑證請設定 `STAGING=false` 並重新申請憑證

### SSL 憑證問題排解

**檢查憑證路徑:**
```bash
# 查看實際憑證目錄
docker compose exec nginx ls -la /etc/letsencrypt/live/

# 檢查憑證有效性
echo | openssl s_client -servername your-domain.com -connect your-domain.com:443 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```

**修正憑證路徑:**
如果憑證目錄為 `your-domain.com-0001`，需要更新 `nginx/conf.d/default.conf` 中的路徑設定。

## 版本歷程

### v1.0.2 (2025-09-04)
**測試與 SSL 改進版本**

**新增功能**：
- ✅ **Playwright E2E 測試框架** - 自動化網站功能測試
- ✅ **SSL 憑證路徑自動修正** - 解決 Let's Encrypt 憑證路徑問題
- ✅ **改進的 .env 配置說明** - 詳細的 STAGING 參數說明
- ✅ **測試命令集成** - npm test 一鍵執行測試

**技術改進**：
- 🔧 修正 nginx SSL 憑證路徑配置
- 🔧 嚴格的 SSL 憑證驗證（生產環境標準）
- 🧹 清理臨時檔案與重複資源
- 📝 完善的 README 文件更新

**測試覆蓋**：
- 🧪 網站可訪問性測試
- 🧪 SSL 憑證有效性驗證
- 🧪 頁面內容驗證

### v1.0.0 (2025-09-04)
**完整功能版本**

**核心功能**：
- ✅ Hugo + Nginx + Certbot 完整架構
- ✅ 自動 SSL 憑證申請與續期
- ✅ 即時文章更新功能（無需重建映像檔）
- ✅ 自訂響應式佈局設計
- ✅ Docker Compose 多服務部署

**技術特色**：
- 🚀 Hugo 監控模式，文章即時發布
- 🔒 Let's Encrypt 自動憑證管理
- 🎨 簡潔白色卡片風格設計
- 📱 完全響應式佈局
- 🔧 雙重操作方式（Make + 腳本）

**已實現功能**：
- 首頁文章列表展示
- 文章分類和標籤系統
- 搜尋功能頁面
- HTTPS 安全連線
- 版本化映像檔管理
- 可移植部署套件匯出