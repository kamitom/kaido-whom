.PHONY: build deploy export clean status logs stats help

# 載入版本號
VERSION := $(shell cat VERSION)

help: ## 顯示幫助資訊
	@echo "Kaido Tech Blog v$(VERSION) - 可用指令："
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## 建置 Docker 映像檔
	@./scripts/build.sh

deploy: ## 部署服務
	@./scripts/deploy.sh

export: build ## 匯出部署套件
	@./scripts/export.sh

up: ## 啟動服務
	@docker compose up -d

down: ## 停止服務
	@docker compose down

status: ## 檢查服務狀態
	@docker compose ps

logs: ## 檢視服務日誌
	@docker compose logs -f

stats: ## 檢視網站訪問統計
	@./scripts/view-stats.sh

clean: ## 清理停止的容器和未使用的映像檔
	@docker system prune -f
	@docker volume prune -f

ssl-init: ## 初始化 SSL 憑證
	@./certbot/init-letsencrypt.sh

ssl-renew: ## 手動續期 SSL 憑證
	@./certbot/renew-certs.sh

version: ## 顯示目前版本
	@echo "目前版本: $(VERSION)"

update-version: ## 更新版本號 (使用方式: make update-version VERSION=1.0.1)
	@./scripts/update-version.sh $(VERSION)