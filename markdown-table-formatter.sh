#!/bin/bash

# 設定檔案名稱
INPUT_FILE="table.md"
OUTPUT_FILE="${INPUT_FILE%.*}_html.html"

# 檢查輸入檔案是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "錯誤: 找不到輸入檔案 '$INPUT_FILE'"
    exit 1
fi

# 主要處理
awk '
BEGIN {
    print "<!DOCTYPE html>"
    print "<html>"
    print "<head>"
    print "<style>"
    print "table { border-collapse: collapse; width: 100%; margin: 20px 0; }"
    print "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }"
    print "th { background-color: #f2f2f2; }"
    print "ul, ol { margin: 0 0 1em 0; padding-left: 20px; }"
    print "li { margin: 5px 0; }"
    print "li > ul, li > ol { margin: 5px 0; }"
    print ".nested-content { margin-left: 20px; }"
    print ".table-container { margin: 1em 0; clear: both; }"
    print "h1 { font-size: 2em; margin: 0.67em 0; }"
    print "h2 { font-size: 1.5em; margin: 0.75em 0; }"
    print "h3 { font-size: 1.17em; margin: 0.83em 0; }"
    print "h4 { font-size: 1em; margin: 1.12em 0; }"
    print "h5 { font-size: .83em; margin: 1.5em 0; }"
    print "h6 { font-size: .75em; margin: 1.67em 0; }"
    print "</style>"
    print "</head>"
    print "<body>"
    
    base_indent = -1
    current_list = ""
    current_item = ""
    in_table = 0
    table_content = ""
    table_row_count = 0
    skip_next_separator = 0
}

function get_indent(line) {
    match(line, /[^ ]/)
    return RSTART - 1
}

function process_table_row(line,    cells, i, n, cell, items, j) {
    # 忽略純分隔行
    if (line ~ /^[\| :-]+$/) {
        return
    }

    if (!in_table) {
        table_content = "<div class=\"table-container\">\n<table>\n"
        in_table = 1
        table_row_count = 0
    }

    # 移除首尾的管道符號並分割儲存格
    gsub(/^ *\| *| *\| *$/, "", line)
    n = split(line, cells, /\|/)
    
    table_content = table_content "<tr>\n"
    
    for (i = 1; i <= n; i++) {
        cell = cells[i]
        gsub(/^ +| +$/, "", cell)
        
        # 第一行使用 th
        if (table_row_count == 0) {
            table_content = table_content "  <th>" cell "</th>\n"
        } else {
            if (cell ~ /[•]/) {
                table_content = table_content "  <td><ul>\n"
                split(cell, items, /[•]/)
                for (j in items) {
                    item = items[j]
                    gsub(/^ +| +$/, "", item)
                    if (item != "") {
                        table_content = table_content "    <li>" item (j < length(items) ? "<br>" : "") "</li>\n"
                    }
                }
                table_content = table_content "  </ul></td>\n"
            } else {
                table_content = table_content "  <td>" cell "</td>\n"
            }
        }
    }
    
    table_content = table_content "</tr>\n"
    table_row_count++
}

function flush_list_item() {
    if (current_item) {
        if (table_content) {
            table_content = table_content "</table>\n</div>"
            print current_item table_content "</li>"
            table_content = ""
            in_table = 0
            table_row_count = 0
        } else {
            print current_item "</li>"
        }
        current_item = ""
    }
}

{
    indent = get_indent($0)
    content = $0
    gsub(/^[[:space:]]+/, "", content)
    
    # 設置基準縮進
    if (base_indent == -1 && content ~ /^[-*]/) {
        base_indent = indent
    }
    
    # 處理列表項
    if (content ~ /^[-*]/) {
        # 開始新列表
        if (!current_list) {
            print "<ul>"
            current_list = "ul"
        }
        
        # 處理前一個列表項
        flush_list_item()
        
        # 處理新列表項
        sub(/^[-*][[:space:]]*/, "", content)
        current_item = "<li>" content
    }
    # 處理表格行
    else if (content ~ /^\|/ && indent > base_indent) {
        process_table_row(content)
    }
    # 處理空行
    else if (content ~ /^[[:space:]]*$/) {
        flush_list_item()
        if (current_list) {
            print "</" current_list ">"
            current_list = ""
        }
        base_indent = -1
    }
}

END {
    flush_list_item()
    if (current_list) {
        print "</" current_list ">"
    }
    print "</body>"
    print "</html>"
}
' "$INPUT_FILE" > "$OUTPUT_FILE"

echo "處理完成。輸出檔案為: $OUTPUT_FILE"