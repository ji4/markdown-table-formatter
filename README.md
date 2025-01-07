# Markdown Table to HTML Converter

A command-line tool that converts Markdown tables and lists to HTML, with special handling for nested lists within table cells.

## Features

- Converts Markdown tables to HTML tables
- Supports nested lists within table cells (using • or - symbols)
- Preserves plain text formatting
- Supports basic Markdown formatting (headers, bold, italic)
- Generates appropriate CSS styling
- UTF-8 support for international characters

## System Requirements

- Unix-like operating system (Linux, macOS)
- Bash shell
- AWK

## Installation

1. Clone the repository:
```bash
git clone [repository-url]
cd [repository-name]
```

2. Make the script executable:
```bash
chmod +x md_to_html.sh
```

## Usage

1. Prepare your Markdown file (default name: `table.md`)

2. Run the script:
```bash
./md_to_html.sh
```

3. Check the output file (default: `table_html.html`)

### Input File Format Example

```markdown
## 1. Project Overview
| Section | Content |
|---------|---------|
| Project Title | Cloud Migration Strategy and Implementation Plan |
| Key Deliverables | • Infrastructure Assessment Report<br>• Migration Timeline<br>• Cost Analysis Document |

## 2. Implementation Phases
| Phase | Details |
|-------|---------|
| Phase 1 | Initial Assessment and Planning |
| Action Items | • Inventory current infrastructure<br>• Identify dependencies<br>• Define success metrics |
```

### Supported Markdown Syntax

- Tables (using `|` separators)
- Lists (using `•` or `-` symbols)
- Headers (from `#` to `######`)
- Bold text (`**text**`)
- Italic text (`*text*`)
- Inline code (```text```)

## Output Styling

The script automatically generates HTML with the following styles:
- Table styling (borders, padding, alignment)
- List styling (indentation, bullets)
- Header styling (sizes, margins)
- Text formatting (bold, italic, code)

## Configuration

To modify default settings, edit the variables at the beginning of the script:
```bash
INPUT_FILE="table.md"        # Input filename
OUTPUT_FILE="${INPUT_FILE%.*}_html.html"  # Output filename
```

## Important Notes

1. Ensure input files use UTF-8 encoding
2. List items within table cells must be separated with `<br>`
3. Both `•` and `-` are supported as list markers
4. Empty cells are preserved in the output


## Known Limitations

- Does not support nested tables
- Limited support for complex Markdown formatting within table cells
- Tables must have consistent column counts
