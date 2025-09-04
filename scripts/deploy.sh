#!/bin/bash

# 載入環境變數
if [[ -f .env ]]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

VERSION=${VERSION:-1.0.0}

echo "部署 Kaido Tech Blog v${VERSION}..."

# 檢查是否為首次部署
if [ ! -d "certbot/conf" ]; then
    echo "首次部署，初始化 SSL 憑證..."
    ./certbot/init-letsencrypt.sh
else
    echo "更新部署..."
    # 停止現有服務
    docker-compose down
    
    # 拉取最新映像檔或建置
    echo "更新服務..."
    docker-compose up -d
    
    echo "等待服務啟動..."
    sleep 10
    
    echo "重新載入 nginx 配置..."
    docker-compose exec nginx nginx -s reload
fi

echo "部署完成！"
echo "網站: https://${DOMAIN_NAME}"