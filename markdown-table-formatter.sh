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
    print "table { border-collapse: collapse; width: 100%; margin: 20px 0; }"
    print "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }"
    print "th { background-color: #f2f2f2; }"
    print "ul { margin: 0; padding-left: 20px; }"
    print "li { margin: 5px 0; }"
    # Markdown 格式的 CSS
    print "h1 { font-size: 2em; margin: 0.67em 0; }"
    print "h2 { font-size: 1.5em; margin: 0.75em 0; }"
    print "h3 { font-size: 1.17em; margin: 0.83em 0; }"
    print "h4 { font-size: 1em; margin: 1.12em 0; }"
    print "h5 { font-size: .83em; margin: 1.5em 0; }"
    print "h6 { font-size: .75em; margin: 1.67em 0; }"
    print "strong { font-weight: bold; }"
    print "em { font-style: italic; }"
    print "code { font-family: monospace; background-color: #f5f5f5; padding: 2px 4px; }"
    print "pre { background-color: #f5f5f5; padding: 16px; overflow: auto; }"
    print "blockquote { border-left: 4px solid #ddd; margin: 0; padding-left: 16px; }"
    print "</style>"
    print "</head>"
    print "<body>"
    in_table = 0
    in_header = 0
    in_list = 0
}

# 處理表格開始
/^\|/ {
    if (!in_table) {
        print "<table>"
        in_table = 1
        in_header = 1
    }
}

# 處理表格分隔線
/^[|:-]+$/ { 
    in_header = 0
    next 
}

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
    } else {
        print "<tr>"
        for (i = 1; i <= n; i++) {
            gsub(/^ +| +$/, "", cells[i])
            if (cells[i] ~ /<br>/) {
                # 將列表項目轉換為 HTML 無序列表
                split(cells[i], items, /<br>/)
                print "<td><ul>"
                for (j = 1; j <= length(items); j++) {
                    if (items[j] ~ /^- /) {
                        gsub(/^- /, "", items[j])
                        print "<li>" items[j] "</li>"
                    }
                }
                print "</ul></td>"
            } else {
                print "<td>" cells[i] "</td>"
            }
        }
        print "</tr>"
    }
    next
}

# 處理非表格行
{
    if (in_table) {
        print "</table>"
        in_table = 0
    }
    
    # 處理 Markdown 格式
    # 標題
    if ($0 ~ /^#{1,6} /) {
        level = match($0, /#{1,6}/)
        title = substr($0, RLENGTH + 2)
        print "<h" RLENGTH ">" title "</h" RLENGTH ">"
        next
    }
    
    # 處理列表項目
    if ($0 ~ /^- /) {
        if (!in_list) {
            print "<ul>"
            in_list = 1
        }
        gsub(/^- /, "")
        print "<li>" $0 "</li>"
        next
    } else if (in_list && $0 !~ /^- /) {
        print "</ul>"
        in_list = 0
    }
    
    # 加粗
    gsub(/\*\*([^\*]+)\*\*/, "<strong>\\1</strong>")
    # 斜體
    gsub(/\*([^\*]+)\*/, "<em>\\1</em>")
    # 行內程式碼
    gsub(/`([^`]+)`/, "<code>\\1</code>")
    
    if ($0 !~ /^$/) {
        print
    }
}

END {
    if (in_table) {
        print "</table>"
    }
    if (in_list) {
        print "</ul>"
    }
    print "</body>"
    print "</html>"
}
' "$INPUT_FILE" > "$OUTPUT_FILE"

echo "處理完成。輸出檔案為: $OUTPUT_FILE"

# 設定腳本為可執行
chmod +x "$0"