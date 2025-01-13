#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

# 設定檔案名稱
my $input_file = "table.md";
my $output_file = $input_file;
$output_file =~ s/\.md$/_html.html/;

# 檢查輸入檔案是否存在
unless (-f $input_file) {
    die "錯誤: 找不到輸入檔案 '$input_file'\n";
}

# 初始化變數
my $in_table = 0;
my $table_buffer = "";
my $prev_indent = -1;
my $list_item_content = "";
my $in_list_item = 0;
my @list_stack = ();
my %processed_tables;

# 打開檔案
open(my $in_fh, '<:utf8', $input_file) or die "無法開啟輸入檔案: $!";
open(my $out_fh, '>:utf8', $output_file) or die "無法開啟輸出檔案: $!";

# 輸出 HTML 頭部
print $out_fh <<'HTML_HEAD';
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
table { border-collapse: collapse; width: 100%; margin: 20px 0; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background-color: #f2f2f2; }
ul, ol { margin: 0 0 1em 0; padding-left: 20px; }
li { margin: 5px 0; }
li > ul, li > ol { margin: 5px 0; }
.nested-content { margin-left: 20px; }
.table-container { margin: 1em 0; clear: both; }
h1 { font-size: 2em; margin: 0.67em 0; }
h2 { font-size: 1.5em; margin: 0.75em 0; }
h3 { font-size: 1.17em; margin: 0.83em 0; }
h4 { font-size: 1em; margin: 1.12em 0; }
h5 { font-size: .83em; margin: 1.5em 0; }
h6 { font-size: .75em; margin: 1.67em 0; }
</style>
</head>
<body>
HTML_HEAD

sub close_lists_until {
    my ($target_indent) = @_;
    while (@list_stack && $list_stack[-1]->{indent} >= $target_indent) {
        my $last = pop @list_stack;
        print $out_fh "</li>\n" if $in_list_item;
        print $out_fh "</$last->{type}>\n";
        $in_list_item = 0;
    }
}

sub process_cell_content {
    my ($cell) = @_;
    
    # 移除開頭的空白
    $cell =~ s/^\s+//;
    
    # 檢查是否包含列表項目
    if ($cell =~ /[•]/ || $cell =~ /^-/) {
        my @items = split(/[•]|-/, $cell);
        my $result = "<ul>\n";
        foreach my $item (@items) {
            # 移除項目開頭和結尾的空白
            $item =~ s/^\s+|\s+$//g;
            if ($item ne '') {
                $result .= "    <li>$item</li>\n";
            }
        }
        $result .= "</ul>";
        return $result;
    }
    
    # 如果文本包含 <br>• 或 <br>-，轉換為列表
    if ($cell =~ /<br>[•-]/) {
        my @items = split(/<br>[•-]\s*/, $cell);
        my $result = "<ul>\n";
        foreach my $item (@items) {
            $item =~ s/^\s+|\s+$//g;
            if ($item ne '') {
                $result .= "    <li>$item</li>\n";
            }
        }
        $result .= "</ul>";
        return $result;
    }
    
    return $cell;
}

sub process_table {
    my @rows = @_;
    my $table_html = "<div class=\"table-container\">\n<table>\n";
    
    foreach my $row (@rows) {
        next if $row =~ /^\s*$/;  # 跳過空行
        next if $row =~ /^[|\s:-]+$/;  # 跳過分隔線
        
        $row =~ s/^\s*\|\s*|\s*\|\s*$//g;  # 移除首尾的 |
        my @cells = split /\s*\|\s*/, $row;
        
        $table_html .= "<tr>\n";
        foreach my $cell (@cells) {
            $cell =~ s/^\s+|\s+$//g;  # 移除首尾空白
            my $cell_content = process_cell_content($cell);
            $table_html .= "  <td>$cell_content</td>\n";
        }
        $table_html .= "</tr>\n";
    }
    $table_html .= "</table>\n</div>\n";
    return $table_html;
}

sub get_indent {
    my ($line) = @_;
    return 0 unless $line =~ /\S/;
    $line =~ /^(\s*)/;
    return length($1);
}

# 讀取整個文件到內存
my @lines = <$in_fh>;
chomp @lines;

# 移除介紹性文本
@lines = grep { 
    !/^我會幫您將文字完整整理/ &&
    !/^第一部分/ &&
    !/^好的，我將繼續整理/ &&
    !/^這樣已經完整整理/ &&
    !/^需要我/ 
} @lines;

my $i = 0;
while ($i < @lines) {
    my $line = $lines[$i];
    my $indent = get_indent($line);
    my $content = $line;
    $content =~ s/^\s+//;
    
    # 處理標題
    if ($line =~ /^(#{1,6})\s+(.+)/) {
        my $level = length($1);
        my $title = $2;
        close_lists_until(0) if @list_stack;
        print $out_fh "<h$level>$title</h$level>\n";
    }
    # 檢測表格開始
    elsif ($line =~ /^\s*\|/) {
        my @table_lines;
        my $j = $i;
        
        # 收集表格所有行
        while ($j < @lines && ($lines[$j] =~ /^\s*\|/ || $lines[$j] =~ /^\s*$/)) {
            push @table_lines, $lines[$j] unless $lines[$j] =~ /^\s*$/;
            $j++;
        }
        
        # 輸出表格
        print $out_fh process_table(@table_lines);
        
        $i = $j - 1;
    }
    # 處理列表
    elsif ($line =~ /^(\s*)((?:[0-9]+\.)|[-*])\s+(.+)/) {
        my ($spaces, $marker, $text) = ($1, $2, $3);
        my $list_type = $marker =~ /[0-9]+\./ ? 'ol' : 'ul';
        my $this_indent = length($spaces);
        
        if (!@list_stack || $this_indent > $list_stack[-1]->{indent}) {
            push @list_stack, {
                type => $list_type,
                indent => $this_indent
            };
            print $out_fh "<$list_type>\n";
        } elsif ($this_indent < $list_stack[-1]->{indent}) {
            while (@list_stack && $this_indent < $list_stack[-1]->{indent}) {
                my $last = pop @list_stack;
                print $out_fh "</li>\n" if $in_list_item;
                print $out_fh "</$last->{type}>\n";
                $in_list_item = 0;
            }
            if (@list_stack && $this_indent == $list_stack[-1]->{indent}) {
                print $out_fh "</li>\n" if $in_list_item;
            }
        } elsif ($this_indent == $list_stack[-1]->{indent}) {
            print $out_fh "</li>\n" if $in_list_item;
        }
        
        print $out_fh "<li>$text";
        $in_list_item = 1;
    }
    # 處理一般文本
    else {
        if ($in_list_item) {
            print $out_fh " $content";
        } else {
            print $out_fh "$content\n";
        }
    }
    
    $i++;
}

# 關閉所有開啟的列表
while (@list_stack) {
    my $last = pop @list_stack;
    print $out_fh "</li>\n" if $in_list_item;
    print $out_fh "</$last->{type}>\n";
    $in_list_item = 0;
}

# 輸出 HTML 尾部
print $out_fh "</body>\n</html>\n";

# 關閉檔案
close $in_fh;
close $out_fh;

print "處理完成。輸出檔案為: $output_file\n";