#!/bin/bash
# 一键上传 PiBoot 到 GitHub
# 使用方法: bash upload_to_github.sh

set -e

echo "========================================"
echo "  PiBoot GitHub 上传助手"
echo "========================================"
echo ""

# 检查是否在正确的目录
if [[ ! -f "install.sh" ]]; then
    echo "错误: 请在 piboot 目录下运行此脚本"
    exit 1
fi

# 配置 Git（如果还没配置）
if ! git config user.name &>/dev/null; then
    git config user.name "韩信"
    git config user.email "hanxin@piboot.io"
fi

# 确保仓库已初始化
if [[ ! -d ".git" ]]; then
    echo "[*] 初始化 Git 仓库..."
    git init
fi

# 添加所有文件
echo "[*] 添加文件到 Git..."
git add .

# 提交
echo "[*] 提交更改..."
git commit -m "Initial commit: PiBoot MVP - One-click RPi5 deployment tool" || echo "已是最新提交"

# 添加远程仓库（如果还没添加）
if ! git remote | grep -q "origin"; then
    echo "[*] 添加远程仓库..."
    git remote add origin https://github.com/liushutao/piboot.git
fi

# 推送
echo "[*] 推送到 GitHub..."
echo "    可能需要输入 GitHub 用户名和密码/Token"
echo ""

# 尝试推送
if git push -u origin master; then
    echo ""
    echo "========================================"
    echo "  ✅ 上传成功！"
    echo "========================================"
    echo ""
    echo "  仓库地址: https://github.com/liushutao/piboot"
    echo ""
else
    echo ""
    echo "[!] 推送失败，尝试备用方法..."
    echo ""
    echo "请手动运行以下命令："
    echo ""
    echo "  git remote add origin https://github.com/liushutao/piboot.git"
    echo "  git push -u origin master"
    echo ""
    echo "如果提示输入密码，请输入你的 GitHub Token"
fi
