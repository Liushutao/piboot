# install.sh - PiBoot 入口脚本
# 主入口，负责检测环境、下载完整脚本、启动安装流程

set -e

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# 版本号
readonly VERSION="1.0.0"
readonly REPO_URL="https://github.com/yourusername/piboot"

# 打印带颜色的信息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_banner() {
    clear
    echo -e "${BLUE}"
    echo "========================================"
    echo "     PiBoot - RPi5 一键部署工具"
    echo "     版本: $VERSION"
    echo "========================================"
    echo -e "${NC}"
    echo ""
}

# 检查是否以 root 运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "请使用 sudo 运行此脚本"
        echo "例如: sudo ./install.sh"
        exit 1
    fi
}

# 检查是否在 Raspberry Pi 上运行
check_hardware() {
    if [[ -f /proc/device-tree/model ]]; then
        local model=$(tr -d '\0' < /proc/device-tree/model)
        if [[ "$model" == *"Raspberry Pi 5"* ]]; then
            print_info "检测到硬件: $model ✓"
            return 0
        else
            print_warn "检测到: $model"
            print_warn "本工具主要为 Raspberry Pi 5 优化"
            read -p "是否继续? [y/N]: " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 0
            fi
        fi
    else
        print_warn "无法检测硬件型号"
        read -p "是否继续? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
}

# 检查操作系统
check_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        print_info "操作系统: $NAME $VERSION_ID"
        
        if [[ "$ID" != "debian" && "$ID" != "raspbian" && "$ID" != "ubuntu" ]]; then
            print_warn "本工具主要针对 Raspberry Pi OS (Debian) 优化"
        fi
    else
        print_warn "无法检测操作系统"
    fi
}

# 检查网络连接
check_network() {
    print_info "检查网络连接..."
    if ping -c 1 -W 3 223.5.5.5 >/dev/null 2>&1 || \
       ping -c 1 -W 3 114.114.114.114 >/dev/null 2>&1; then
        print_info "网络连接正常 ✓"
        return 0
    else
        print_error "无法连接到网络"
        exit 1
    fi
}

# 检查必要命令
check_dependencies() {
    local deps=("curl" "wget" "git" "whiptail")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_info "安装依赖: ${missing[*]}"
        apt-get update -qq
        apt-get install -y -qq "${missing[@]}"
    fi
}

# 显示主菜单
show_main_menu() {
    while true; do
        local choice
        choice=$(whiptail --title "PiBoot - RPi5 一键部署工具" \
            --menu "请选择操作:" 20 60 10 \
            "1" "🚀 快速配置（推荐新手）" \
            "2" "⚙️  自定义配置" \
            "3" "📦 安装特定服务" \
            "4" "🔧 系统优化" \
            "5" "📊 查看状态" \
            "6" "🗑️  卸载服务" \
            "7" "❓ 帮助" \
            "0" "退出" \
            3>&1 1>&2 2>&3)
        
        case $choice in
            1) run_quick_setup ;;
            2) run_custom_setup ;;
            3) install_services ;;
            4) system_optimize ;;
            5) show_status ;;
            6) uninstall_services ;;
            7) show_help ;;
            0|"") exit 0 ;;
            *) print_error "无效选项" ;;
        esac
    done
}

# 快速配置
run_quick_setup() {
    print_info "开始快速配置..."
    # TODO: 调用快速配置脚本
    read -p "按回车键继续..."
}

# 自定义配置
run_custom_setup() {
    print_info "开始自定义配置..."
    # TODO: 调用自定义配置脚本
    read -p "按回车键继续..."
}

# 安装服务
install_services() {
    print_info "安装特定服务..."
    # TODO: 显示服务列表供选择
    read -p "按回车键继续..."
}

# 系统优化
system_optimize() {
    print_info "系统优化..."
    # TODO: 系统优化选项
    read -p "按回车键继续..."
}

# 查看状态
show_status() {
    print_info "系统状态..."
    echo ""
    echo "操作系统: $(uname -o)"
    echo "内核版本: $(uname -r)"
    echo "IP 地址: $(hostname -I | awk '{print $1}')"
    echo ""
    read -p "按回车键继续..."
}

# 卸载服务
uninstall_services() {
    print_info "卸载服务..."
    # TODO: 卸载逻辑
    read -p "按回车键继续..."
}

# 显示帮助
show_help() {
    whiptail --title "帮助" --msgbox "PiBoot 使用说明:\n\n1. 快速配置 - 一键完成基础配置\n2. 自定义配置 - 按需选择安装项\n3. 安装服务 - 单独安装特定服务\n\n更多帮助请访问:\n$REPO_URL" 15 60
}

# 主函数
main() {
    print_banner
    
    check_root
    check_hardware
    check_os
    check_network
    check_dependencies
    
    print_info "环境检查完成，启动主菜单..."
    sleep 1
    
    show_main_menu
}

# 运行主函数
main "$@"
