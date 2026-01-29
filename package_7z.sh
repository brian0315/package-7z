#!/bin/bash

# 7z 壓縮檔建立腳本
# 功能：
# - 可輸入輸出 7z 檔案名稱
# - 可指定多個要打包的資料夾
# - 可包含 xlsx 檔案
# - 檢查並刪除 .DS_Store 檔案
# - 產生隨機 12 碼密碼（不包含符號）
# - 使用 -mhe=on 加密壓縮

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
    echo "  -b <base_dir>    基礎目錄路徑（所有相對路徑的參考點，預設：當前目錄）"
    echo "  -d <folders>     要打包的資料夾，用逗號分隔（例如：front,api）"
    echo "  -x <xlsx_file>   要包含的 xlsx 檔案（相對於基礎目錄）"
    echo "  -o <output_7z>   輸出的 7z 檔案名稱（預設：archive_YYYYMMDD_HHMMSS.7z）"
    echo "  -p <password>    指定密碼（若不指定則自動產生 12 碼隨機密碼）"
    echo "  -h               顯示此說明"
    echo ""
    echo "範例："
    echo "  # 打包 front 和 api 資料夾，包含 diff.xlsx"
    echo "  $0 -b /path/to/project -d front,api -x diff.xlsx"
    echo ""
    echo "  # 只打包單一資料夾"
    echo "  $0 -b /path/to/project -d front -o release.7z"
    echo ""
    echo "  # 指定密碼"
    echo "  $0 -b /path/to/project -d front,api -x diff.xlsx -p MyPass123"
    echo ""
    echo "  # 使用當前目錄作為基礎目錄"
    echo "  $0 -d front,api -x diff.xlsx"
    exit 1
}

# 產生隨機密碼（12 碼，只包含英數字）
generate_password() {
    # 使用 /dev/urandom 產生隨機英數字，長度 12
    LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 12
}

# 檢查並刪除 .DS_Store 檔案
remove_ds_store() {
    local base_dir="$1"
    local folders="$2"

    echo -e "${YELLOW}檢查 .DS_Store 檔案...${NC}"

    local ds_count=0

    # 針對每個資料夾檢查 .DS_Store
    IFS=',' read -ra FOLDER_ARRAY <<< "$folders"
    for folder in "${FOLDER_ARRAY[@]}"; do
        local folder_path="$base_dir/$folder"
        if [ -d "$folder_path" ]; then
            local ds_files=$(find "$folder_path" -name '.DS_Store' -print 2>/dev/null)
            if [ -n "$ds_files" ]; then
                echo -e "${YELLOW}在 $folder/ 中找到：${NC}"
                echo "$ds_files"
                find "$folder_path" -name '.DS_Store' -delete
                ((ds_count++))
            fi
        fi
    done

    if [ $ds_count -eq 0 ]; then
        echo -e "${GREEN}✓ 沒有找到 .DS_Store 檔案${NC}"
    else
        echo -e "${GREEN}✓ .DS_Store 檔案已清除${NC}"
    fi
}

# 驗證要打包的項目
validate_items() {
    local base_dir="$1"
    local folders="$2"
    local xlsx_file="$3"

    local all_valid=true

    echo -e "${YELLOW}驗證要打包的項目...${NC}"

    # 檢查資料夾
    if [ -n "$folders" ]; then
        IFS=',' read -ra FOLDER_ARRAY <<< "$folders"
        for folder in "${FOLDER_ARRAY[@]}"; do
            local folder_path="$base_dir/$folder"
            if [ ! -d "$folder_path" ]; then
                echo -e "${RED}✗ 資料夾不存在：$folder${NC}"
                all_valid=false
            else
                echo -e "${GREEN}✓ 資料夾確認：$folder/${NC}"
            fi
        done
    fi

    # 檢查 xlsx 檔案
    if [ -n "$xlsx_file" ]; then
        local xlsx_path="$base_dir/$xlsx_file"
        if [ ! -f "$xlsx_path" ]; then
            echo -e "${RED}✗ xlsx 檔案不存在：$xlsx_file${NC}"
            all_valid=false
        else
            echo -e "${GREEN}✓ xlsx 檔案確認：$xlsx_file${NC}"
        fi
    fi

    if [ "$all_valid" = false ]; then
        return 1
    fi

    return 0
}

# 檢查 7z 是否已安裝
check_7z_installed() {
    if ! command -v 7z &> /dev/null; then
        echo -e "${RED}錯誤：未找到 7z 命令${NC}"
        echo -e "${YELLOW}請先安裝 7z：${NC}"
        echo "  macOS:   brew install p7zip"
        echo "  Ubuntu:  sudo apt-get install p7zip-full"
        echo "  CentOS:  sudo yum install p7zip"
        exit 1
    fi
}

# 預設值
BASE_DIR="."
FOLDERS=""
OUTPUT_FILE=""
PASSWORD=""
XLSX_FILE=""

# 解析參數
while getopts "b:d:o:p:x:h" opt; do
    case $opt in
        b) BASE_DIR="$OPTARG" ;;
        d) FOLDERS="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        p) PASSWORD="$OPTARG" ;;
        x) XLSX_FILE="$OPTARG" ;;
        h) usage ;;
        ?) usage ;;
    esac
done

# 驗證必要參數
if [ -z "$FOLDERS" ] && [ -z "$XLSX_FILE" ]; then
    echo -e "${RED}錯誤：必須至少指定要打包的資料夾 (-d) 或 xlsx 檔案 (-x)${NC}"
    usage
fi

# 檢查基礎目錄是否存在
if [ ! -d "$BASE_DIR" ]; then
    echo -e "${RED}錯誤：基礎目錄不存在：$BASE_DIR${NC}"
    exit 1
fi

# 轉換為絕對路徑
BASE_DIR=$(cd "$BASE_DIR" && pwd)

# 檢查 7z 是否已安裝
check_7z_installed

# 設定預設輸出檔名（如果未指定）
if [ -z "$OUTPUT_FILE" ]; then
    TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
    OUTPUT_FILE="archive_${TIMESTAMP}.7z"
fi

# 確保輸出檔名有 .7z 副檔名
if [[ ! "$OUTPUT_FILE" =~ \.7z$ ]]; then
    OUTPUT_FILE="${OUTPUT_FILE}.7z"
fi

# 產生密碼（如果未指定）
if [ -z "$PASSWORD" ]; then
    PASSWORD=$(generate_password)
    AUTO_GENERATED_PASSWORD=true
else
    AUTO_GENERATED_PASSWORD=false
fi

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}7z 壓縮檔建立工具${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "${BLUE}基礎目錄：${NC}$BASE_DIR"
if [ -n "$FOLDERS" ]; then
    echo -e "${BLUE}打包資料夾：${NC}$FOLDERS"
fi
if [ -n "$XLSX_FILE" ]; then
    echo -e "${BLUE}包含檔案：${NC}$XLSX_FILE"
fi
echo -e "${BLUE}輸出檔案：${NC}$OUTPUT_FILE"
if [ "$AUTO_GENERATED_PASSWORD" = true ]; then
    echo -e "${BLUE}密碼：${NC}${YELLOW}[自動產生]${NC}"
else
    echo -e "${BLUE}密碼：${NC}[已指定]"
fi
echo -e "${GREEN}======================================${NC}\n"

# 驗證所有要打包的項目
if ! validate_items "$BASE_DIR" "$FOLDERS" "$XLSX_FILE"; then
    exit 1
fi

echo ""

# 移除 .DS_Store 檔案
if [ -n "$FOLDERS" ]; then
    remove_ds_store "$BASE_DIR" "$FOLDERS"
    echo ""
fi

# 準備要打包的項目列表
PACK_ITEMS=()

# 添加資料夾
if [ -n "$FOLDERS" ]; then
    IFS=',' read -ra FOLDER_ARRAY <<< "$FOLDERS"
    for folder in "${FOLDER_ARRAY[@]}"; do
        PACK_ITEMS+=("$folder/")
    done
fi

# 添加 xlsx 檔案
if [ -n "$XLSX_FILE" ]; then
    PACK_ITEMS+=("$XLSX_FILE")
fi

# 建立 7z 壓縮檔
echo -e "${YELLOW}正在建立 7z 壓縮檔...${NC}"
echo -e "${BLUE}使用參數：${NC}"
echo "  - 加密標頭：啟用 (-mhe=on)"
echo "  - 密碼保護：啟用"
echo -e "${BLUE}打包項目：${NC}"
for item in "${PACK_ITEMS[@]}"; do
    echo "  - $item"
done
echo ""

# 切換到基礎目錄執行打包
cd "$BASE_DIR"

# 執行 7z 壓縮
# -mhe=on: 加密檔案標頭
# -p: 設定密碼
if 7z a -mhe=on -p"$PASSWORD" "$OUTPUT_FILE" "${PACK_ITEMS[@]}" ; then
    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}✓ 壓縮完成！${NC}"
    echo -e "${GREEN}======================================${NC}"

    # 顯示完整路徑（如果是相對路徑）
    if [[ "$OUTPUT_FILE" != /* ]]; then
        OUTPUT_FILE="$BASE_DIR/$OUTPUT_FILE"
    fi

    echo -e "${BLUE}輸出檔案：${NC}$OUTPUT_FILE"

    # 顯示檔案大小
    if [ -f "$OUTPUT_FILE" ]; then
        FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
        echo -e "${BLUE}檔案大小：${NC}$FILE_SIZE"
    fi

    echo ""
    if [ "$AUTO_GENERATED_PASSWORD" = true ]; then
        echo -e "${YELLOW}⚠ 重要：請妥善保存以下密碼${NC}"
        echo -e "${GREEN}密碼：${NC}${YELLOW}$PASSWORD${NC}"
    else
        echo -e "${GREEN}使用指定的密碼${NC}"
    fi

    echo ""
    echo -e "${GREEN}打包內容摘要：${NC}"
    if [ -n "$FOLDERS" ]; then
        echo -e "${BLUE}  資料夾：${NC}$FOLDERS"
    fi
    if [ -n "$XLSX_FILE" ]; then
        echo -e "${BLUE}  檔案：${NC}$XLSX_FILE"
    fi

    echo -e "${GREEN}======================================${NC}"
else
    echo ""
    echo -e "${RED}======================================${NC}"
    echo -e "${RED}✗ 壓縮失敗${NC}"
    echo -e "${RED}======================================${NC}"
    exit 1
fi
