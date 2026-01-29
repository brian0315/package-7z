# Git 自動打包工具

這是一個自動化的 Git 打包腳本，可以比較不同 branch 或 commit 之間的差異，並將變更的檔案複製到指定目錄。

## 功能特點

- ✅ 支援 branch 與 branch 之間的比較
- ✅ 支援 commit 與 commit 之間的比較
- ✅ 自動生成差異報告 (diff.txt)
- ✅ 保留完整的目錄結構
- ✅ 支援選擇專案類型 (api / front)
- ✅ 自動排除已刪除的檔案
- ✅ 顯示檔案狀態（新增、修改、刪除等）
- ✅ 彩色輸出，清晰易讀

## 使用方法

### 基本語法

```bash
~/Documents/scripts/package.sh [選項]
```

### 參數說明

| 參數 | 說明 | 預設值 |
|------|------|--------|
| `-t` | 比較類型：`branch` 或 `commit` | `branch` |
| `-s` | 來源 branch/commit（必填） | 無 |
| `-d` | 目標 branch/commit | `HEAD` |
| `-p` | 專案類型：`api` 或 `front` | `front` |
| `-o` | 輸出目錄路徑 | `./package_output` |
| `-h` | 顯示使用說明 | - |

## 使用範例

### 範例 1：比較兩個 branch（前端專案）

```bash
cd /path/to/your/project
~/Documents/scripts/package.sh -t branch -s main -d develop -p front -o ~/Desktop/release
```

這會：
- 比較 `main` 和 `develop` 兩個 branch
- 將差異檔案複製到 `~/Desktop/release/front/`
- 在 `~/Desktop/release/diff.txt` 生成差異報告

### 範例 2：比較當前版本與 main branch

```bash
cd /path/to/your/project
~/Documents/scripts/package.sh -s main -p front
```

這會：
- 比較 `main` branch 與當前 HEAD
- 輸出到預設目錄 `./package_output/front/`
- 生成 `./package_output/diff.txt`

### 範例 3：比較兩個 commit（後端專案）

```bash
cd /path/to/your/project
~/Documents/scripts/package.sh -t commit -s abc123def -d 456789ghi -p api -o ~/output
```

這會：
- 比較兩個 commit hash
- 將差異檔案複製到 `~/output/api/`
- 生成 `~/output/diff.txt`

### 範例 4：比較特定 commit 與當前版本

```bash
cd /path/to/your/project
~/Documents/scripts/package.sh -t commit -s c907bf2 -p front -o ~/Desktop/patch
```

## 輸出說明

### 目錄結構

執行後會在輸出目錄產生以下結構：

```
output_directory/
├── diff.txt          # 差異報告
└── front/           # 或 api/（依據 -p 參數）
    └── [保留原始目錄結構的檔案]
```

### diff.txt 內容

差異報告包含：
- 比較資訊（類型、來源、目標）
- 生成時間
- Commit 資訊
- 檔案差異列表及狀態

檔案狀態說明：
- `A` = Added (新增)
- `M` = Modified (修改)
- `D` = Deleted (刪除)
- `R` = Renamed (重新命名)
- `C` = Copied (複製)
- `T` = Type changed (型別變更)

## 快速使用腳本

### 在任何專案中使用

```bash
# 進入你的專案目錄
cd /Users/fujiaren/code/FIAP/fiap-iaws-front

# 執行打包（前端專案）
~/Documents/scripts/package.sh -s main -p front -o ~/Desktop/release
```

### 建立別名（optional）

在 `~/.zshrc` 或 `~/.bashrc` 中加入：

```bash
alias gitpack='~/Documents/scripts/package.sh'
```

然後就可以簡化使用：

```bash
gitpack -s main -p front -o ~/Desktop/release
```

## 注意事項

1. **必須在 Git 專案目錄中執行**
   - 腳本會檢查當前目錄是否為 Git 倉庫

2. **來源參數必填**
   - 必須使用 `-s` 指定來源 branch 或 commit

3. **檔案複製策略**
   - 只複製新增 (A) 和修改 (M) 的檔案
   - 自動跳過已刪除 (D) 的檔案
   - 保留完整的目錄結構

4. **權限問題**
   - 確保腳本有執行權限：`chmod +x ~/Documents/scripts/package.sh`

## 常見問題

### Q: 如何查看可用的 branch？
```bash
git branch -a
```

### Q: 如何查看 commit hash？
```bash
git log --oneline
```

### Q: 輸出目錄已存在會怎樣？
A: 腳本會覆蓋或合併檔案，建議每次使用不同的輸出目錄。

### Q: 可以比較遠端 branch 嗎？
A: 可以，例如：`-s origin/main -d origin/develop`

## 版本資訊

- 版本：1.0.0
- 建立日期：2026-01-29
- 相容系統：macOS, Linux
- Shell：Bash

## 授權

此腳本為內部使用工具。

---

# 7z 壓縮檔建立工具

這是一個自動化的 7z 壓縮腳本，可以安全地建立加密的 7z 壓縮檔。

## 功能特點

- ✅ 選擇性打包：只打包指定的資料夾和檔案
- ✅ 自動檢查並刪除 .DS_Store 檔案
- ✅ 自動產生 12 碼隨機密碼（僅英數字，不含符號）
- ✅ 使用 -mhe=on 加密檔案標頭（更安全）
- ✅ 支援多個資料夾同時打包
- ✅ 可包含 xlsx 差異檔案
- ✅ 可自訂輸出檔名和密碼
- ✅ 彩色輸出，清楚顯示處理流程

## 安裝需求

### macOS
```bash
brew install p7zip
```

### Ubuntu/Debian
```bash
sudo apt-get install p7zip-full
```

### CentOS/RHEL
```bash
sudo yum install p7zip
```

## 使用方法

### 基本語法

```bash
~/Documents/scripts/create_7z.sh [選項]
```

### 參數說明

| 參數 | 說明 | 預設值 |
|------|------|--------|
| `-b` | 基礎目錄路徑（所有相對路徑的參考點） | 當前目錄 |
| `-d` | 要打包的資料夾，用逗號分隔（例如：front,api） | 無 |
| `-x` | 要包含的 xlsx 檔案（相對於基礎目錄） | 無 |
| `-o` | 輸出的 7z 檔案名稱 | `archive_YYYYMMDD_HHMMSS.7z` |
| `-p` | 指定密碼 | 自動產生 12 碼隨機密碼 |
| `-h` | 顯示使用說明 | - |

**注意**：至少要指定 `-d`（資料夾）或 `-x`（xlsx 檔案）其中一個。

## 使用範例

### 範例 1：打包多個資料夾和 xlsx 檔案（最常用）

```bash
~/Documents/scripts/create_7z.sh -b /path/to/project -d front,api -x diff.xlsx
```

這會：
- 在 `/path/to/project` 目錄下
- 只打包 `front/` 和 `api/` 兩個資料夾
- 包含 `diff.xlsx` 檔案
- 自動產生 12 碼隨機密碼
- 建立加密的 7z 檔案（檔名：archive_20260129_153045.7z）

這相當於執行：`7z a -mhe=on -p<密碼> archive.7z front/ api/ diff.xlsx`

### 範例 2：使用當前目錄作為基礎目錄

```bash
cd /path/to/project
~/Documents/scripts/create_7z.sh -d front,api -x diff.xlsx
```

### 範例 3：只打包單一資料夾

```bash
~/Documents/scripts/create_7z.sh -b ~/Documents/project -d front -o release.7z
```

### 範例 4：指定密碼和輸出檔名

```bash
~/Documents/scripts/create_7z.sh -b ~/Documents/project -d front,api -x diff.xlsx -p MyPass123 -o release_v1.7z
```

### 範例 5：只打包 xlsx 檔案（不包含資料夾）

```bash
~/Documents/scripts/create_7z.sh -b ~/Documents/project -x diff.xlsx -o diff_only.7z
```

### 範例 6：打包三個資料夾

```bash
~/Documents/scripts/create_7z.sh -b ~/Documents/project -d front,api,docs -o full_package.7z
```

## 腳本流程

1. **參數驗證**
   - 檢查必要參數（至少需要 `-d` 或 `-x` 其中一個）
   - 驗證基礎目錄存在
   - 檢查 7z 是否已安裝

2. **項目驗證**
   - 檢查指定的資料夾是否存在
   - 檢查指定的 xlsx 檔案是否存在
   - 顯示所有要打包的項目

3. **清理 .DS_Store**
   - 在指定的資料夾中搜尋所有 .DS_Store 檔案
   - 顯示找到的檔案清單
   - 自動刪除所有 .DS_Store 檔案

4. **產生密碼**
   - 若未指定 `-p` 參數，自動產生 12 碼隨機密碼
   - 密碼僅包含英數字（A-Z, a-z, 0-9）

5. **建立 7z 壓縮檔**
   - 只打包指定的資料夾和 xlsx 檔案
   - 使用 `-mhe=on` 加密檔案標頭
   - 使用密碼保護
   - 顯示壓縮進度

6. **完成報告**
   - 顯示輸出檔案位置
   - 顯示檔案大小
   - 顯示產生的密碼（若為自動產生）
   - 顯示打包內容摘要

## 建立別名（optional）

在 `~/.zshrc` 或 `~/.bashrc` 中加入：

```bash
alias create7z='~/Documents/scripts/create_7z.sh'
```

然後就可以簡化使用：

```bash
# 在專案目錄中直接執行
cd ~/Documents/project
create7z -d front,api -x diff.xlsx -o release.7z
```

## 注意事項

1. **密碼安全**
   - 自動產生的密碼只會顯示一次，請務必妥善保存
   - 建議將密碼記錄在安全的地方

2. **.DS_Store 檔案**
   - macOS 系統會自動產生 .DS_Store 檔案
   - 腳本會在壓縮前自動清除這些檔案
   - 清除過程會顯示找到的檔案清單

3. **檔案標頭加密**
   - 使用 `-mhe=on` 參數
   - 即使沒有密碼也無法看到壓縮檔內的檔案列表
   - 提供更高的安全性

4. **權限問題**
   - 確保腳本有執行權限：`chmod +x ~/Documents/scripts/create_7z.sh`

## 常見問題

### Q: 忘記密碼怎麼辦？
A: 7z 使用強加密，若忘記密碼將無法解壓縮。請務必妥善保存密碼。

### Q: 可以壓縮多個資料夾嗎？
A: 可以！使用逗號分隔多個資料夾名稱：`-d front,api,docs`

### Q: xlsx 檔案一定要在基礎目錄的根目錄嗎？
A: 不一定。`-x` 參數接受相對路徑，例如：`-x reports/diff.xlsx`

### Q: 如何只打包資料夾不包含 xlsx？
```bash
create7z.sh -b ~/project -d front,api -o release.7z
```

### Q: 如何只打包 xlsx 不包含資料夾？
```bash
create7z.sh -b ~/project -x diff.xlsx -o diff_only.7z
```

### Q: 壓縮檔會包含其他未指定的檔案嗎？
A: 不會！腳本只會打包 `-d` 指定的資料夾和 `-x` 指定的檔案，其他檔案會被排除。

### Q: 可以指定子資料夾嗎？
A: 可以！例如：`-d src/components,src/utils`

### Q: 如何解壓縮？
```bash
7z x archive.7z
# 或指定輸出目錄
7z x archive.7z -o/path/to/output
```

## 實際使用案例

假設你的專案結構如下：

```
/Users/john/myproject/
├── front/
│   ├── src/
│   └── public/
├── api/
│   ├── controllers/
│   └── models/
├── diff.xlsx
├── README.md
└── package.json
```

如果你只想打包 `front/`、`api/` 和 `diff.xlsx`，排除其他檔案：

```bash
~/Documents/scripts/create_7z.sh -b /Users/john/myproject -d front,api -x diff.xlsx -o release.7z
```

這會建立一個包含以下內容的加密 7z 檔案：
- `front/` 資料夾（含所有內容）
- `api/` 資料夾（含所有內容）
- `diff.xlsx` 檔案
- 自動產生的隨機密碼

**不會包含**：README.md、package.json 或其他未指定的檔案。

## 版本資訊

- 版本：2.0.0
- 更新日期：2026-01-29
- 相容系統：macOS, Linux
- Shell：Bash
- 主要更新：支援選擇性打包指定的資料夾和檔案
