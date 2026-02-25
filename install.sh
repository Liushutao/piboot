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
    
    # 检测硬件（不强制退出）
    local hw_type
    hw_type=$(check_raspberry_pi || echo "unknown")
    
    if [[ "$hw_type" == "unknown" ]]; then
        log_warn "未检测到 Raspberry Pi"
        log_info "当前系统: $(get_os_info)"
        read -p "是否继续安装? [Y/n]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ && ! -z $REPLY ]]; then
            exit 0
        fi
    fi
    
    # 显示硬件信息
    show_section "硬件信息"
    get_hardware_info 2>/dev/null | sed 's/^/  /' || echo "  无法获取硬件信息"
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
        apt-get update -qq
        apt-get install -y -qq whiptail 2>/dev/null || {
            log_warn "无法安装 whiptail，将使用 CLI 模式"
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
    
    read -p "开始快速配置? [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ && ! -z $REPLY ]]; then
        return 0
    fi
    
    # 加载系统配置模块
    source "${SCRIPT_DIR}/modules/00_system.sh"
    
    # 选择镜像源
    local mirror
    mirror=$(show_mirror_menu)
    
    # 步骤1-2: 更换镜像源并更新
    local total_steps=5
    local current=0
    
    ((current++))
    show_progress_bar "$current" "$total_steps" 40 "更换镜像源"
    change_mirror "$mirror" || log_warn "镜像源更换失败，使用默认源"
    sleep 0.5
    
    ((current++))
    show_progress_bar "$current" "$total_steps" 40 "更新系统"
    update_package_list && upgrade_packages || log_warn "系统更新部分失败"
    sleep 0.5
    
    # 步骤3: 配置中文环境
    ((current++))
    show_progress_bar "$current" "$total_steps" 40 "配置中文"
    setup_chinese_locale || log_warn "中文环境配置失败"
    sleep 0.5
    
    # 步骤4: 安装 Docker
    ((current++))
    show_progress_bar "$current" "$total_steps" 40 "安装Docker"
    source "${SCRIPT_DIR}/modules/01_docker.sh"
    module_install || log_warn "Docker 安装失败"
    sleep 0.5
    
    # 步骤5: 安装 Home Assistant（可选）
    ((current++))
    show_progress_bar "$current" "$total_steps" 40 "完成配置"
    
    read -p "是否安装 Home Assistant? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_homeassistant
    fi
    
    echo ""
    show_separator "=" 60
    echo -e "${COLOR_GREEN}快速配置完成！${COLOR_NC}"
    echo ""
    echo "后续操作："
    echo "  • 运行 'docker ps' 查看容器状态"
    echo "  • 访问 http://$(get_ip_address):8123 打开 Home Assistant"
    echo ""
    
    read -p "按回车键返回主菜单..."
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
    
    # 加载系统配置模块
    source "${SCRIPT_DIR}/modules/00_system.sh"
    
    # 执行自定义配置
    module_custom_setup
    
    read -p "按回车键返回主菜单..."
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
    
    read -p "确认安装? [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ && ! -z $REPLY ]]; then
        return 0
    fi
    
    # 解析选择的服务并安装
    for service in $services; do
        case $service in
            docker)
                source "${SCRIPT_DIR}/modules/01_docker.sh"
                module_install
                ;;
            homeassistant)
                install_homeassistant
                ;;
            plex)
                install_plex
                ;;
            *)
                log_warn "服务 $service 暂不支持"
                ;;
        esac
    done
    
    log_success "安装完成"
    read -p "按回车键返回主菜单..."
}

# 安装 Home Assistant
install_homeassistant() {
    log_info "安装 Home Assistant..."
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        return 1
    fi
    
    # 创建配置目录
    local ha_dir="${HOME}/homeassistant"
    ensure_dir "$ha_dir"
    ensure_dir "$ha_dir/config"
    
    # 复制 compose 文件
    cp "${SCRIPT_DIR}/config/docker-compose/homeassistant.yml" "$ha_dir/docker-compose.yml"
    
    # 启动
    cd "$ha_dir"
    docker compose up -d
    
    log_success "Home Assistant 安装完成"
    log_info "访问地址: http://$(get_ip_address):8123"
    log_info "配置文件位置: $ha_dir/config"
}

# 安装 Plex
install_plex() {
    log_info "安装 Plex Media Server..."
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        return 1
    fi
    
    # 创建配置目录
    local plex_dir="${HOME}/plex"
    ensure_dir "$plex_dir"
    ensure_dir "$plex_dir/config"
    ensure_dir "$plex_dir/media"
    ensure_dir "$plex_dir/transcode"
    
    # 复制 compose 文件
    cp "${SCRIPT_DIR}/config/docker-compose/plex.yml" "$plex_dir/docker-compose.yml"
    
    # 启动
    cd "$plex_dir"
    docker compose up -d
    
    log_success "Plex 安装完成"
    log_info "访问地址: http://$(get_ip_address):32400"
    log_info "媒体文件位置: $plex_dir/media"
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
    echo "  [5] 优化 swappiness"
    echo ""
    
    read -r -p "请选择优化项目 [1-5]: " opt
    
    # 加载系统配置模块
    source "${SCRIPT_DIR}/modules/00_system.sh"
    
    case $opt in
        1) expand_filesystem ;;
        2) 
            read -r -p "输入GPU内存大小(MB) [128]: " gpu_mem
            optimize_gpu_mem "${gpu_mem:-128}"
            ;;
        3) setup_ssh_key ;;
        4) disable_bluetooth ;;
        5) optimize_swappiness 10 ;;
        *) log_warn "无效选项" ;;
    esac
    
    read -p "按回车键返回主菜单..."
}

# 卸载服务
uninstall_services() {
    show_banner
    show_section "卸载服务"
    
    log_warn "此功能将删除已安装的服务"
    echo ""
    echo "  [1] 卸载 Docker"
    echo "  [2] 卸载 Home Assistant"
    echo "  [3] 卸载 Plex"
    echo ""
    
    read -r -p "请选择 [1-3]: " opt
    
    case $opt in
        1)
            source "${SCRIPT_DIR}/modules/01_docker.sh"
            uninstall_docker
            ;;
        2)
            log_info "卸载 Home Assistant..."
            cd "$HOME/homeassistant" 2>/dev/null && docker compose down || true
            rm -rf "$HOME/homeassistant"
            log_success "Home Assistant 已卸载"
            ;;
        3)
            log_info "卸载 Plex..."
            cd "$HOME/plex" 2>/dev/null && docker compose down || true
            rm -rf "$HOME/plex"
            log_success "Plex 已卸载"
            ;;
        *) log_warn "无效选项" ;;
    esac
    
    read -p "按回车键返回主菜单..."
}

# 运行主程序
main "$@"
