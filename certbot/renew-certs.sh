#!/bin/bash

# SSL 憑證自動續期腳本
echo "Starting certificate renewal check..."

# 嘗試續期憑證
docker-compose exec certbot certbot renew --quiet

# 檢查續期結果
if [ $? -eq 0 ]; then
    echo "Certificate renewal check completed successfully"
    # 重新載入 nginx 配置
    docker-compose exec nginx nginx -s reload
    echo "Nginx configuration reloaded"
else
    echo "Certificate renewal failed"
    exit 1
fi