# Homebrew Setup Instructions

This guide explains how to set up your own Homebrew tap for distributing mdtable.

## Step 1: Create GitHub Repositories

You need two repositories:

### 1. Main Repository (markdown-table-formatter)
```
https://github.com/YOUR_USERNAME/markdown-table-formatter
```
This contains your source code, scripts, and documentation.

### 2. Homebrew Tap Repository (homebrew-tap)
```
https://github.com/YOUR_USERNAME/homebrew-tap
```
This contains your Homebrew formulas.

## Step 2: Set Up Main Repository

1. Push your code to GitHub:
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/markdown-table-formatter.git
git branch -M main
git push -u origin main
```

2. Create a release tag:
```bash
git tag v1.0.0
git push origin v1.0.0
```

3. Generate SHA256 hash for the release:
```bash
curl -sL https://github.com/YOUR_USERNAME/markdown-table-formatter/archive/v1.0.0.tar.gz | shasum -a 256
```

## Step 3: Set Up Homebrew Tap

1. Create the tap repository:
```bash
mkdir homebrew-tap
cd homebrew-tap
git init
```

2. Create the formula directory:
```bash
mkdir Formula
```

3. Copy the formula file:
```bash
cp ../mdtable.rb Formula/mdtable.rb
```

4. Update the formula with your actual values:
   - Replace `YOUR_USERNAME` with your GitHub username
   - Replace `SHA256_HASH_HERE` with the actual SHA256 hash
   - Update the homepage URL

5. Push to GitHub:
```bash
git add .
git commit -m "Add mdtable formula"
git remote add origin https://github.com/YOUR_USERNAME/homebrew-tap.git
git branch -M main
git push -u origin main
```

## Step 4: Update Formula Template

Update `Formula/mdtable.rb` with these values:

```ruby
class Mdtable < Formula
  desc "Convert Markdown tables to HTML with support for nested lists"
  homepage "https://github.com/YOUR_USERNAME/markdown-table-formatter"
  url "https://github.com/YOUR_USERNAME/markdown-table-formatter/archive/v1.0.0.tar.gz"
  sha256 "ACTUAL_SHA256_HASH"
  license "MIT"
  
  depends_on "perl"
  
  def install
    bin.install "markdown-table-formatter.sh" => "mdtable"
    chmod 0755, bin/"mdtable"
  end
  
  test do
    (testpath/"test.md").write <<~EOS
      | Header 1 | Header 2 |
      |----------|----------|
      | Cell 1   | Cell 2   |
    EOS
    
    system "#{bin}/mdtable", "test.md"
    assert_predicate testpath/"test_html.html", :exist?
    
    output = (testpath/"test_html.html").read
    assert_match "<table>", output
    assert_match "Cell 1", output
  end
end
```

## Step 5: Test Installation

Test your formula locally:
```bash
brew install --build-from-source ./Formula/mdtable.rb
```

## Step 6: User Installation

Users can now install your tool with:
```bash
brew tap YOUR_USERNAME/tap
brew install mdtable
```

## Updating the Formula

When you release a new version:

1. Create a new release tag:
```bash
git tag v1.0.1
git push origin v1.0.1
```

2. Update the formula:
   - Change the version in the URL
   - Update the SHA256 hash
   - Push changes to the tap repository

## Notes

- Replace `YOUR_USERNAME` with your actual GitHub username
- The tap repository name must be `homebrew-tap`
- Formula files must be in the `Formula/` directory
- Formula names should match the file name (minus .rb extension)