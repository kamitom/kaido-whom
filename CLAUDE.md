# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 專案概覽

這是一個基於 Hugo + Nginx + Certbot 的技術部落格專案，使用 Docker Compose 部署。主要特色包括即時更新功能、自動 SSL 憑證管理以及 E2E 測試框架。

## 常用指令

### 開發與建置
```bash
# 建置 Docker 映像檔
make build
# 或使用腳本
./scripts/build.sh

# 部署服務（包含 SSL 憑證申請）
make deploy
# 或使用腳本
./scripts/deploy.sh

# 檢查服務狀態
make status
# 或
docker compose ps

# 查看服務日誌
make logs
# 或
docker compose logs -f
```

### 測試
```bash
# 執行 Playwright E2E 測試
npm test
# 或
npx playwright test

# UI 模式執行測試
npx playwright test --ui
```

### SSL 憑證管理
```bash
# 初始化 SSL 憑證（僅首次需要）
make ssl-init

# 手動續期憑證
make ssl-renew
```

### 版本管理
```bash
# 更新版本號
make update-version VERSION=1.0.1

# 匯出部署套件
make export
```

## 程式碼架構

### 服務架構
專案採用三個主要 Docker 容器：
- **hugo**: 使用 `klakegg/hugo:ext-alpine`，負責靜態網站生成和即時監控
- **nginx**: 使用 `nginx:alpine`，提供 HTTPS 服務和反向代理
- **certbot**: 使用 `certbot/certbot`，自動處理 SSL 憑證申請與續期

### 關鍵目錄結構
```
hugo/                 # Hugo 網站內容
├── config.yaml      # Hugo 主配置檔
├── content/posts/    # 文章目錄
├── layouts/          # 自訂佈局模板
└── static/          # 靜態檔案

nginx/               # Nginx 配置
├── nginx.conf       # 主配置檔
└── conf.d/          # 網站配置

scripts/             # 管理腳本
├── build.sh         # 建置腳本
├── deploy.sh        # 部署腳本
└── export.sh        # 匯出腳本

tests/               # Playwright E2E 測試
└── hello.spec.js    # 基本網站測試
```

### Hugo 配置重點
- 使用自訂主題設計（不依賴第三方主題）
- 支援中文內容（zh-tw）
- 啟用搜尋功能（JSON 輸出）
- 配置完整的選單結構（分類、標籤、搜尋）

## 開發重點

### 即時更新機制
- 新增/修改 `hugo/content/posts/` 中的文章**不需要**重建映像檔
- Hugo 運行在 watch 模式，會自動偵測變更並重新生成網站
- 只有修改 `config.yaml`、`layouts/` 或容器配置時才需要重建

### 需要重建映像檔的情況
- 修改 `hugo/config.yaml`
- 修改 `hugo/layouts/` 中的模板檔案
- 修改 `docker-compose.yml` 或 `Dockerfile.hugo`
- 修改 `nginx/` 配置檔案
- 版本升級

### SSL 憑證管理
- 使用 Let's Encrypt 自動憑證
- 透過 `.env` 中的 `STAGING` 參數控制使用 staging 或 production CA
- 憑證路徑可能為 `domain-0001` 格式，nginx 配置需相應調整

### 測試架構
- 使用 Playwright 進行 E2E 測試
- 測試包括網站可訪問性、SSL 憑證有效性驗證
- 嚴格模式 SSL 檢查（生產環境標準）
- 配置檔位於 `playwright.config.js`

## 部署說明

### 雙重操作方式
專案支援兩種操作方式：
1. **Make 指令**：需要安裝 make，提供簡潔的指令介面
2. **直接腳本**：不需安裝 make，直接執行 `./scripts/` 中的腳本

### 環境變數配置
關鍵環境變數（`.env` 檔案）：
- `DOMAIN_NAME`: 部署網域
- `EMAIL`: Let's Encrypt 憑證申請 email
- `VERSION`: 版本號
- `STAGING`: 控制使用 Let's Encrypt staging 或 production CA