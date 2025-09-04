# Kaido Tech Blog

基於 Hugo + Nginx + Certbot 的技術部落格專案，使用 Docker Compose 部署。

## 專案特色

- 🚀 使用 Hugo 靜態網站生成器，快速且SEO友善
- 🔒 自動 SSL 憑證申請與續期 (Let's Encrypt)
- 🐳 完全 Docker 化部署
- 📦 版本化管理，可匯出部署到其他伺服器
- 🔧 簡單的 Makefile 操作介面

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

### 2. 初次部署

```bash
# 建置映像檔
make build

# 部署服務（包含 SSL 憑證申請）
make deploy
```

### 3. 日常操作

```bash
# 檢視可用指令
make help

# 檢查服務狀態
make status

# 檢視服務日誌
make logs

# 停止服務
make down

# 啟動服務
make up
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

```bash
make build
make up
```

## 版本管理

### 更新版本號

```bash
make update-version VERSION=1.0.1
```

### 匯出部署套件

```bash
make export
```

這會在 `exports/` 目錄產生可移植到其他伺服器的部署套件。

## SSL 憑證管理

### 手動續期憑證

```bash
make ssl-renew
```

### 設定自動續期

建議在伺服器上設定 crontab：

```bash
# 每週日凌晨 3 點檢查憑證續期
0 3 * * 0 /path/to/project/certbot/renew-certs.sh
```

## 移植到其他伺服器

1. 使用 `make export` 匯出部署套件
2. 將 `exports/` 目錄內容複製到目標伺服器
3. 依照 `exports/README-DEPLOYMENT.md` 指示部署

## 疑難排解

### 查看服務狀態
```bash
make status
```

### 查看日誌
```bash
make logs
```

### 重新申請 SSL 憑證
```bash
make down
rm -rf certbot/conf
make ssl-init
```

## 版本歷程

- v1.0.0: 初始版本，包含基本 Hugo + Nginx + Certbot 架構