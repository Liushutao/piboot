#!/bin/bash
# lib/ui.sh - PiBoot 用户界面库
# 提供交互式菜单、对话框、进度显示等功能

# ============================================
# 引入核心库
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/core.sh"

# ============================================
# 界面配置
# ============================================

# 是否使用图形界面（whiptail/dialog）
USE_TUI=${USE_TUI:-true}

# 终端尺寸
TERM_ROWS=${LINES:-24}
TERM_COLS=${COLUMNS:-80}

# ============================================
# 界面检测
# ============================================

# 检测可用的 TUI 工具
detect_tui_tool() {
    if cmd_exists whiptail; then
        echo "whiptail"
        return 0
    elif cmd_exists dialog; then
        echo "dialog"
        return 0
    fi
    echo "none"
    return 1
}

# 检查是否支持 TUI
supports_tui() {
    [[ -t 0 ]] && [[ "$USE_TUI" == "true" ]] && detect_tui_tool >/dev/null
}

# ============================================
# 清屏和显示控制
# ============================================

# 清屏
clear_screen() {
    clear
}

# 保存光标位置
save_cursor() {
    echo -en "\033[s"
}

# 恢复光标位置
restore_cursor() {
    echo -en "\033[u"
}

# 隐藏光标
hide_cursor() {
    echo -en "\033[?25l"
}

# 显示光标
show_cursor() {
    echo -en "\033[?25h"
}

# ============================================
# Banner 和标题
# ============================================

# 显示 PiBoot Banner
show_banner() {
    clear_screen
    echo -e "${COLOR_BLUE}"
    show_separator "=" 60
    echo "        ___  ____  ____   ____   _____ _____ ____  "
    echo "       / _ \\|  _ \\| __ ) / __ \\ / ____|_   _|  _ \\ "
    echo "      | | | | |_) |  _ \\| |  | | (___   | | | |_) |"
    echo "      | |_| |  __/| |_) | |__| |\\___ \\  | | |  _ < "
    echo "       \\___/|_|   |____/ \\____/|_____/ |___||_| \\_\\"
    echo ""
    echo "        Raspberry Pi 5 一键部署工具"
    echo "        版本: ${PIBOOT_VERSION}"
    show_separator "=" 60
    echo -e "${COLOR_NC}"
    echo ""
}

# 显示小标题
show_section() {
    local title="$1"
    echo ""
    echo -e "${COLOR_CYAN}▶ ${title}${COLOR_NC}"
    show_separator "-" 40
}

# 显示子标题
show_subsection() {
    local title="$1"
    echo -e "${COLOR_YELLOW}  › ${title}${COLOR_NC}"
}

# ============================================
# 主菜单
# ============================================

# 显示主菜单（TUI 模式）
show_main_menu_tui() {
    local tui_tool
    tui_tool=$(detect_tui_tool)
    
    local title="PiBoot - RPi5 一键部署工具"
    local text="请选择要执行的操作："
    
    if [[ "$tui_tool" == "whiptail" ]]; then
        whiptail --title "$title" --menu "$text" 20 60 10 \
            "1" "🚀 快速配置（推荐新手）" \
            "2" "⚙️  自定义配置" \
            "3" "📦 安装特定服务" \
            "4" "🔧 系统优化" \
            "5" "📊 查看系统状态" \
            "6" "🗑️  卸载服务" \
            "7" "❓ 帮助与支持" \
            "0" "退出" \
            3>&1 1>&2 2>&3
    elif [[ "$tui_tool" == "dialog" ]]; then
        dialog --title "$title" --menu "$text" 20 60 10 \
            "1" "快速配置（推荐新手）" \
            "2" "自定义配置" \
            "3" "安装特定服务" \
            "4" "系统优化" \
            "5" "查看系统状态" \
            "6" "卸载服务" \
            "7" "帮助与支持" \
            "0" "退出" \
            3>&1 1>&2 2>&3
    fi
}

# 显示主菜单（CLI 模式）
show_main_menu_cli() {
    show_banner
    
    echo "  [1] 🚀 快速配置（推荐新手）"
    echo "  [2] ⚙️  自定义配置"
    echo "  [3] 📦 安装特定服务"
    echo "  [4] 🔧 系统优化"
    echo "  [5] 📊 查看系统状态"
    echo "  [6] 🗑️  卸载服务"
    echo "  [7] ❓ 帮助与支持"
    echo ""
    echo "  [0] 退出"
    echo ""
    show_separator "-" 40
    echo ""
}

# 显示主菜单（自动选择模式）
show_main_menu() {
    if supports_tui; then
        show_main_menu_tui
    else
        show_main_menu_cli
        read -r -p "请输入选项 [0-7]: " choice
        echo "$choice"
    fi
}

# ============================================
# 服务选择菜单
# ============================================

# 定义可用服务列表
declare -A SERVICES
declare -A SERVICES_DESC

init_services() {
    SERVICES=(
        ["docker"]="Docker"
        ["homeassistant"]="Home Assistant"
        ["plex"]="Plex Media Server"
        ["jellyfin"]="Jellyfin"
        ["qbittorrent"]="qBittorrent"
        ["samba"]="Samba 文件共享"
        ["pihole"]="Pi-hole 去广告"
        ["adguard"]="AdGuard Home"
        ["nodejs"]="Node.js"
        ["python"]="Python 环境"
        ["codeserver"]="VS Code Server"
        ["portainer"]="Portainer"
        ["grafana"]="Grafana 监控"
        ["mqtt"]="MQTT Broker"
        ["nodered"]="Node-RED"
        ["esphome"]="ESPHome"
        ["openvpn"]="OpenVPN"
        ["wireguard"]="WireGuard"
        ["frp"]="Frp 内网穿透"
        ["nextcloud"]="Nextcloud"
    )
    
    SERVICES_DESC=(
        ["docker"]="容器化平台"
        ["homeassistant"]="开源智能家居平台"
        ["plex"]="私人媒体服务器"
        ["jellyfin"]="开源媒体服务器（Plex替代品）"
        ["qbittorrent"]="BT下载工具"
        ["samba"]="Windows文件共享"
        ["pihole"]="DNS去广告"
        ["adguard"]="高级去广告工具"
        ["nodejs"]="JavaScript运行时"
        ["python"]="Python3 + pip + venv"
        ["codeserver"]="浏览器版VS Code"
        ["portainer"]="Docker可视化管理"
        ["grafana"]="监控仪表盘"
        ["mqtt"]="物联网消息中间件"
        ["nodered"]="可视化流程编程"
        ["esphome"]="ESP设备固件生成"
        ["openvpn"]="VPN服务器"
        ["wireguard"]="新一代VPN协议"
        ["frp"]="内网穿透工具"
        ["nextcloud"]="私有云盘"
    )
}

# 显示服务选择菜单（多选，TUI）
show_service_menu_tui() {
    local tui_tool
    tui_tool=$(detect_tui_tool)
    
    local title="选择要安装的服务"
    local text="使用空格键选择，回车键确认："
    local items=()
    
    # 构建选项列表
    for key in "${!SERVICES[@]}"; do
        items+=("$key" "${SERVICES[$key]}" "OFF")
    done
    
    if [[ "$tui_tool" == "whiptail" ]]; then
        whiptail --title "$title" --checklist "$text" 22 70 15 \
            "${items[@]}" \
            3>&1 1>&2 2>&3
    elif [[ "$tui_tool" == "dialog" ]]; then
        dialog --title "$title" --checklist "$text" 22 70 15 \
            "${items[@]}" \
            3>&1 1>&2 2>&3
    fi
}

# 显示服务选择菜单（多选，CLI）
show_service_menu_cli() {
    show_banner
    show_section "选择要安装的服务"
    
    echo ""
    echo "请输入服务编号，多个用空格分隔，回车确认："
    echo ""
    
    local i=1
    for key in "${!SERVICES[@]}"; do
        printf "  [%2d] %-20s - %s\n" "$i" "${SERVICES[$key]}" "${SERVICES_DESC[$key]}"
        ((i++))
    done
    
    echo ""
    read -r -p "选择: " selection
    echo "$selection"
}

# 显示服务选择菜单（自动选择模式）
show_service_menu() {
    init_services
    
    if supports_tui; then
        show_service_menu_tui
    else
        show_service_menu_cli
    fi
}

# ============================================
# 镜像源选择
# ============================================

# 显示镜像源选择菜单
show_mirror_menu() {
    local title="选择软件源"
    local text="选择离你最近的镜像源，可提高下载速度："
    
    if supports_tui; then
        local tui_tool
        tui_tool=$(detect_tui_tool)
        
        if [[ "$tui_tool" == "whiptail" ]]; then
            whiptail --title "$title" --menu "$text" 15 60 5 \
                "tsinghua" "清华大学（推荐）" \
                "ustc" "中国科技大学" \
                "aliyun" "阿里云" \
                "tencent" "腾讯云" \
                "default" "保持默认" \
                3>&1 1>&2 2>&3
        elif [[ "$tui_tool" == "dialog" ]]; then
            dialog --title "$title" --menu "$text" 15 60 5 \
                "tsinghua" "清华大学（推荐）" \
                "ustc" "中国科技大学" \
                "aliyun" "阿里云" \
                "tencent" "腾讯云" \
                "default" "保持默认" \
                3>&1 1>&2 2>&3
        fi
    else
        show_banner
        show_section "选择软件源"
        
        echo ""
        echo "  [1] 清华大学（推荐）"
        echo "  [2] 中国科技大学"
        echo "  [3] 阿里云"
        echo "  [4] 腾讯云"
        echo "  [5] 保持默认"
        echo ""
        
        read -r -p "请选择 [1-5]: " choice
        
        case $choice in
            1) echo "tsinghua" ;;
            2) echo "ustc" ;;
            3) echo "aliyun" ;;
            4) echo "tencent" ;;
            5) echo "default" ;;
            *) echo "tsinghua" ;;
        esac
    fi
}

# ============================================
# 进度显示
# ============================================

# 显示进度条（图形）
show_progress_bar() {
    local current="$1"
    local total="$2"
    local width="${3:-50}"
    local message="${4:-进度}"
    
    local percent=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r%s [" "$message"
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%" "$percent"
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# 显示简单的进度
show_simple_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-处理中}"
    
    printf "\r%s: %d/%d" "$message" "$current" "$total"
    
    if [[ $current -eq $total ]]; then
        echo " 完成"
    fi
}

# 显示旋转进度（用于等待）
show_spinner() {
    local pid="$1"
    local message="${2:-请稍候}"
    local delay=0.1
    local spinstr='|/-\'
    
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r%s [%c]" "$message" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r%s [✓]\n" "$message"
}

# ============================================
# 消息框
# ============================================

# 显示信息框
show_info_box() {
    local title="$1"
    local message="$2"
    
    if supports_tui; then
        local tui_tool
        tui_tool=$(detect_tui_tool)
        
        if [[ "$tui_tool" == "whiptail" ]]; then
            whiptail --title "$title" --msgbox "$message" 15 60
        elif [[ "$tui_tool" == "dialog" ]]; then
            dialog --title "$title" --msgbox "$message" 15 60
        fi
    else
        show_banner
        show_section "$title"
        echo "$message"
        echo ""
        read -r -p "按回车键继续..."
    fi
}

# 显示确认框
show_confirm_box() {
    local title="$1"
    local message="$2"
    
    if supports_tui; then
        local tui_tool
        tui_tool=$(detect_tui_tool)
        
        if [[ "$tui_tool" == "whiptail" ]]; then
            whiptail --title "$title" --yesno "$message" 10 60
            return $?
        elif [[ "$tui_tool" == "dialog" ]]; then
            dialog --title "$title" --yesno "$message" 10 60
            return $?
        fi
    else
        echo "$message"
        ask_yes_no "确认"
        return $?
    fi
}

# 显示输入框
show_input_box() {
    local title="$1"
    local message="$2"
    local default="${3:-}"
    
    if supports_tui; then
        local tui_tool
        tui_tool=$(detect_tui_tool)
        
        if [[ "$tui_tool" == "whiptail" ]]; then
            whiptail --title "$title" --inputbox "$message" 10 60 "$default" \
                3>&1 1>&2 2>&3
        elif [[ "$tui_tool" == "dialog" ]]; then
            dialog --title "$title" --inputbox "$message" 10 60 "$default" \
                3>&1 1>&2 2>&3
        fi
    else
        if [[ -n "$default" ]]; then
            read -r -p "$message [$default]: " input
            echo "${input:-$default}"
        else
            read -r -p "$message: " input
            echo "$input"
        fi
    fi
}

# 显示密码输入框
show_password_box() {
    local title="$1"
    local message="$2"
    
    if supports_tui; then
        local tui_tool
        tui_tool=$(detect_tui_tool)
        
        if [[ "$tui_tool" == "whiptail" ]]; then
            whiptail --title "$title" --passwordbox "$message" 10 60 \
                3>&1 1>&2 2>&3
        elif [[ "$tui_tool" == "dialog" ]]; then
            dialog --title "$title" --passwordbox "$message" 10 60 \
                3>&1 1>&2 2>&3
        fi
    else
        ask_password "$message"
    fi
}

# ============================================
# 结果显示
# ============================================

# 显示安装结果报告
show_install_report() {
    local installed=("$@")
    
    show_banner
    show_section "安装完成报告"
    
    echo ""
    echo -e "${COLOR_GREEN}以下服务已安装：${COLOR_NC}"
    echo ""
    
    for service in "${installed[@]}"; do
        log_success "$service"
    done
    
    echo ""
    show_separator "-" 40
}

# 显示错误报告
show_error_report() {
    local errors=("$@")
    
    show_banner
    show_section "安装遇到问题"
    
    echo ""
    echo -e "${COLOR_RED}以下服务安装失败：${COLOR_NC}"
    echo ""
    
    for error in "${errors[@]}"; do
        log_fail "$error"
    done
    
    echo ""
    echo "查看日志获取详细信息："
    echo "  ${PIBOOT_LOG_DIR}/piboot.log"
    echo ""
    
    read -r -p "按回车键继续..."
}

# 显示系统信息
show_system_info() {
    show_banner
    show_section "系统信息"
    
    echo ""
    echo -e "${COLOR_CYAN}硬件信息：${COLOR_NC}"
    get_hardware_info | sed 's/^/  /'
    
    echo ""
    echo -e "${COLOR_CYAN}操作系统：${COLOR_NC}"
    echo "  $(get_os_info)"
    
    echo ""
    echo -e "${COLOR_CYAN}网络信息：${COLOR_NC}"
    echo "  IP地址: $(get_ip_address)"
    
    echo ""
    echo -e "${COLOR_CYAN}PiBoot信息：${COLOR_NC}"
    echo "  版本: $PIBOOT_VERSION"
    echo "  安装路径: $PIBOOT_DIR"
    echo "  日志路径: $PIBOOT_LOG_DIR"
    
    echo ""
    read -r -p "按回车键继续..."
}

# ============================================
# 帮助信息
# ============================================

show_help() {
    show_banner
    
    cat << 'EOF'
PiBoot 使用说明

快速开始:
  1. 运行 sudo ./install.sh 启动安装程序
  2. 选择"快速配置"一键完成基础设置
  3. 或选择"自定义配置"按需安装服务

常用服务:
  • Home Assistant - 智能家居平台
  • Docker - 容器化平台
  • Plex/Jellyfin - 私人影院
  • Samba - 文件共享
  • Pi-hole - 去广告

快捷键:
  • Tab - 切换选项
  • Space - 选择/取消
  • Enter - 确认
  • Esc - 取消

帮助与支持:
  • GitHub: https://github.com/liushutao/piboot
  • 邮箱: your-email@example.com

EOF
    
    read -r -p "按回车键继续..."
}

# ============================================
# 退出处理
# ============================================

# 显示退出信息
show_exit_message() {
    echo ""
    echo -e "${COLOR_GREEN}感谢使用 PiBoot！${COLOR_NC}"
    echo ""
    echo "如有问题，请访问: https://github.com/liushutao/piboot"
    echo ""
}
