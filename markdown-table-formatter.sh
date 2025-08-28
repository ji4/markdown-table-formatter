#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use Encode qw(decode encode);
use Getopt::Long;
use Pod::Usage;

# Set UTF-8 encoding for all I/O
binmode(STDIN, ':encoding(UTF-8)');
binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

# Version information
my $VERSION = '1.0.4';

# Command line parameters
my $input_file;
my $output_file;
my $help = 0;
my $version = 0;

# Parse command line arguments
GetOptions(
    'input|i=s'   => \$input_file,
    'output|o=s'  => \$output_file,
    'help|h'      => \$help,
    'version|v'   => \$version,
) or pod2usage(2);

# Show help information
if ($help) {
    print <<'HELP';
mdtable - Markdown table to HTML converter

USAGE:
    mdtable [OPTIONS] <input.md>
    mdtable [OPTIONS] --input <input.md> --output <output.html>

ARGUMENTS:
    <input.md>    Input Markdown file (default: table.md)

OPTIONS:
    -i, --input <FILE>     Input Markdown file
    -o, --output <FILE>    Output HTML file (default: <input>.html)
    -h, --help             Show this help message
    -v, --version          Show version information

EXAMPLES:
    mdtable table.md                          # Convert table.md to table.html
    mdtable -i input.md -o output.html        # Specify both input and output
    mdtable --input data.md                   # Use long option names

HELP
    exit 0;
}

# Show version information
if ($version) {
    print "mdtable version $VERSION\n";
    exit 0;
}

# Determine input file
if (@ARGV && !$input_file) {
    $input_file = $ARGV[0];
} elsif (!$input_file) {
    $input_file = "table.md";
}

# Determine output file
if (!$output_file) {
    $output_file = $input_file;
    $output_file =~ s/\.md$/.html/;
    $output_file =~ s/\.txt$/.html/;
}

# Check if input file exists
unless (-f $input_file) {
    die "Error: Input file '$input_file' not found\nTry 'mdtable --help' for more information.\n";
}

# Initialize variables
my $in_table = 0;
my $table_buffer = "";
my $prev_indent = -1;
my $list_item_content = "";
my $in_list_item = 0;
my @list_stack = ();
my %processed_tables;

# Open files
open(my $in_fh, '<:utf8', $input_file) or die "Cannot open input file: $!";
open(my $out_fh, '>:utf8', $output_file) or die "Cannot open output file: $!";

# Output HTML header
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
hr { border: none; border-top: 1px solid #ccc; margin: 1em 0; }
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

# Function to process bold text - convert **text** to <strong>text</strong>
sub process_bold_text {
    my ($text) = @_;
    $text =~ s/\*\*([^*]+)\*\*/<strong>$1<\/strong>/g;
    return $text;
}

sub process_cell_content {
    my ($cell) = @_;
    
    # Remove leading whitespace
    $cell =~ s/^\s+//;
    
    # Process bold text
    $cell = process_bold_text($cell);
    
    # Check if contains list items
    if ($cell =~ /[•]/ || $cell =~ /^-/) {
        my @items = split(/[•]|-/, $cell);
        my $result = "<ul>\n";
        foreach my $item (@items) {
            # Remove leading and trailing whitespace from item
            $item =~ s/^\s+|\s+$//g;
            if ($item ne '') {
                $result .= "    <li>$item</li>\n";
            }
        }
        $result .= "</ul>";
        return $result;
    }
    
    # If text contains <br>• or <br>-, convert to list
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
        next if $row =~ /^\s*$/;  # Skip empty lines
        next if $row =~ /^\s*\|?[\s:-|]+\|?\s*$/;  # Skip separator lines
        
        $row =~ s/^\s*\|\s*|\s*\|\s*$//g;  # Remove leading and trailing |
        my @cells = split /\s*\|\s*/, $row;
        
        $table_html .= "<tr>\n";
        foreach my $cell (@cells) {
            $cell =~ s/^\s+|\s+$//g;  # Remove leading and trailing whitespace
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

# Read entire file into memory
my @lines = <$in_fh>;
chomp @lines;

# Remove introductory text
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
    
    # Process headers
    if ($line =~ /^(#{1,6})\s+(.+)/) {
        my $level = length($1);
        my $title = $2;
        # Process bold text in headers
        $title = process_bold_text($title);
        close_lists_until(0) if @list_stack;
        print $out_fh "<h$level>$title</h$level>\n";
    }
    # Convert horizontal rules (--- or ***) to HTML hr tag
    elsif ($line =~ /^\s*[-*]{3,}\s*$/) {
        close_lists_until(0) if @list_stack;
        print $out_fh "<hr>\n";
    }
    # Detect table start
    elsif ($line =~ /^\s*\|/) {
        my @table_lines;
        my $j = $i;
        
        # Collect all table rows
        while ($j < @lines && ($lines[$j] =~ /^\s*\|/ || $lines[$j] =~ /^\s*$/)) {
            push @table_lines, $lines[$j] unless $lines[$j] =~ /^\s*$/;
            $j++;
        }
        
        # Output table
        print $out_fh process_table(@table_lines);
        
        $i = $j - 1;
    }
    # Process lists
    elsif ($line =~ /^(\s*)((?:[0-9]+\.)|[-*])\s+(.+)/) {
        my ($spaces, $marker, $text) = ($1, $2, $3);
        # Process bold text in list items
        $text = process_bold_text($text);
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
    # Process general text
    else {
        # Process bold text in general text
        $content = process_bold_text($content);
        if ($in_list_item) {
            print $out_fh " $content";
        } else {
            print $out_fh "$content\n";
        }
    }
    
    $i++;
}

# Close all open lists
while (@list_stack) {
    my $last = pop @list_stack;
    print $out_fh "</li>\n" if $in_list_item;
    print $out_fh "</$last->{type}>\n";
    $in_list_item = 0;
}

# Output HTML footer
print $out_fh "</body>\n</html>\n";

# Close files
close $in_fh;
close $out_fh;

# Handle UTF-8 output properly - decode filename if needed
my $display_input = $input_file;
my $display_output = $output_file;

# Try to ensure proper encoding for display
eval {
    $display_input = decode('UTF-8', $input_file) if !utf8::is_utf8($input_file);
    $display_output = decode('UTF-8', $output_file) if !utf8::is_utf8($output_file);
};

print "✅ Conversion completed successfully!\n";
print "Input: $display_input\n";
print "Output: $display_output\n";