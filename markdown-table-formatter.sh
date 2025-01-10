#!/bin/bash

# 設定檔案名稱
INPUT_FILE="table.md"
OUTPUT_FILE="${INPUT_FILE%.*}_html.html"

# 檢查輸入檔案是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "錯誤: 找不到輸入檔案 '$INPUT_FILE'"
    exit 1
fi

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
    print ".content { margin: 1em 0; line-height: 1.5; }"  # 新增段落樣式
    print "</style>"
    print "</head>"
    print "<body>"
    
    list_stack_depth = 0
    in_table = 0
    table_buffer = ""
    prev_indent = -1
    list_item_content = ""
    in_list_item = 0
    current_list_num = 0
    processed_tables = ""
    in_conclusion = 0  # 新增：追蹤是否在結論段落中
    conclusion_content = ""  # 新增：儲存結論內容
}

function get_indent(line) {
    match(line, /[^ ]/)
    return RSTART - 1
}

function process_bullet_list(cell,    items, j, n, list) {
    list = "  <td><ul>\n"
    n = split(cell, items, /[•]/)
    for (j = 1; j <= n; j++) {
        gsub(/^ +| +$/, "", items[j])
        if (items[j] != "") {
            list = list "    <li>" items[j] "</li>\n"
        }
    }
    list = list "  </ul></td>\n"
    return list
}

function is_duplicate_table(table_content) {
    return (index(processed_tables, table_content) > 0)
}

function add_to_processed_tables(table_content) {
    processed_tables = processed_tables "\n" table_content
}

{
    if ($0 ~ /^## 結論$/) {
        in_conclusion = 1
        print "<h2>結論</h2>"
    }
    else if (in_conclusion && $0 !~ /^$/) {
        # 收集結論段落的內容
        if (conclusion_content == "") {
            conclusion_content = $0
        } else {
            conclusion_content = conclusion_content "<br>" $0
        }
    }
    else if (in_conclusion && $0 ~ /^$/) {
        # 當遇到空行時，輸出收集到的結論內容
        if (conclusion_content != "") {
            print "<div class=\"content\">" conclusion_content "</div>"
            conclusion_content = ""
        }
        in_conclusion = 0
    }
    else {
        # 原有的處理邏輯
        indent = get_indent($0)
        content = $0
        gsub(/^[[:space:]]+/, "", content)
        
        if ($0 ~ /^#{1,6} /) {
            if (in_table) {
                table_buffer = table_buffer "</table>\n</div>\n"
                if (!is_duplicate_table(table_buffer)) {
                    print table_buffer
                    add_to_processed_tables(table_buffer)
                }
                table_buffer = ""
                in_table = 0
            }
            level = match($0, /#{1,6}/)
            title = substr($0, RLENGTH + 2)
            print "<h" RLENGTH ">" title "</h" RLENGTH ">"
        }
        else if ($0 ~ /^\|/) {
            if (!in_table) {
                table_buffer = table_buffer "<div class=\"table-container\">\n<table>\n"
                in_table = 1
            }
            
            if (!($0 ~ /^[\| :-]+$/)) {
                gsub(/^ *\| *| *\| *$/, "", content)
                split(content, cells, /\|/)
                
                table_buffer = table_buffer "<tr>\n"
                for (i = 1; i <= length(cells); i++) {
                    cell = cells[i]
                    gsub(/^ +| +$/, "", cell)
                    
                    if (cell ~ /[•]/) {
                        table_buffer = table_buffer process_bullet_list(cell)
                    } else {
                        table_buffer = table_buffer "  <td>" cell "</td>\n"
                    }
                }
                table_buffer = table_buffer "</tr>\n"
            }
        }
        else if ($0 ~ /^[[:space:]]*$/) {
            if (in_table) {
                table_buffer = table_buffer "</table>\n</div>\n"
                if (!is_duplicate_table(table_buffer)) {
                    print table_buffer
                    add_to_processed_tables(table_buffer)
                }
                table_buffer = ""
                in_table = 0
            }
        }
        else if ($0 !~ /^[[:space:]]*$/) {
            print "<div class=\"content\">" $0 "</div>"
        }
    }
}

END {
    # 確保最後的結論內容被輸出
    if (conclusion_content != "") {
        print "<div class=\"content\">" conclusion_content "</div>"
    }
    if (in_table) {
        table_buffer = table_buffer "</table>\n</div>\n"
        if (!is_duplicate_table(table_buffer)) {
            print table_buffer
        }
    }
    print "</body>"
    print "</html>"
}' "$INPUT_FILE" > "$OUTPUT_FILE"

echo "處理完成。輸出檔案為: $OUTPUT_FILE"