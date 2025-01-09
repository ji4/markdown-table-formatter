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
    in_summary = 0
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

function process_list_content() {
    if (in_list_item) {
        print list_item_content
        if (table_buffer != "") {
            print table_buffer
            table_buffer = ""
        }
        print "</li>"
        in_list_item = 0
    }
}

function close_lists_until(target_indent,    i) {
    for (i = list_stack_depth - 1; i >= 0; i--) {
        if (list_indent[i] >= target_indent) {
            process_list_content()
            printf "</%s>\n", list_container[i]
            list_stack_depth--
        } else {
            break
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
    # 檢查是否在總結部分的特殊處理
    if ($0 ~ /總結：選品策略三步驟/) {
        in_summary = 1
    }
    
    # 如果在總結部分，保持相同的縮排級別
    if (in_summary && list_marker == "ol") {
        indent = 0
    }
    
    # 如果縮排減少，關閉較深的列表
    if (indent < prev_indent) {
        close_lists_until(indent)
    }
    
    # 開始新列表或繼續現有列表
    if (list_stack_depth == 0 || indent > list_indent[list_stack_depth - 1]) {
        process_list_content()
        list_container[list_stack_depth] = list_marker
        list_indent[list_stack_depth] = indent
        printf "<%s>\n", list_marker
        list_stack_depth++
    } else if (indent == list_indent[list_stack_depth - 1] && 
               list_marker != list_container[list_stack_depth - 1]) {
        # 如果在同一層級但列表類型不同
        process_list_content()
        close_lists_until(indent)
        list_container[list_stack_depth] = list_marker
        list_indent[list_stack_depth] = indent
        printf "<%s>\n", list_marker
        list_stack_depth++
    }
    
    process_list_content()
    
    # 移除列表標記
    sub(/^[0-9]+\. |^[-*] /, "", content)
    printf "<li>"
    in_list_item = 1
    list_item_content = content
}

{
    indent = get_indent($0)
    content = $0
    gsub(/^[[:space:]]+/, "", content)
    
    # 處理標題
    if ($0 ~ /^#{1,6} /) {
        process_list_content()
        close_lists_until(0)
        in_summary = 0  # 重置總結標記
        level = match($0, /#{1,6}/)
        title = substr($0, RLENGTH + 2)
        print "<h" RLENGTH ">" title "</h" RLENGTH ">"
    }
    # 處理列表
    else if ((type_marker = detect_list_type(content)) != "") {
        handle_list(indent, content, type_marker)
    }
    # 處理表格
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
    # 處理空行
    else if (content ~ /^[[:space:]]*$/) {
        if (in_table) {
            table_buffer = table_buffer "</table>\n</div>\n"
            if (in_list_item) {
                list_item_content = list_item_content table_buffer
                table_buffer = ""
            } else {
                print table_buffer
            }
            in_table = 0
        }
    } else if (in_list_item) {
        # 處理列表項的額外內容
        list_item_content = list_item_content "\n" content
    }
    
    prev_indent = indent
}

END {
    process_list_content()
    close_lists_until(0)
    print "</body>"
    print "</html>"
}
' "$INPUT_FILE" > "$OUTPUT_FILE"

echo "處理完成。輸出檔案為: $OUTPUT_FILE"