#!/bin/bash

# 載入環境變數
if [[ -f .env ]]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

VERSION=${VERSION:-1.0.0}
EXPORT_DIR="./exports"

echo "匯出 Kaido Tech Blog v${VERSION} 用於部署到其他伺服器..."

# 建立匯出目錄
mkdir -p ${EXPORT_DIR}

# 匯出 Docker 映像檔
echo "匯出 Docker 映像檔..."
docker save kaido-blog:${VERSION} | gzip > ${EXPORT_DIR}/kaido-blog-${VERSION}.tar.gz

# 複製部署所需檔案
echo "複製部署檔案..."
cp docker-compose.yml ${EXPORT_DIR}/
cp .env.example ${EXPORT_DIR}/
cp -r certbot ${EXPORT_DIR}/
cp -r scripts ${EXPORT_DIR}/

# 建立部署說明檔案
cat > ${EXPORT_DIR}/README-DEPLOYMENT.md << EOF
# Kaido Tech Blog v${VERSION} 部署說明

## 系統需求
- Docker
- Docker Compose
- Ubuntu 22.04 或相容系統

## 部署步驟

1. 解壓縮並載入 Docker 映像檔：
   \`\`\`bash
   gunzip -c kaido-blog-${VERSION}.tar.gz | docker load
   \`\`\`

2. 複製 .env.example 為 .env 並修改配置：
   \`\`\`bash
   cp .env.example .env
   # 編輯 .env 檔案，設定您的網域名稱和 Email
   \`\`\`

3. 設定執行權限：
   \`\`\`bash
   chmod +x certbot/init-letsencrypt.sh
   chmod +x certbot/renew-certs.sh
   chmod +x scripts/*.sh
   \`\`\`

4. 部署：
   \`\`\`bash
   ./scripts/deploy.sh
   \`\`\`

## 憑證自動續期

建議設定 crontab 自動執行憑證續期：
\`\`\`bash
# 每週檢查憑證續期
0 3 * * 0 /path/to/project/certbot/renew-certs.sh
\`\`\`

## 版本資訊
- 版本: ${VERSION}
- 建置時間: $(date)
EOF

echo "匯出完成！"
echo "匯出檔案位置: ${EXPORT_DIR}/"
echo "主要映像檔: ${EXPORT_DIR}/kaido-blog-${VERSION}.tar.gz"
echo "部署說明: ${EXPORT_DIR}/README-DEPLOYMENT.md"