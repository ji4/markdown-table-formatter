#!/bin/bash

# 設定檔案名稱
INPUT_FILE="table.md"
OUTPUT_FILE="${INPUT_FILE%.*}_html.html"

# 檢查輸入檔案是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "錯誤: 找不到輸入檔案 '$INPUT_FILE'"
    exit 1
fi

# 處理檔案
awk '
BEGIN {
    print "<!DOCTYPE html>"
    print "<html>"
    print "<head>"
    print "<style>"
    print "table { border-collapse: collapse; width: 100%; }"
    print "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }"
    print "th { background-color: #f2f2f2; }"
    print ".list-item { margin: 5px 0; }"
    print "</style>"
    print "</head>"
    print "<body>"
    print "<table>"
    in_header = 1
}

# 跳過分隔線
/^[|:-]+$/ { next }

# 處理表格行
/^\|/ {
    # 移除開頭和結尾的 |
    gsub(/^\| *| *\|$/, "")
    
    # 分割欄位
    n = split($0, cells, /\|/)
    
    if (in_header) {
        print "<tr>"
        for (i = 1; i <= n; i++) {
            gsub(/^ +| +$/, "", cells[i])
            print "<th>" cells[i] "</th>"
        }
        print "</tr>"
        in_header = 0
    } else {
        print "<tr>"
        for (i = 1; i <= n; i++) {
            gsub(/^ +| +$/, "", cells[i])
            # 將 <br> 替換為 HTML 段落
            if (cells[i] ~ /<br>/) {
                # 移除開頭的空格和 - 
                gsub(/^[ -]*/, "", cells[i])
                # 替換 <br>- 為 HTML 列表項目
                gsub(/<br>- /, "</div><div class=\"list-item\">", cells[i])
                print "<td><div class=\"list-item\">" cells[i] "</div></td>"
            } else {
                print "<td>" cells[i] "</td>"
            }
        }
        print "</tr>"
    }
    next
}

END {
    print "</table>"
    print "</body>"
    print "</html>"
}
' "$INPUT_FILE" > "$OUTPUT_FILE"

echo "處理完成。輸出檔案為: $OUTPUT_FILE"

# 設定腳本為可執行
chmod +x "$0"