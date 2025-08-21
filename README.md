# mdtable - Markdown Table to HTML Converter

A command-line tool that converts Markdown tables and lists to HTML, with special handling for nested lists within table cells.

## ✨ Key Features

- 🔄 **Smart Table Conversion**: Converts Markdown tables to properly formatted HTML
- 📋 **Nested Lists Support**: Handles bullet points within table cells (`•` or `-` symbols)
- 🎨 **Text Formatting**: Preserves **bold**, *italic*, and other Markdown formatting
- 📑 **Headers Support**: Converts headers (H1-H6) with proper styling
- 💅 **Built-in CSS**: Generates responsive, professional-looking HTML with embedded styles
- 🌍 **UTF-8 Support**: Full international character support
- ⚡ **Command-line Ready**: Flexible CLI with help, version, and custom output options

## 🎯 What Makes It Special

This tool solves the common problem of **complex table cells** containing lists. While most Markdown processors struggle with nested content in tables, `mdtable` intelligently converts:

```
| Task Category | Action Items |
|---------------|--------------|
| Planning | • Research market<br>• Define goals<br>• Set timeline |
```

Into properly structured HTML with actual `<ul>` and `<li>` elements, not just text with bullet symbols.

## Installation

### Homebrew (Recommended)

```bash
# Add the tap
brew tap ji4/tap

# Install mdtable
brew install mdtable
```

### Manual Installation

```bash
# Download and install
curl -o mdtable https://raw.githubusercontent.com/ji4/markdown-table-formatter/main/markdown-table-formatter.sh
chmod +x mdtable
sudo mv mdtable /usr/local/bin/
```

### From Source

```bash
git clone https://github.com/ji4/markdown-table-formatter.git
cd markdown-table-formatter
chmod +x markdown-table-formatter.sh
sudo cp markdown-table-formatter.sh /usr/local/bin/mdtable
```

## Usage

```bash
# Basic usage
mdtable input.md

# Specify output file
mdtable input.md -o output.html

# Using long options
mdtable --input data.md --output result.html

# Show help
mdtable --help

# Show version
mdtable --version
```

## 🚀 Quick Start

1. **Install via Homebrew**:
   ```bash
   brew tap ji4/tap
   brew install mdtable
   ```

2. **Create a Markdown file** (`example.md`):
   ```markdown
   # My Project Plan
   
   | Phase | Tasks |
   |-------|-------|
   | **Planning** | • Research competitors<br>• Define requirements<br>• Create mockups |
   | **Development** | • Set up environment<br>• Build core features |
   ```
   
   > **Key**: Use `<br>` between list items in table cells - the tool converts these to proper HTML lists!

3. **Convert to HTML**:
   ```bash
   mdtable example.md
   # Creates: example_html.html
   ```

4. **Open in browser** to see the professionally styled result! 🎉

## 📝 Before & After Examples

> **Note**: In the input examples, you write `<br>` to create line breaks between list items in table cells. The tool automatically converts these to proper HTML `<ul><li>` structure.

### Example 1: Simple Table

| **Input (Markdown)** | **Output (HTML)** |
|---------------------|-------------------|
| ```markdown<br>\| Product \| **Price** \|<br>\|---------|----------\|<br>\| iPhone  \| $999     \|<br>\| MacBook \| $1299    \|<br>``` | ```html<br><table><br>  <tr><br>    <td>Product</td><br>    <td><strong>Price</strong></td><br>  </tr><br>  <tr><br>    <td>iPhone</td><br>    <td>$999</td><br>  </tr><br>  <tr><br>    <td>MacBook</td><br>    <td>$1299</td><br>  </tr><br></table><br>``` |

### Example 2: Table with Nested Lists ⭐ (Key Feature)

| **Input (Markdown)** | **Output (HTML)** |
|---------------------|-------------------|
| ```markdown<br>\| Project Phase \| Tasks \|<br>\|---------\|----------\|<br>\| Planning \| • Research competitors<br>• Define requirements<br>• Create timeline \|<br>\| Development \| • Build MVP<br>• Test functionality \|<br>``` | ```html<br><table><br>  <tr><br>    <td>Planning</td><br>    <td><br>      <ul><br>        <li>Research competitors</li><br>        <li>Define requirements</li><br>        <li>Create timeline</li><br>      </ul><br>    </td><br>  </tr><br>  <tr><br>    <td>Development</td><br>    <td><br>      <ul><br>        <li>Build MVP</li><br>        <li>Test functionality</li><br>      </ul><br>    </td><br>  </tr><br></table><br>``` |

### Example 3: Complete Document with Headers

| **Input (Markdown)** | **Output (HTML)** |
|---------------------|-------------------|
| ```markdown<br># Project Overview<br><br>\| Section \| Content \|<br>\|---------\|---------\|<br>\| **Title** \| Web App Development \|<br>\| Features \| • User authentication<br>• Data visualization<br>• Real-time updates \|<br>``` | ```html<br><h1>Project Overview</h1><br><br><table><br>  <tr><br>    <td><strong>Title</strong></td><br>    <td>Web App Development</td><br>  </tr><br>  <tr><br>    <td>Features</td><br>    <td><br>      <ul><br>        <li>User authentication</li><br>        <li>Data visualization</li><br>        <li>Real-time updates</li><br>      </ul><br>    </td><br>  </tr><br></table><br>``` |

## 🎨 Visual Output Preview

The generated HTML creates professional-looking tables with proper styling:

### Input → Output Comparison

| **Before (Markdown Source)** | **After (Rendered HTML)** |
|------------------------------|---------------------------|
| Raw text with `<br>` breaks and `•` symbols | ✅ Properly structured HTML lists |
| No visual formatting | ✅ Professional table styling with borders |
| Limited text styling | ✅ Rich formatting (bold, italic, headers) |

### What You Get

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    table { border-collapse: collapse; width: 100%; margin: 20px 0; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #f2f2f2; }
    ul, ol { margin: 0 0 1em 0; padding-left: 20px; }
    /* ... more professional styling ... */
  </style>
</head>
<body>
  <!-- Your converted content here -->
</body>
</html>
```

### Supported Markdown Syntax

| Syntax | Example | Output |
|--------|---------|--------|
| **Tables** | `\| Col1 \| Col2 \|` | HTML `<table>` with borders |
| **Lists** | `• Item 1<br>• Item 2` | Proper `<ul><li>` structure |
| **Headers** | `# Title` → `### Subtitle` | `<h1>` → `<h3>` tags |
| **Bold Text** | `**important**` | `<strong>important</strong>` |
| **Nested Content** | Lists inside table cells | Structured HTML with proper nesting |

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
