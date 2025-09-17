#!/bin/bash

# Nginx 訪問日誌分析腳本
# 用法: ./scripts/view-stats.sh [選項]

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 獲取容器名稱
NGINX_CONTAINER=$(docker compose ps -q nginx 2>/dev/null)
if [ -z "$NGINX_CONTAINER" ]; then
    echo -e "${RED}錯誤: 找不到 nginx 容器。請確保服務正在運行。${NC}"
    echo "運行 'make status' 或 'docker compose ps' 檢查服務狀態"
    exit 1
fi

# 檢查容器是否運行
if ! docker ps -q --filter "id=$NGINX_CONTAINER" | grep -q .; then
    echo -e "${RED}錯誤: nginx 容器未運行${NC}"
    exit 1
fi

show_help() {
    echo -e "${BLUE}Nginx 訪問日誌分析工具${NC}"
    echo ""
    echo "用法: $0 [選項]"
    echo ""
    echo "選項:"
    echo "  -h, --help      顯示此幫助訊息"
    echo "  -s, --summary   顯示訪問統計摘要 (預設)"
    echo "  -t, --today     顯示今日訪問統計"
    echo "  -p, --posts     顯示文章訪問排行"
    echo "  -i, --ips       顯示 IP 訪問統計"
    echo "  -w, --watch     即時監控訪問日誌"
    echo "  -r, --raw       顯示原始日誌"
    echo ""
    echo "範例:"
    echo "  $0 -s           # 顯示總體統計"
    echo "  $0 -p           # 顯示文章排行"
    echo "  $0 -w           # 即時監控"
}

get_access_log() {
    # nginx 在 Docker 中通常將日誌重定向到 stdout
    # 所以我們從 Docker 日誌中提取 access log
    docker logs "$NGINX_CONTAINER" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' || {
        echo -e "${YELLOW}目前沒有訪問日誌或容器剛啟動${NC}" >&2
        return 1
    }
}

get_today_log() {
    # 同時檢查 UTC 的今天和台灣時間的今天
    local today_utc=$(date -u +"%d/%b/%Y")
    local today_tw=$(TZ=Asia/Taipei date +"%d/%b/%Y")
    get_access_log | grep -E "($today_utc|$today_tw)"
}

show_summary() {
    echo -e "${BLUE}=== 訪問統計摘要 ===${NC}"
    echo ""

    local access_log=$(get_access_log)
    if [ $? -ne 0 ] || [ -z "$access_log" ]; then
        echo -e "${YELLOW}目前沒有訪問記錄${NC}"
        echo "可能原因："
        echo "1. 網站剛啟動，尚未有訪客"
        echo "2. 容器最近重啟，日誌被清空"
        echo "3. 訪問網站 https://kaido.helenfit.com 來產生一些日誌"
        return
    fi

    local total_requests=$(echo "$access_log" | wc -l)
    local today_requests=$(get_today_log | wc -l)
    local unique_ips=$(echo "$access_log" | awk '{print $1}' | sort | uniq | wc -l)
    local post_requests=$(echo "$access_log" | grep -E 'GET /posts/' | wc -l)

    echo -e "${GREEN}總訪問次數:${NC} $total_requests"
    echo -e "${GREEN}今日訪問:${NC} $today_requests"
    echo -e "${GREEN}獨立 IP:${NC} $unique_ips"
    echo -e "${GREEN}文章訪問:${NC} $post_requests"
    echo ""

    # 最近24小時趨勢 (台灣時間)
    echo -e "${YELLOW}最近24小時訪問趨勢 (台灣時間):${NC}"
    for i in {23..0}; do
        # 台灣時間比 UTC 快 8 小時，所以 UTC 時間往前推 8 小時
        local hour_ago_utc=$(date -u -d "$((i+8)) hours ago" +"%d/%b/%Y:%H")
        local hour_ago_tw=$(TZ=Asia/Taipei date -d "$i hours ago" +"%d/%b/%Y:%H")

        local hour_count=$(echo "$access_log" | grep "$hour_ago_utc" | wc -l)
        if [ "$hour_count" -gt 0 ]; then
            printf "%-13s: %s (%d)\n" "$hour_ago_tw" "$(printf '%*s' $hour_count | tr ' ' '*')" "$hour_count"
        fi
    done
}

show_today_stats() {
    echo -e "${BLUE}=== 今日訪問統計 ===${NC}"
    echo ""

    local today_log=$(get_today_log)
    if [ -z "$today_log" ]; then
        echo "今日尚無訪問記錄"
        return
    fi

    echo -e "${GREEN}今日總訪問:${NC} $(echo "$today_log" | wc -l)"
    echo -e "${GREEN}今日獨立 IP:${NC} $(echo "$today_log" | awk '{print $1}' | sort | uniq | wc -l)"
    echo ""

    echo -e "${YELLOW}今日熱門頁面:${NC}"
    echo "$today_log" | awk '{print $7}' | grep -v '^/$' | sort | uniq -c | sort -nr | head -10 | \
    while read count url; do
        printf "%-4s %s\n" "$count" "$url"
    done
}

show_posts_ranking() {
    echo -e "${BLUE}=== 文章訪問排行 ===${NC}"
    echo ""

    local posts_log=$(get_access_log | grep -E 'GET /posts/' | awk '{print $7}')
    if [ -z "$posts_log" ]; then
        echo "尚無文章訪問記錄"
        return
    fi

    echo -e "${YELLOW}文章訪問排行榜:${NC}"
    echo "$posts_log" | sort | uniq -c | sort -nr | head -15 | \
    while read count url; do
        # 提取文章標題 (去掉 /posts/ 前綴和 / 後綴)
        local title=$(echo "$url" | sed 's|^/posts/||' | sed 's|/$||')
        printf "%-4s %s\n" "$count" "$title"
    done
}

show_ip_stats() {
    echo -e "${BLUE}=== IP 訪問統計 ===${NC}"
    echo ""

    echo -e "${YELLOW}訪問次數最多的 IP:${NC}"
    get_access_log | awk '{print $1}' | sort | uniq -c | sort -nr | head -10 | \
    while read count ip; do
        printf "%-4s %s\n" "$count" "$ip"
    done

    echo ""
    echo -e "${YELLOW}今日活躍 IP:${NC}"
    get_today_log | awk '{print $1}' | sort | uniq -c | sort -nr | head -5 | \
    while read count ip; do
        printf "%-4s %s\n" "$count" "$ip"
    done
}

watch_logs() {
    echo -e "${BLUE}=== 即時監控訪問日誌 ===${NC}"
    echo -e "${YELLOW}按 Ctrl+C 停止監控${NC}"
    echo ""

    docker logs -f "$NGINX_CONTAINER" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' --line-buffered | \
    while IFS= read -r line; do
        # 解析日誌行
        local ip=$(echo "$line" | awk '{print $1}')
        local timestamp=$(echo "$line" | awk '{print $4 $5}' | tr -d '[]')
        local method_url=$(echo "$line" | awk '{print $6 $7}' | tr -d '"')
        local status=$(echo "$line" | awk '{print $9}')

        # 根據狀態碼著色
        case "$status" in
            "200"|"304") color=$GREEN ;;
            "404") color=$YELLOW ;;
            "5"*) color=$RED ;;
            *) color=$NC ;;
        esac

        echo -e "${color}${timestamp}${NC} ${ip} ${method_url} ${color}${status}${NC}"
    done
}

show_raw_logs() {
    echo -e "${BLUE}=== 原始 Nginx 日誌 (最後50行) ===${NC}"
    echo ""
    docker logs "$NGINX_CONTAINER" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | tail -50
}

# 主程式
if [ $# -eq 0 ]; then
    show_summary
    exit 0
fi

case "$1" in
    -h|--help)
        show_help
        ;;
    -s|--summary)
        show_summary
        ;;
    -t|--today)
        show_today_stats
        ;;
    -p|--posts)
        show_posts_ranking
        ;;
    -i|--ips)
        show_ip_stats
        ;;
    -w|--watch)
        watch_logs
        ;;
    -r|--raw)
        show_raw_logs
        ;;
    *)
        echo -e "${RED}未知選項: $1${NC}"
        echo "使用 -h 或 --help 查看幫助"
        exit 1
        ;;
esac