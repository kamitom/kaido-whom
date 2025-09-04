#!/bin/bash

if [ -z "$1" ]; then
    echo "使用方式: $0 <new_version>"
    echo "範例: $0 1.0.1"
    exit 1
fi

NEW_VERSION=$1

echo "更新版本號從 $(cat VERSION) 到 ${NEW_VERSION}..."

# 更新版本檔案
echo ${NEW_VERSION} > VERSION

# 更新 .env 檔案
sed -i "s/VERSION=.*/VERSION=${NEW_VERSION}/" .env
sed -i "s/VERSION=.*/VERSION=${NEW_VERSION}/" .env.example

echo "版本號已更新到 ${NEW_VERSION}"
echo "記得重新建置映像檔："
echo "  ./scripts/build.sh"