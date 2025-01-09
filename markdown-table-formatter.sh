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
    is_first_table_row = 1
    list_stack_type[0] = ""
    list_stack_depth = 0
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

function process_table_row(line,    cells, i, n, cell) {
    if (line ~ /^[\| :-]+$/) {
        is_first_table_row = 0
        return
    }

    if (!in_table) {
        table_content = "<div class=\"table-container\">\n<table>\n"
        in_table = 1
        table_row_count = 0
    }

    gsub(/^ *\| *| *\| *$/, "", line)
    n = split(line, cells, /\|/)
    
    table_content = table_content "<tr>\n"
    
    for (i = 1; i <= n; i++) {
        cell = cells[i]
        gsub(/^ +| +$/, "", cell)
        
        if (is_first_table_row) {
            table_content = table_content "  <th>" cell "</th>\n"
        } else {
            if (cell ~ /[•]/) {
                table_content = table_content process_bullet_list(cell)
            } else {
                table_content = table_content "  <td>" cell "</td>\n"
            }
        }
    }
    
    table_content = table_content "</tr>\n"
    table_row_count++
    is_first_table_row = 0
}

function start_list(type, indent) {
    list_stack_type[list_stack_depth] = type
    list_stack_indent[list_stack_depth] = indent
    list_stack_depth++
    return "<" type ">"
}

function end_list(until_indent,    i, output) {
    output = ""
    for (i = list_stack_depth - 1; i >= 0; i--) {
        if (list_stack_indent[i] > until_indent) {
            output = output "</" list_stack_type[i] ">\n"
            list_stack_depth--
        }
    }
    return output
}

function flush_list_item() {
    if (current_item) {
        if (table_content) {
            table_content = table_content "</table>\n</div>"
            print current_item table_content "</li>"
            table_content = ""
            in_table = 0
            table_row_count = 0
            is_first_table_row = 1
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
    
    # 處理標題
    if ($0 ~ /^#{1,6} /) {
        flush_list_item()
        if (list_stack_depth > 0) {
            printf "%s", end_list(-1)
            list_stack_depth = 0
        }
        level = match($0, /#{1,6}/)
        title = substr($0, RLENGTH + 2)
        print "<h" RLENGTH ">" title "</h" RLENGTH ">"
        next
    }
    
    # 處理列表
    if (content ~ /^[0-9]+\. / || content ~ /^[-*] /) {
        is_numbered = (content ~ /^[0-9]+\. /)
        list_type = is_numbered ? "ol" : "ul"
        
        # 檢查是否需要結束之前的列表
        if (list_stack_depth > 0 && indent <= list_stack_indent[list_stack_depth - 1]) {
            printf "%s", end_list(indent)
        }
        
        # 開始新列表（如果需要）
        if (list_stack_depth == 0 || indent > list_stack_indent[list_stack_depth - 1]) {
            print start_list(list_type, indent)
        }
        
        # 處理列表項
        if (is_numbered) {
            sub(/^[0-9]+\. /, "", content)
        } else {
            sub(/^[-*] /, "", content)
        }
        
        flush_list_item()
        current_item = "<li>" content
    }
    # 處理表格行
    else if (content ~ /^\|/ && indent > base_indent) {
        process_table_row(content)
    }
    # 處理空行
    else if (content ~ /^[[:space:]]*$/) {
        flush_list_item()
        if (list_stack_depth > 0) {
            printf "%s", end_list(-1)
            list_stack_depth = 0
        }
    }
}

END {
    flush_list_item()
    if (list_stack_depth > 0) {
        printf "%s", end_list(-1)
    }
    print "</body>"
    print "</html>"
}
' "$INPUT_FILE" > "$OUTPUT_FILE"

echo "處理完成。輸出檔案為: $OUTPUT_FILE"