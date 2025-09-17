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
    echo "  -a, --attacks   顯示安全攻擊嘗試記錄"
    echo "  -w, --watch     即時監控訪問日誌"
    echo "  -r, --raw       顯示原始日誌"
    echo ""
    echo "範例:"
    echo "  $0 -s           # 顯示總體統計"
    echo "  $0 -p           # 顯示文章排行"
    echo "  $0 -w           # 即時監控"
}

get_access_log() {
    # 優先使用持久化的日誌檔案，如果不存在則使用 Docker 日誌
    if docker exec "$NGINX_CONTAINER" test -f /var/log/nginx/access.log && \
       docker exec "$NGINX_CONTAINER" test -s /var/log/nginx/access.log; then
        # 使用持久化的日誌檔案
        docker exec "$NGINX_CONTAINER" cat /var/log/nginx/access.log 2>/dev/null
    else
        # 回退到 Docker 日誌
        docker logs "$NGINX_CONTAINER" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' || {
            echo -e "${YELLOW}目前沒有訪問日誌或容器剛啟動${NC}" >&2
            return 1
        }
    fi
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
        local hour_ago_tw=$(TZ=Asia/Taipei date -d "$i hours ago" +"%d/%b/%Y:%H")
        # 同時搜尋台灣時間格式和對應的 UTC 時間格式（舊日誌）
        local hour_ago_utc=$(date -u -d "$((i+8)) hours ago" +"%d/%b/%Y:%H")

        # 搜尋台灣時間格式 (+0800) 和 UTC 格式 (+0000) 的日誌
        local hour_count_tw=$(echo "$access_log" | grep "${hour_ago_tw}.*+0800" | wc -l)
        local hour_count_utc=$(echo "$access_log" | grep "${hour_ago_utc}.*+0000" | wc -l)
        local total_count=$((hour_count_tw + hour_count_utc))

        # 顯示所有小時，包括 0 訪問的
        printf "%-13s: %s (%d)\n" "$hour_ago_tw" "$(printf '%*s' $total_count | tr ' ' '*')" "$total_count"
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
        # URL 解碼，將 %XX 格式轉換為中文字符
        local decoded_url=$(python3 -c "import urllib.parse; print(urllib.parse.unquote('$url'))" 2>/dev/null || echo "$url")
        printf "%-4s %s\n" "$count" "$decoded_url"
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
        # URL 解碼，將 %XX 格式轉換為中文字符
        local decoded_title=$(python3 -c "import urllib.parse; print(urllib.parse.unquote('$title'))" 2>/dev/null || echo "$title")
        printf "%-4s %s\n" "$count" "$decoded_title"
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

    # 優先使用持久化日誌檔案的 tail，否則使用 Docker 日誌
    if docker exec "$NGINX_CONTAINER" test -f /var/log/nginx/access.log; then
        docker exec "$NGINX_CONTAINER" tail -f /var/log/nginx/access.log | \
        while IFS= read -r line; do
            # 檢查是否為正常的 HTTP 日誌格式
            if echo "$line" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.*\[.*\].*"[A-Z]+ .* HTTP/.*"'; then
                # 解析 HTTP 日誌行
                local ip=$(echo "$line" | awk '{print $1}')
                local timestamp=$(echo "$line" | awk '{print $4 $5}' | tr -d '[]')
                local method=$(echo "$line" | awk '{print $6}' | tr -d '"')
                local url=$(echo "$line" | awk '{print $7}')
                local status=$(echo "$line" | awk '{print $9}')

                # URL 解碼
                local decoded_url=$(python3 -c "import urllib.parse; print(urllib.parse.unquote('$url'))" 2>/dev/null || echo "$url")

                # 根據狀態碼著色
                case "$status" in
                    "200"|"304") color=$GREEN ;;
                    "404") color=$YELLOW ;;
                    "5"*) color=$RED ;;
                    *) color=$NC ;;
                esac

                echo -e "${color}${timestamp}${NC} ${ip} ${method}${decoded_url} ${color}${status}${NC}"
            else
                # 處理非 HTTP 請求（可能是攻擊或異常連接）
                local ip=$(echo "$line" | awk '{print $1}' 2>/dev/null)
                local timestamp=$(echo "$line" | awk '{print $4 $5}' 2>/dev/null | tr -d '[]')

                if [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    echo -e "${RED}${timestamp}${NC} ${ip} ${RED}[異常連接/可能攻擊]${NC}"
                else
                    # 完全無法解析的行，顯示為異常
                    echo -e "${RED}[異常日誌] $(echo "$line" | head -c 50)...${NC}"
                fi
            fi
        done
    else
        # 回退到 Docker 日誌
        docker logs -f "$NGINX_CONTAINER" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' --line-buffered | \
        while IFS= read -r line; do
            # 檢查是否為正常的 HTTP 日誌格式
            if echo "$line" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.*\[.*\].*"[A-Z]+ .* HTTP/.*"'; then
                # 解析 HTTP 日誌行
                local ip=$(echo "$line" | awk '{print $1}')
                local timestamp=$(echo "$line" | awk '{print $4 $5}' | tr -d '[]')
                local method=$(echo "$line" | awk '{print $6}' | tr -d '"')
                local url=$(echo "$line" | awk '{print $7}')
                local status=$(echo "$line" | awk '{print $9}')

                # URL 解碼
                local decoded_url=$(python3 -c "import urllib.parse; print(urllib.parse.unquote('$url'))" 2>/dev/null || echo "$url")

                # 根據狀態碼著色
                case "$status" in
                    "200"|"304") color=$GREEN ;;
                    "404") color=$YELLOW ;;
                    "5"*) color=$RED ;;
                    *) color=$NC ;;
                esac

                echo -e "${color}${timestamp}${NC} ${ip} ${method}${decoded_url} ${color}${status}${NC}"
            else
                # 處理非 HTTP 請求（可能是攻擊或異常連接）
                local ip=$(echo "$line" | awk '{print $1}' 2>/dev/null)
                local timestamp=$(echo "$line" | awk '{print $4 $5}' 2>/dev/null | tr -d '[]')

                if [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    echo -e "${RED}${timestamp}${NC} ${ip} ${RED}[異常連接/可能攻擊]${NC}"
                else
                    # 完全無法解析的行，顯示為異常
                    echo -e "${RED}[異常日誌] $(echo "$line" | head -c 50)...${NC}"
                fi
            fi
        done
    fi
}

show_security_attacks() {
    echo -e "${BLUE}=== 安全攻擊嘗試記錄 ===${NC}"
    echo ""

    # 檢查安全日誌是否存在
    if docker exec "$NGINX_CONTAINER" test -f /var/log/nginx/security.log 2>/dev/null; then
        local security_log=$(docker exec "$NGINX_CONTAINER" cat /var/log/nginx/security.log 2>/dev/null)
        if [ -n "$security_log" ]; then
            echo -e "${RED}⚠️  偵測到敏感檔案訪問嘗試：${NC}"
            echo ""

            echo -e "${YELLOW}最近攻擊記錄：${NC}"
            echo "$security_log" | tail -20 | while IFS= read -r line; do
                local ip=$(echo "$line" | awk '{print $1}')
                local timestamp=$(echo "$line" | awk '{print $4 $5}' | tr -d '[]')
                local url=$(echo "$line" | awk '{print $7}')
                echo -e "${RED}${timestamp}${NC} ${ip} 嘗試訪問: ${YELLOW}${url}${NC}"
            done

            echo ""
            echo -e "${YELLOW}攻擊源 IP 統計：${NC}"
            echo "$security_log" | awk '{print $1}' | sort | uniq -c | sort -nr | head -10 | \
            while read count ip; do
                echo -e "${RED}%-4s %s${NC}" "$count" "$ip"
            done

            echo ""
            echo -e "${YELLOW}被攻擊的目標檔案：${NC}"
            echo "$security_log" | awk '{print $7}' | sort | uniq -c | sort -nr | head -10 | \
            while read count url; do
                echo -e "${RED}%-4s %s${NC}" "$count" "$url"
            done
        else
            echo -e "${GREEN}✅ 目前沒有偵測到敏感檔案訪問嘗試${NC}"
        fi
    else
        echo -e "${GREEN}✅ 安全日誌檔案不存在，表示沒有攻擊嘗試${NC}"
    fi
}

show_raw_logs() {
    echo -e "${BLUE}=== 原始 Nginx 日誌 (最後50行) ===${NC}"
    echo ""

    # 獲取日誌並處理亂碼
    local logs=""
    if docker exec "$NGINX_CONTAINER" test -f /var/log/nginx/access.log; then
        logs=$(docker exec "$NGINX_CONTAINER" tail -50 /var/log/nginx/access.log 2>/dev/null)
    else
        logs=$(docker logs "$NGINX_CONTAINER" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | tail -50)
    fi

    # 處理每一行日誌
    echo "$logs" | while IFS= read -r line; do
        if [ -z "$line" ]; then
            continue
        fi

        # 檢查是否為正常 HTTP 日誌格式
        if echo "$line" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.*\[.*\].*"[A-Z]+ .* HTTP/.*"'; then
            # 正常 HTTP 日誌，進行 URL 解碼
            local decoded_line=$(echo "$line" | python3 -c "
import sys, urllib.parse, re
line = sys.stdin.read().strip()
# 尋找並解碼 URL 部分
def decode_url(match):
    return urllib.parse.unquote(match.group(0))
# 使用正規表達式找到 URL 並解碼（在引號內的 HTTP 請求部分）
decoded = re.sub(r'\"[A-Z]+ ([^\"]+) HTTP/[^\"]*\"', lambda m: m.group(0).replace(m.group(1), urllib.parse.unquote(m.group(1))), line)
print(decoded)
" 2>/dev/null || echo "$line")
            echo "$decoded_line"
        elif echo "$line" | grep -qE '\\x[0-9a-fA-F]{2}'; then
            # 包含二進位數據的行，提取基本資訊並清理顯示
            local ip=$(echo "$line" | awk '{print $1}' 2>/dev/null)
            local timestamp=$(echo "$line" | awk '{print $4 $5}' 2>/dev/null | tr -d '[]')
            local status=$(echo "$line" | grep -oE ' [0-9]{3} ' | tr -d ' ' | tail -1)

            if [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo -e "${ip} - - [${timestamp}] ${RED}\"[二進位攻擊/SSL探測]\"${NC} ${status:-400} - \"-\" \"-\" \"-\""
            else
                # 完全無法解析，顯示清理過的版本
                local clean_line=$(echo "$line" | tr -d '\000-\037\177-\377' | head -c 100)
                echo -e "${RED}[異常日誌] ${clean_line}...${NC}"
            fi
        else
            # 其他格式的日誌，直接顯示
            echo "$line"
        fi
    done
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
    -a|--attacks)
        show_security_attacks
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