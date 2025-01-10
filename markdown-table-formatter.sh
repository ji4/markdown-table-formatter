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
    processed_tables = ""  # 新增：用於追蹤已處理的表格
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
    # 檢查是否為重複表格
    return (index(processed_tables, table_content) > 0)
}

function add_to_processed_tables(table_content) {
    # 將表格內容加入已處理清單
    processed_tables = processed_tables "\n" table_content
}

function process_list_content() {
    if (in_list_item) {
        if (list_item_content != "") {
            print list_item_content
        }
        if (table_buffer != "" && !is_duplicate_table(table_buffer)) {
            print table_buffer
            add_to_processed_tables(table_buffer)
        }
        table_buffer = ""
        print "</li>"
        in_list_item = 0
        list_item_content = ""
    }
}

function close_lists_until(target_indent,    i) {
    for (i = list_stack_depth - 1; i >= 0; i--) {
        if (list_indent[i] >= target_indent) {
            process_list_content()
            printf "</%s>\n", list_container[i]
            list_stack_depth--
        }
    }
}

function detect_list_type(content) {
    if (content ~ /^[0-9]+\./) {
        return "ol"
    } else if (content ~ /^[-*]/) {
        return "ul"
    }
    return ""
}

function handle_list(indent, content, list_marker) {
    if (indent < prev_indent) {
        close_lists_until(indent)
    }
    
    if (list_stack_depth == 0 || indent > list_indent[list_stack_depth - 1]) {
        process_list_content()
        list_container[list_stack_depth] = list_marker
        list_indent[list_stack_depth] = indent
        printf "<%s>\n", list_marker
        list_stack_depth++
    }
    
    process_list_content()
    
    sub(/^[0-9]+\. |^[-*] /, "", content)
    printf "<li>"
    in_list_item = 1
    list_item_content = content
}

{
    indent = get_indent($0)
    content = $0
    gsub(/^[[:space:]]+/, "", content)
    
    if ($0 ~ /^#{1,6} /) {
        process_list_content()
        close_lists_until(0)
        level = match($0, /#{1,6}/)
        title = substr($0, RLENGTH + 2)
        print "<h" RLENGTH ">" title "</h" RLENGTH ">"
    }
    else if ((type_marker = detect_list_type(content)) != "") {
        handle_list(indent, content, type_marker)
    }
    else if (content ~ /^\|/) {
        if (!in_table) {
            table_buffer = table_buffer "<div class=\"table-container\">\n<table>\n"
            in_table = 1
        }
        
        if (!(content ~ /^[\| :-]+$/)) {
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
    else if (content ~ /^[[:space:]]*$/) {
        if (in_table) {
            table_buffer = table_buffer "</table>\n</div>\n"
            if (!is_duplicate_table(table_buffer)) {
                if (in_list_item) {
                    list_item_content = list_item_content "\n" table_buffer
                } else {
                    print table_buffer
                    add_to_processed_tables(table_buffer)
                }
            }
            table_buffer = ""
            in_table = 0
        }
    }
    else if (in_list_item) {
        list_item_content = list_item_content "\n" content
    }
    
    prev_indent = indent
}

END {
    process_list_content()
    close_lists_until(0)
    if (in_table) {
        table_buffer = table_buffer "</table>\n</div>\n"
        if (!is_duplicate_table(table_buffer)) {
            print table_buffer
        }
    }
    print "</body>"
    print "</html>"
}
' "$INPUT_FILE" > "$OUTPUT_FILE"

echo "處理完成。輸出檔案為: $OUTPUT_FILE"