#!/bin/bash
# commit.sh - 自动定位根目录的一键推送脚本

# 1. 自动切换到脚本所在的目录 (也就是项目根目录)
cd "$(dirname "$0")"

# 2. 检查 git 是否已初始化
if [ ! -d ".git" ]; then
    echo "❌ 错误：当前目录不是一个 git 仓库。"
    exit 1
fi

# 3. 设置提交信息
MESSAGE=${1:-"fix: 自动提交更新"}

echo "🚀 正在从 $(pwd) 提交代码..."

# git pull --rebase origin main

# 4. 执行 Git 操作
git add .
git commit -m "$MESSAGE"
git push origin main


if [ $? -eq 0 ]; then
    echo "✅ 提交并推送成功！"
else
    echo "❌ 提交失败，请检查网络或 SSH 权限。"
fi