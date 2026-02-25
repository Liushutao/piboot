# PiBoot 🥧

> 让 Raspberry Pi 5 部署像搭积木一样简单

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Raspberry%20Pi%205-red.svg)](https://www.raspberrypi.com/products/raspberry-pi-5/)
[![Language](https://img.shields.io/badge/language-Bash-green.svg)]()

[English](README_EN.md) | 简体中文

---

## ✨ 特性

- 🚀 **一键部署** - 一条命令，10分钟完成系统配置
- 🐳 **Docker 优先** - 所有服务使用 Docker 部署，干净可迁移
- 🇨🇳 **国内优化** - 自动更换镜像源，告别下载慢
- 🎛️ **模块化设计** - 按需安装，自由选择
- 📝 **中文界面** - 交互式操作，无需懂 Linux
- 🔒 **安全可靠** - 自动配置 SSH 密钥，禁用密码登录

---

## 🎯 适合谁用

- 🏠 **智能家居玩家** - 一键部署 Home Assistant
- 🎬 **影音爱好者** - 快速搭建 Plex/Jellyfin 私人影院
- 💾 **NAS 用户** - 配置 Samba 文件共享
- 👨‍💻 **开发者** - 秒搭 Docker/Python/Node 开发环境
- 🤖 **创客小白** - 不会 Linux 也能玩转 Pi5

---

## 🚀 快速开始

### 方式一：一行命令安装（推荐）

```bash
curl -fsSL https://get.piboot.io | bash
```

### 方式二：手动下载安装

```bash
# 下载最新版本
git clone https://github.com/yourusername/piboot.git
cd piboot

# 运行安装
chmod +x install.sh
sudo ./install.sh
```

---

## 📦 支持的服务

### 系统与工具
- ✅ 系统更新 & 中文环境
- ✅ 国内镜像源（清华/中科大/阿里云）
- ✅ Docker & Docker Compose
- ✅ SSH 密钥登录配置

### 智能家居
- 🏠 Home Assistant
- 🔌 ESPHome
- 🌊 Node-RED
- 📡 MQTT Broker (Mosquitto)

### 媒体中心
- 🎬 Plex Media Server
- 🎥 Jellyfin
- ⬇️ qbittorrent
- 📁 Samba 文件共享

### 网络工具
- 🛡️ Pi-hole（去广告）
- 🚫 AdGuard Home
- 🔒 OpenVPN / WireGuard
- 🌐 Frp 内网穿透

### 开发与监控
- 🐍 Python 3 + pip
- 📦 Node.js + npm
- 💻 VS Code Server (code-server)
- 📊 Grafana + Prometheus
- 🐳 Portainer (Docker 管理)

---

## 🖥️ 使用截图

![主菜单](docs/images/menu.png)
*交互式主菜单，清晰易懂*

![安装进度](docs/images/progress.png)
*实时显示安装进度*

---

## 📖 详细文档

- [快速开始指南](docs/quickstart.md)
- [功能列表](docs/features.md)
- [常见问题](docs/faq.md)
- [开发文档](docs/development.md)

---

## 💰 专业版

社区版免费开源，包含基础功能。

**专业版**（¥29）额外包含：
- 全部 20+ 服务一键安装
- 高级系统优化选项
- Web 管理界面
- 优先技术支持
- 永久免费更新

👉 [购买专业版](https://your-store-link.com)

---

## 🤝 参与贡献

欢迎提交 Issue 和 Pull Request！

```bash
#  Fork 本仓库
#  创建你的分支
git checkout -b feature/AmazingFeature

#  提交更改
git commit -m 'Add some AmazingFeature'

#  推送到分支
git push origin feature/AmazingFeature

#  创建 Pull Request
```

详细贡献指南请查看 [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 📜 许可证

本项目采用 [MIT](LICENSE) 许可证开源。

---

## 🙏 致谢

感谢以下开源项目：
- [Home Assistant](https://www.home-assistant.io/)
- [Docker](https://www.docker.com/)
- [Raspberry Pi](https://www.raspberrypi.org/)

---

## 📮 联系我们

- 💬 微信：your-wechat-id
- 📧 邮箱：your-email@example.com
- 💼 Telegram：@your_telegram

---

<p align="center">Made with ❤️ for Raspberry Pi community</p>
