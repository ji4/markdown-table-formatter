# 🚀 Homebrew 部署快速指南

## 快速部署步骤

### 1. 准备 GitHub 仓库
```bash
# 在 GitHub 创建两个仓库:
# 1. markdown-table-formatter (主仓库)
# 2. homebrew-tap (Homebrew tap 仓库)
```

### 2. 推送主仓库
```bash
git init
git add .
git commit -m "Initial release"
git remote add origin https://github.com/YOUR_USERNAME/markdown-table-formatter.git
git branch -M main
git push -u origin main

# 创建发布标签
git tag v1.0.0
git push origin v1.0.0
```

### 3. 获取 SHA256
```bash
curl -sL https://github.com/YOUR_USERNAME/markdown-table-formatter/archive/v1.0.0.tar.gz | shasum -a 256
```

### 4. 设置 Homebrew Tap
```bash
# 克隆或创建 tap 仓库
git clone https://github.com/YOUR_USERNAME/homebrew-tap.git
cd homebrew-tap

# 创建 Formula 目录
mkdir -p Formula

# 复制并编辑 formula 文件
cp ../mdtable.rb Formula/mdtable.rb

# 编辑 Formula/mdtable.rb，替换：
# - YOUR_USERNAME → 你的 GitHub 用户名
# - SHA256_HASH_HERE → 步骤3获取的 SHA256 值

# 推送 tap
git add .
git commit -m "Add mdtable formula"
git push origin main
```

### 5. 测试安装
```bash
# 本地测试
brew install --build-from-source ./Formula/mdtable.rb

# 测试命令
mdtable --help
mdtable --version
```

## 用户安装方式

```bash
# 添加你的 tap
brew tap YOUR_USERNAME/tap

# 安装 mdtable
brew install mdtable

# 使用
mdtable input.md
```

## 更新版本

当需要发布新版本时：

```bash
# 1. 更新代码并推送
git add .
git commit -m "Update to v1.0.1"
git push

# 2. 创建新标签
git tag v1.0.1
git push origin v1.0.1

# 3. 获取新的 SHA256
curl -sL https://github.com/YOUR_USERNAME/markdown-table-formatter/archive/v1.0.1.tar.gz | shasum -a 256

# 4. 更新 Formula/mdtable.rb 中的版本号和 SHA256

# 5. 推送 tap 更新
cd homebrew-tap
git add .
git commit -m "Update mdtable to v1.0.1"
git push
```

## 故障排除

### 常见问题

1. **SHA256 不匹配**
   - 重新获取 SHA256 hash
   - 确保 URL 和标签正确

2. **权限问题**
   - 检查脚本是否有执行权限
   - 确保 formula 中的 chmod 设置正确

3. **依赖问题**
   - 确保系统有 Perl 支持
   - 检查 Perl 模块依赖

### 验证安装

```bash
# 检查版本
mdtable --version

# 测试转换
echo "| A | B |\n|---|---|\n| 1 | 2 |" > test.md
mdtable test.md
ls test_html.html
```

## 🎉 恭喜！

你的工具现在可以通过 Homebrew 全球分发了！

用户只需要运行：
```bash
brew tap YOUR_USERNAME/tap
brew install mdtable
```

就可以在任何地方使用你的 `mdtable` 命令了。