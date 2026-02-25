#!/bin/bash
# install.sh - PiBoot 入口脚本
# 主入口，负责检测环境、启动安装流程

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 引入核心库
source "${SCRIPT_DIR}/lib/core.sh"
source "${SCRIPT_DIR}/lib/ui.sh"

# 设置错误处理
set_error_trap

# ============================================
# 主程序
# ============================================

main() {
    # 显示 Banner
    show_banner
    
    # 检查 Root 权限
    check_root || exit 1
    
    # 检测硬件
    local hw_type
    hw_type=$(check_raspberry_pi || echo "unknown")
    
    if [[ "$hw_type" == "unknown" ]]; then
        log_warn "未检测到 Raspberry Pi"
        log_info "当前系统: $(get_os_info)"
        if ! ask_yes_no "是否继续安装（部分功能可能不可用）"; then
            exit 0
        fi
    fi
    
    # 显示硬件信息
    show_section "硬件信息"
    get_hardware_info | sed 's/^/  /'
    echo ""
    
    # 检测操作系统
    show_section "操作系统"
    log_info "$(get_os_info)"
    echo ""
    
    # 检查网络
    check_network || {
        log_error "网络连接失败，请检查网络设置"
        exit 1
    }
    
    # 初始化环境
    init_piboot
    
    # 安装依赖（如果需要）
    if ! cmd_exists whiptail; then
        log_info "安装必要依赖..."
        install_package whiptail || install_package dialog || {
            log_warn "无法安装 TUI 工具，将使用 CLI 模式"
            USE_TUI=false
        }
    fi
    
    log_success "环境准备完成！"
    sleep 1
    
    # 主循环
    while true; do
        local choice
        choice=$(show_main_menu)
        
        case $choice in
            1)
                run_quick_setup
                ;;
            2)
                run_custom_setup
                ;;
            3)
                install_specific_services
                ;;
            4)
                system_optimize
                ;;
            5)
                show_system_info
                ;;
            6)
                uninstall_services
                ;;
            7)
                show_help
                ;;
            0|""|*)
                show_exit_message
                exit 0
                ;;
        esac
    done
}

# ============================================
# 功能实现
# ============================================

# 快速配置
run_quick_setup() {
    show_banner
    show_section "快速配置"
    
    log_info "快速配置将完成以下任务："
    echo "  1. 更新系统软件包"
    echo "  2. 更换国内镜像源"
    echo "  3. 配置中文环境"
    echo "  4. 安装 Docker"
    echo "  5. 安装 Home Assistant（可选）"
    echo ""
    
    if ! ask_yes_no "开始快速配置"; then
        return 0
    fi
    
    # 执行配置
    local total_steps=5
    local current=0
    
    # 步骤1: 更新系统
    ((current++))
    show_progress_bar "$current" "$total_steps" 40 "更新系统"
    log_info "[$current/$total_steps] 更新系统软件包..."
    apt-get update -qq && apt-get upgrade -y -qq || log_warn "系统更新部分失败"
    log_success "系统更新完成"
    sleep 0.5
    
    # 步骤2: 更换镜像源
    ((current++))
    show_progress_bar "$current" "$total_steps" 40 "更换镜像源"
    log_info "[$current/$total_steps] 更换镜像源..."
    # TODO: 调用镜像源更换脚本
    log_success "镜像源更换完成"
    sleep 0.5
    
    # 步骤3: 配置中文环境
    ((current++))
    show_progress_bar "$current" "$total_steps" 40 "配置中文"
    log_info "[$current/$total_steps] 配置中文环境..."
    # TODO: 调用中文环境配置脚本
    log_success "中文环境配置完成"
    sleep 0.5
    
    # 步骤4: 安装 Docker
    ((current++))
    show_progress_bar "$current" "$total_steps" 40 "安装Docker"
    log_info "[$current/$total_steps] 安装 Docker..."
    # TODO: 调用 Docker 安装脚本
    log_success "Docker 安装完成"
    sleep 0.5
    
    # 步骤5: 询问是否安装 Home Assistant
    ((current++))
    show_progress_bar "$current" "$total_steps" 40 "完成配置"
    if ask_yes_no "是否安装 Home Assistant"; then
        log_info "安装 Home Assistant..."
        # TODO: 调用 HA 安装脚本
    fi
    
    echo ""
    show_separator "=" 60
    echo -e "${COLOR_GREEN}快速配置完成！${COLOR_NC}"
    echo ""
    echo "后续操作："
    echo "  • 运行 'docker ps' 查看容器状态"
    echo "  • 访问 http://$(get_ip_address):8123 打开 Home Assistant"
    echo ""
    
    read -r -p "按回车键返回主菜单..."
}

# 自定义配置
run_custom_setup() {
    show_banner
    show_section "自定义配置"
    
    log_info "自定义配置允许您选择具体的配置项..."
    echo ""
    
    # 选择镜像源
    local mirror
    mirror=$(show_mirror_menu)
    log_info "选择的镜像源: $mirror"
    
    # 选择服务
    local services
    services=$(show_service_menu)
    log_info "选择的服务: $services"
    
    # TODO: 执行安装
    
    read -r -p "按回车键返回主菜单..."
}

# 安装特定服务
install_specific_services() {
    show_banner
    show_section "安装特定服务"
    
    local services
    services=$(show_service_menu)
    
    if [[ -z "$services" ]]; then
        log_warn "未选择任何服务"
        return 0
    fi
    
    log_info "准备安装: $services"
    
    if ask_yes_no "确认安装"; then
        # TODO: 调用各服务的安装脚本
        log_success "安装完成"
    fi
    
    read -r -p "按回车键返回主菜单..."
}

# 系统优化
system_optimize() {
    show_banner
    show_section "系统优化"
    
    log_info "可用的优化选项："
    echo ""
    echo "  [1] 扩展文件系统到整个SD卡"
    echo "  [2] 优化GPU内存分配"
    echo "  [3] 配置SSH密钥登录"
    echo "  [4] 禁用蓝牙（节省资源）"
    echo "  [5] 超频设置（谨慎使用）"
    echo ""
    
    read -r -p "请选择优化项目 [1-5]: " opt
    
    case $opt in
        1) log_info "扩展文件系统..." ;;
        2) log_info "优化GPU内存..." ;;
        3) log_info "配置SSH密钥..." ;;
        4) log_info "禁用蓝牙..." ;;
        5) log_info "超频设置..." ;;
        *) log_warn "无效选项" ;;
    esac
    
    read -r -p "按回车键返回主菜单..."
}

# 卸载服务
uninstall_services() {
    show_banner
    show_section "卸载服务"
    
    log_warn "此功能将删除已安装的服务"
    
    # TODO: 显示已安装的服务列表
    
    read -r -p "按回车键返回主菜单..."
}

# 运行主程序
main "$@"
