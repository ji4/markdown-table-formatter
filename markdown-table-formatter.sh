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
    print "ul, ol { margin: 0 0 1em 0; padding-left: 20px; }"
    print "li { margin: 5px 0; }"
    print "li > ul, li > ol { margin: 5px 0; }"  # 巢狀列表樣式
    print ".nested-content { margin-left: 20px; }"  # 巢狀內容的縮排
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
    print ".table-container { margin: 1em 0; clear: both; }"
    print "</style>"
    print "</head>"
    print "<body>"
    in_table = 0
    in_header = 0
    in_list = 0
    list_type = ""
    table_buffer = ""
    list_level = 0
    prev_line_empty = 0
}

# 檢查是否為表格標記行
function is_table_line(line) {
    return line ~ /^\|.*\|$/
}

# 檢查是否為表格分隔行
function is_table_separator(line) {
    return line ~ /^\|[\-:| ]+\|$/
}

# 處理表格行
{
    if (is_table_line($0)) {
        if (!in_table) {
            if (in_list) {
                table_buffer = "<div class=\"nested-content\">\n"
            }
            table_buffer = table_buffer "<div class=\"table-container\">\n<table>\n"
            in_table = 1
            in_header = 1
        }
        
        line = $0
        gsub(/^ *\| *| *\| *$/, "", line)
        n = split(line, cells, / *\| */)
        
        if (!is_table_separator($0)) {
            table_buffer = table_buffer "<tr>\n"
            for (i = 1; i <= n; i++) {
                cell_content = cells[i]
                gsub(/^ +| +$/, "", cell_content)
                
                if (in_header) {
                    table_buffer = table_buffer "  <th>" cell_content "</th>\n"
                } else {
                    if (cell_content ~ /^[•-]/) {
                        table_buffer = table_buffer "  <td><ul>\n"
                        split(cell_content, items, /<br>/)
                        for (j in items) {
                            if (items[j] ~ /^[•-]/) {
                                gsub(/^[•-] */, "", items[j])
                                if (items[j] != "") {
                                    table_buffer = table_buffer "    <li>" items[j] "</li>\n"
                                }
                            }
                        }
                        table_buffer = table_buffer "  </ul></td>\n"
                    } else {
                        table_buffer = table_buffer "  <td>" cell_content "</td>\n"
                    }
                }
            }
            table_buffer = table_buffer "</tr>\n"
        } else {
            in_header = 0
        }
        next
    } else {
        if (in_table) {
            print table_buffer "</table>\n</div>"
            if (in_list) {
                print "</div>"
            }
            table_buffer = ""
            in_table = 0
            in_header = 0
        }
    }
    
    # 處理標題
    if ($0 ~ /^#{1,6} /) {
        if (in_list) {
            print "</" list_type ">"
            in_list = 0
        }
        level = match($0, /#{1,6}/)
        title = substr($0, RLENGTH + 2)
        print "<h" RLENGTH ">" title "</h" RLENGTH ">"
        next
    }
    
    # 處理列表
    if ($0 ~ /^[0-9]+\. / || $0 ~ /^[-*] /) {
        indent = match($0, /[^[:space:]]/)
        current_level = int((indent - 1) / 2)
        
        if (!in_list || current_level == 0) {
            if ($0 ~ /^[0-9]+\. /) {
                print "<ol>"
                list_type = "ol"
            } else {
                print "<ul>"
                list_type = "ul"
            }
            in_list = 1
            list_level = current_level
        } else if (current_level > list_level) {
            if ($0 ~ /^[0-9]+\. /) {
                print "<li><ol class=\"nested-list\">"
                list_type = "ol"
            } else {
                print "<li><ul class=\"nested-list\">"
                list_type = "ul"
            }
            list_level = current_level
        } else if (current_level < list_level) {
            while (list_level > current_level) {
                print "</li></" list_type ">"
                list_level--
            }
        }
        
        if ($0 ~ /^[0-9]+\. /) {
            gsub(/^[0-9]+\. /, "")
        } else {
            gsub(/^[-*] /, "")
        }
        print "<li>" $0
        
        if ($0 ~ /[^[:space:]]$/) {
            print "</li>"
        }
        next
    } else if (in_list && $0 ~ /^$/) {
        print "</li></" list_type ">"
        in_list = 0
        list_level = 0
    }
    
    # 處理其他 Markdown 格式
    gsub(/\*\*([^\*]+)\*\*/, "<strong>\\1</strong>")
    gsub(/\*([^\*]+)\*/, "<em>\\1</em>")
    gsub(/`([^`]+)`/, "<code>\\1</code>")
    
    if ($0 !~ /^$/) {
        print
    }
    
    prev_line_empty = ($0 ~ /^$/)
}

END {
    if (in_table) {
        print table_buffer "</table>\n</div>"
        if (in_list) {
            print "</div>"
        }
    }
    if (in_list) {
        print "</li></" list_type ">"
    }
    print "</body>"
    print "</html>"
}
' "$INPUT_FILE" > "$OUTPUT_FILE"

echo "處理完成。輸出檔案為: $OUTPUT_FILE"

# 設定腳本為可執行
chmod +x "$0"