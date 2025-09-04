#!/bin/bash

# 載入環境變數
if [[ -f .env ]]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

VERSION=${VERSION:-1.0.0}

echo "開始建置 Kaido Tech Blog v${VERSION}..."

# 建置 Hugo + Nginx 映像檔
echo "建置主要應用程式映像檔..."
docker build -f Dockerfile.hugo -t kaido-blog:${VERSION} --build-arg VERSION=${VERSION} .

# 標記為最新版本
docker tag kaido-blog:${VERSION} kaido-blog:latest

echo "建置完成！"
echo "映像檔標籤："
echo "  - kaido-blog:${VERSION}"
echo "  - kaido-blog:latest"