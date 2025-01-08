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
    table_data = ""
    table_rows = 0
    in_table = 0
    in_header = 0
    in_list = 0
    list_level = 0
    list_type = ""
    buffer = ""
}

function process_table_row(line) {
    if (!in_table) {
        buffer = buffer "<div class=\"table-container\">\n<table>\n"
        in_table = 1
        in_header = 1
    }

    gsub(/^ *\| *| *\| *$/, "", line)
    if (line ~ /^[-:|]+$/) {
        in_header = 0
        buffer = buffer "<tr><td colspan=\"100%\">" line "</td></tr>\n"
        return
    }

    n = split(line, cells, /\|/)
    buffer = buffer "<tr>\n"
    
    for (i = 1; i <= n; i++) {
        cell = cells[i]
        gsub(/^ +| +$/, "", cell)
        
        if (in_header) {
            buffer = buffer "  <th>" cell "</th>\n"
        } else {
            if (cell ~ /[•-]/) {
                buffer = buffer "  <td><ul>\n"
                split(cell, items, /[•]/)
                for (j in items) {
                    if (items[j] != "") {
                        gsub(/^ +| +$/, "", items[j])
                        if (items[j] ~ /^-/) {
                            gsub(/^- */, "", items[j])
                        }
                        buffer = buffer "    <li>" items[j] "</li>\n"
                    }
                }
                buffer = buffer "  </ul></td>\n"
            } else {
                buffer = buffer "  <td>" cell "</td>\n"
            }
        }
    }
    buffer = buffer "</tr>\n"
}

{
    # 處理標題
    if ($0 ~ /^#{1,6} /) {
        if (in_table) {
            buffer = buffer "</table>\n</div>\n"
            in_table = 0
            print buffer
            buffer = ""
        }
        if (in_list) {
            print "</" list_type ">"
            in_list = 0
        }
        level = match($0, /#{1,6}/)
        title = substr($0, RLENGTH + 2)
        print "<h" RLENGTH ">" title "</h" RLENGTH ">"
        next
    }

    # 處理列表開始
    if ($0 ~ /^[[:space:]]*[0-9]+\. / || $0 ~ /^[[:space:]]*[-*] /) {
        indent = match($0, /[^ ]/)
        current_level = int((indent - 1) / 2)
        
        # 如果正在處理表格，先完成並輸出
        if (in_table && buffer != "") {
            buffer = buffer "</table>\n</div>\n"
            in_table = 0
            print buffer
            buffer = ""
        }
        
        # 處理列表層級
        if (!in_list || current_level > list_level) {
            if ($0 ~ /[0-9]+\. /) {
                print "<ol>"
                list_type = "ol"
            } else {
                print "<ul>"
                list_type = "ul"
            }
            list_level = current_level
            in_list = 1
        }
        
        content = $0
        if ($0 ~ /[0-9]+\. /) {
            gsub(/^[[:space:]]*[0-9]+\. /, "", content)
        } else {
            gsub(/^[[:space:]]*[-*] /, "", content)
        }
        
        # 移除列表標記後，檢查是否包含表格
        if (content ~ /^\|/) {
            print "<li>"
            process_table_row(content)
        } else {
            if (content ~ /:$/) {
                print "<li>" content
            } else {
                print "<li>" content "</li>"
            }
        }
        next
    }
    
    # 處理表格行
    if ($0 ~ /^[[:space:]]*\|/) {
        # 移除開頭的空白
        gsub(/^[[:space:]]*/, "")
        process_table_row($0)
        next
    }
    
    # 非表格行，結束當前表格
    if (in_table) {
        buffer = buffer "</table>\n</div>\n"
        in_table = 0
        if (in_list) {
            print buffer "</li>"
        } else {
            print buffer
        }
        buffer = ""
    }
    
    # 處理空行
    if ($0 ~ /^[[:space:]]*$/) {
        if (in_list) {
            print "</" list_type ">"
            in_list = 0
            list_level = 0
        }
    }
    
    # 處理其他內容
    if ($0 !~ /^[[:space:]]*$/ && !in_table) {
        print
    }
}

END {
    if (in_table) {
        buffer = buffer "</table>\n</div>\n"
        if (in_list) {
            print buffer "</li>"
        } else {
            print buffer
        }
    }
    if (in_list) {
        print "</" list_type ">"
    }
    print "</body>"
    print "</html>"
}
' "$INPUT_FILE" > "$OUTPUT_FILE"

echo "處理完成。輸出檔案為: $OUTPUT_FILE"