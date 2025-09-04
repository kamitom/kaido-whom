# Kaido Tech Blog

基於 Hugo + Nginx + Certbot 的技術部落格專案，使用 Docker Compose 部署。

## 專案特色

- 🚀 使用 Hugo 靜態網站生成器，快速且SEO友善
- 🔒 自動 SSL 憑證申請與續期 (Let's Encrypt)
- 🐳 完全 Docker 化部署
- 📦 版本化管理，可匯出部署到其他伺服器
- 🔧 提供 Makefile 和腳本兩種操作方式

## 技術棧

- **Hugo**: klakegg/hugo:ext-alpine
- **Nginx**: nginx:alpine
- **Certbot**: certbot/certbot
- **主題**: PaperMod

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
│   └── update-version.sh # 版本更新腳本
├── docker-compose.yml   # Docker Compose 配置
├── Dockerfile.hugo      # 自訂 Dockerfile
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

建立文章後，重新建置：

**使用 Make 指令:**
```bash
make build
make up
```

**使用腳本:**
```bash
./scripts/build.sh
docker compose up -d
```

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

## 版本歷程

- v1.0.0: 初始版本，包含基本 Hugo + Nginx + Certbot 架構