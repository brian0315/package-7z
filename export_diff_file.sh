#!/bin/bash

# 自動打包腳本
# 用途：比較 git branch/commit 差異，複製檔案並生成差異報告

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 使用說明
usage() {
    echo -e "${GREEN}使用說明：${NC}"
    echo "  $0 [選項]"
    echo ""
    echo "選項："
    echo "  -t <type>       比較類型：branch 或 commit (預設: branch)"
    echo "  -s <source>     來源 branch/commit"
    echo "  -d <dest>       目標 branch/commit (預設: HEAD)"
    echo "  -p <project>    專案類型：api 或 front (預設: front)"
    echo "  -o <output>     輸出目錄 (預設: ./package_output)"
    echo "  -h              顯示此說明"
    echo ""
    echo "範例："
    echo "  # 比較兩個 branch"
    echo "  $0 -t branch -s main -d develop -p front -o ~/Desktop/release"
    echo ""
    echo "  # 比較兩個 commit"
    echo "  $0 -t commit -s abc123 -d def456 -p api -o ~/output"
    echo ""
    echo "  # 比較當前與特定 branch"
    echo "  $0 -s main -p front"
    exit 1
}

# 預設值
COMPARE_TYPE="branch"
SOURCE=""
DEST="HEAD"
PROJECT_TYPE="front"
OUTPUT_DIR="./package_output"

# 解析參數
while getopts "t:s:d:p:o:h" opt; do
    case $opt in
        t) COMPARE_TYPE="$OPTARG" ;;
        s) SOURCE="$OPTARG" ;;
        d) DEST="$OPTARG" ;;
        p) PROJECT_TYPE="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        h) usage ;;
        ?) usage ;;
    esac
done

# 驗證必要參數
if [ -z "$SOURCE" ]; then
    echo -e "${RED}錯誤：必須指定來源 (-s)${NC}"
    usage
fi

# 驗證 git 倉庫
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}錯誤：當前目錄不是 git 倉庫${NC}"
    exit 1
fi

# 驗證專案類型
if [[ "$PROJECT_TYPE" != "api" && "$PROJECT_TYPE" != "front" ]]; then
    echo -e "${RED}錯誤：專案類型必須是 'api' 或 'front'${NC}"
    exit 1
fi

# 驗證比較類型
if [[ "$COMPARE_TYPE" != "branch" && "$COMPARE_TYPE" != "commit" ]]; then
    echo -e "${RED}錯誤：比較類型必須是 'branch' 或 'commit'${NC}"
    exit 1
fi

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Git 自動打包工具${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "${BLUE}比較類型：${NC}$COMPARE_TYPE"
echo -e "${BLUE}來源：${NC}$SOURCE"
echo -e "${BLUE}目標：${NC}$DEST"
echo -e "${BLUE}專案類型：${NC}$PROJECT_TYPE"
echo -e "${BLUE}輸出目錄：${NC}$OUTPUT_DIR"
echo -e "${GREEN}======================================${NC}\n"

# 創建輸出目錄
OUTPUT_PATH="$OUTPUT_DIR/$PROJECT_TYPE"
mkdir -p "$OUTPUT_PATH"

# 生成差異報告檔案
DIFF_FILE="$OUTPUT_DIR/diff_${PROJECT_TYPE}.txt"

# 執行 git diff 並獲取檔案列表
echo -e "${YELLOW}正在分析差異...${NC}"

# 生成完整的 diff 報告
{
    echo "========================================"
    echo "Git 差異報告"
    echo "========================================"
    echo "比較類型: $COMPARE_TYPE"
    echo "來源: $SOURCE"
    echo "目標: $DEST"
    echo "專案類型: $PROJECT_TYPE"
    echo "生成時間: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
    echo ""

    # 顯示 commit 資訊
    if [ "$COMPARE_TYPE" = "branch" ]; then
        echo "來源 Branch 最新 Commit:"
        git log -1 --format="%h - %s (%an, %ar)" "$SOURCE" 2>/dev/null || echo "無法取得資訊"
        echo ""
        echo "目標 Branch 最新 Commit:"
        if [ "$DEST" = "HEAD" ]; then
            git log -1 --format="%h - %s (%an, %ar)" HEAD
        else
            git log -1 --format="%h - %s (%an, %ar)" "$DEST" 2>/dev/null || echo "無法取得資訊"
        fi
    else
        echo "來源 Commit:"
        git log -1 --format="%h - %s (%an, %ar)" "$SOURCE" 2>/dev/null || echo "無法取得資訊"
        echo ""
        echo "目標 Commit:"
        git log -1 --format="%h - %s (%an, %ar)" "$DEST" 2>/dev/null || echo "無法取得資訊"
    fi

    echo ""
    echo "========================================"
    echo "檔案差異列表"
    echo "========================================"
    echo ""

    # 使用 git diff --name-status 獲取檔案狀態
    git diff --name-status "$SOURCE" "$DEST"

    echo ""
    echo "========================================"
    echo "檔案狀態說明"
    echo "========================================"
    echo "A  = Added (新增)"
    echo "M  = Modified (修改)"
    echo "D  = Deleted (刪除)"
    echo "R  = Renamed (重新命名)"
    echo "C  = Copied (複製)"
    echo "T  = Type changed (型別變更)"
    echo ""

} > "$DIFF_FILE"

echo -e "${GREEN}✓ 差異報告已生成：${NC}$DIFF_FILE\n"

# 獲取需要複製的檔案列表（排除已刪除的檔案）
echo -e "${YELLOW}正在複製檔案...${NC}"

# 計數器
COPIED_COUNT=0
SKIPPED_COUNT=0
ERROR_COUNT=0

# 讀取差異檔案（排除 D = Deleted）
while IFS=$'\t' read -r status file; do
    # 處理重新命名的情況 (R100 oldfile -> newfile)
    if [[ $status == R* ]]; then
        # 取新檔名
        file=$(echo "$file" | awk '{print $NF}')
    fi

    # 跳過已刪除的檔案
    if [[ $status == D* ]]; then
        echo -e "${YELLOW}  跳過已刪除: $file${NC}"
        ((SKIPPED_COUNT++))
        continue
    fi

    # 檢查檔案是否存在於目標版本
    if git cat-file -e "$DEST:$file" 2>/dev/null; then
        # 創建目標目錄
        TARGET_DIR="$OUTPUT_PATH/$(dirname "$file")"
        mkdir -p "$TARGET_DIR"

        # 複製檔案
        if git show "$DEST:$file" > "$OUTPUT_PATH/$file" 2>/dev/null; then
            echo -e "${GREEN}  ✓ 已複製: $file${NC}"
            ((COPIED_COUNT++))
        else
            echo -e "${RED}  ✗ 複製失敗: $file${NC}"
            ((ERROR_COUNT++))
        fi
    else
        echo -e "${YELLOW}  跳過不存在: $file${NC}"
        ((SKIPPED_COUNT++))
    fi

done < <(git diff --name-status "$SOURCE" "$DEST")

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}打包完成！${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "${BLUE}已複製檔案：${NC}$COPIED_COUNT"
echo -e "${YELLOW}已跳過檔案：${NC}$SKIPPED_COUNT"
if [ $ERROR_COUNT -gt 0 ]; then
    echo -e "${RED}錯誤數量：${NC}$ERROR_COUNT"
fi
echo -e "${BLUE}輸出目錄：${NC}$OUTPUT_PATH"
echo -e "${BLUE}差異報告：${NC}$DIFF_FILE"
echo -e "${GREEN}======================================${NC}"
