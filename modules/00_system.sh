#!/bin/bash
# modules/00_system.sh - 系统基础配置模块
# 负责：系统更新、换源、中文环境、SSH配置等

# 模块信息
MODULE_NAME="系统基础配置"
MODULE_DESC="系统更新、镜像源、中文环境、SSH配置"
MODULE_VERSION="1.0.0"

# ============================================
# 系统更新
# ============================================

# 更新软件包列表
update_package_list() {
    log_info "更新软件包列表..."
    
    if apt-get update -qq; then
        log_success "软件包列表更新完成"
        return 0
    else
        log_error "软件包列表更新失败"
        return 1
    fi
}

# 升级已安装软件包
upgrade_packages() {
    log_info "升级已安装软件包..."
    
    # 先检查是否有可升级的包
    local upgradable
    upgradable=$(apt list --upgradable 2>/dev/null | wc -l)
    
    if [[ $upgradable -le 1 ]]; then
        log_info "所有软件包已是最新版本"
        return 0
    fi
    
    log_info "有 $((upgradable - 1)) 个软件包可以升级"
    
    if apt-get upgrade -y -qq; then
        log_success "软件包升级完成"
        return 0
    else
        log_warn "部分软件包升级失败"
        return 1
    fi
}

# 完全升级（包含内核等）
full_upgrade() {
    log_info "执行完全升级..."
    
    if apt-get dist-upgrade -y -qq; then
        log_success "完全升级完成"
        return 0
    else
        log_warn "完全升级部分失败"
        return 1
    fi
}

# 清理无用包
clean_packages() {
    log_info "清理无用软件包..."
    
    apt-get autoremove -y -qq
    apt-get autoclean -qq
    
    log_success "清理完成"
}

# ============================================
# 镜像源配置
# ============================================

# 定义可用镜像源
declare -A MIRRORS
declare -A MIRROR_URLS

init_mirrors() {
    local codename
    codename=$(lsb_release -cs 2>/dev/null || echo "noble")
    
    MIRRORS=(
        ["tsinghua"]="清华大学"
        ["ustc"]="中国科技大学"
        ["aliyun"]="阿里云"
        ["tencent"]="腾讯云"
        ["default"]="官方源"
    )
    
    MIRROR_URLS=(
        ["tsinghua"]="https://mirrors.tuna.tsinghua.edu.cn"
        ["ustc"]="https://mirrors.ustc.edu.cn"
        ["aliyun"]="https://mirrors.aliyun.com"
        ["tencent"]="https://mirrors.tencent.com"
        ["default"]="http://archive.ubuntu.com"
    )
}

# 更换软件源
change_mirror() {
    local mirror="${1:-tsinghua}"
    
    init_mirrors
    
    if [[ "$mirror" == "default" ]]; then
        log_info "保持官方源"
        return 0
    fi
    
    log_info "更换为 ${MIRRORS[$mirror]}..."
    
    local codename
    codename=$(lsb_release -cs 2>/dev/null || echo "noble")
    
    local mirror_url="${MIRROR_URLS[$mirror]}"
    
    # 备份原配置
    backup_file /etc/apt/sources.list
    
    # 生成新配置
    cat > /etc/apt/sources.list << EOF
# ${MIRRORS[$mirror]} - Ubuntu $codename
deb $mirror_url/ubuntu/ $codename main restricted universe multiverse
deb $mirror_url/ubuntu/ $codename-updates main restricted universe multiverse
deb $mirror_url/ubuntu/ $codename-backports main restricted universe multiverse
deb $mirror_url/ubuntu/ $codename-security main restricted universe multiverse
EOF
    
    # 更新软件包列表
    if apt-get update -qq; then
        log_success "镜像源更换完成"
        return 0
    else
        log_error "镜像源更换失败，恢复原配置"
        mv /etc/apt/sources.list.backup.* /etc/apt/sources.list
        apt-get update -qq
        return 1
    fi
}

# 更换 Raspbian 源（如果是树莓派）
change_raspbian_mirror() {
    local mirror="${1:-tsinghua}"
    
    init_mirrors
    
    if [[ ! -f /etc/apt/sources.list.d/raspi.list ]]; then
        return 0
    fi
    
    log_info "更换 Raspbian 源为 ${MIRRORS[$mirror]}..."
    
    local mirror_url="${MIRROR_URLS[$mirror]}"
    
    # 备份
    backup_file /etc/apt/sources.list.d/raspi.list
    
    # 生成新配置
    cat > /etc/apt/sources.list.d/raspi.list << EOF
# ${MIRRORS[$mirror]} - Raspberry Pi
deb $mirror_url/raspberrypi/ $(lsb_release -cs) main ui
EOF
    
    log_success "Raspbian 源更换完成"
}

# ============================================
# 中文环境配置
# ============================================

# 配置中文 locale
setup_chinese_locale() {
    log_info "配置中文环境..."
    
    # 安装中文语言包
    apt-get install -y -qq language-pack-zh-hans language-pack-zh-hans-base locales 2>/dev/null || \
    apt-get install -y -qq locales
    
    # 生成 locale
    locale-gen zh_CN.UTF-8
    locale-gen en_US.UTF-8
    
    # 设置默认 locale
    update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8
    
    # 设置时区为上海
    timedatectl set-timezone Asia/Shanghai
    
    log_success "中文环境配置完成"
}

# 安装中文字体
install_chinese_fonts() {
    log_info "安装中文字体..."
    
    apt-get install -y -qq fonts-wqy-zenhei fonts-wqy-microhei fonts-noto-cjk
    
    log_success "中文字体安装完成"
}

# ============================================
# SSH 配置
# ============================================

# 配置 SSH 密钥登录
setup_ssh_key() {
    log_info "配置 SSH 密钥登录..."
    
    # 确保 SSH 服务运行
    if ! systemctl is-active --quiet ssh; then
        systemctl start ssh
        systemctl enable ssh
    fi
    
    # 备份配置
    backup_file /etc/ssh/sshd_config
    
    # 修改配置
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    
    # 重启 SSH
    systemctl restart sshd
    
    log_warn "SSH 已配置为密钥登录，请确保已上传公钥后再断开连接"
    log_info "公钥位置: ~/.ssh/authorized_keys"
    
    return 0
}

# 生成 SSH 密钥对
generate_ssh_key() {
    local key_file="${1:-$HOME/.ssh/id_rsa}"
    local comment="${2:-$(whoami)@$(hostname)}"
    
    if [[ -f "$key_file" ]]; then
        log_warn "SSH 密钥已存在: $key_file"
        return 0
    fi
    
    log_info "生成 SSH 密钥对..."
    
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    ssh-keygen -t ed25519 -C "$comment" -f "$key_file" -N ""
    
    log_success "SSH 密钥生成完成"
    log_info "公钥内容:"
    cat "${key_file}.pub"
}

# ============================================
# 文件系统
# ============================================

# 扩展文件系统到整个 SD 卡
expand_filesystem() {
    log_info "扩展文件系统..."
    
    # 检查是否是树莓派
    if [[ -f /usr/bin/raspi-config ]]; then
        raspi-config --expand-rootfs
        log_success "文件系统将在下次启动后扩展"
        log_warn "请重启系统以应用更改"
        return 0
    fi
    
    # 手动扩展（通用 Linux）
    local root_part
    root_part=$(findmnt -n -o SOURCE /)
    
    log_info "根分区: $root_part"
    log_warn "请手动使用 fdisk/growpart 扩展分区"
    
    return 0
}

# ============================================
# 系统优化
# ============================================

# 优化 swappiness
optimize_swappiness() {
    local value="${1:-10}"
    
    log_info "优化 swappiness 为 $value..."
    
    # 临时生效
    sysctl -w vm.swappiness=$value
    
    # 永久生效
    if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
        echo "vm.swappiness=$value" >> /etc/sysctl.conf
    else
        sed -i "s/vm.swappiness=.*/vm.swappiness=$value/" /etc/sysctl.conf
    fi
    
    log_success "swappiness 优化完成"
}

# 优化 GPU 内存分配（树莓派专用）
optimize_gpu_mem() {
    local mem="${1:-128}"
    
    if [[ ! -f /boot/firmware/config.txt && ! -f /boot/config.txt ]]; then
        log_warn "非树莓派系统，跳过 GPU 内存优化"
        return 0
    fi
    
    log_info "设置 GPU 内存为 ${mem}MB..."
    
    local config_file
    if [[ -f /boot/firmware/config.txt ]]; then
        config_file="/boot/firmware/config.txt"
    else
        config_file="/boot/config.txt"
    fi
    
    # 备份
    backup_file "$config_file"
    
    # 修改或添加配置
    if grep -q "^gpu_mem=" "$config_file"; then
        sed -i "s/^gpu_mem=.*/gpu_mem=$mem/" "$config_file"
    else
        echo "gpu_mem=$mem" >> "$config_file"
    fi
    
    log_success "GPU 内存设置完成，重启后生效"
}

# 禁用蓝牙（节省资源）
disable_bluetooth() {
    log_info "禁用蓝牙..."
    
    systemctl stop bluetooth
    systemctl disable bluetooth
    
    if [[ -f /boot/firmware/config.txt ]]; then
        echo "dtoverlay=disable-bt" >> /boot/firmware/config.txt
    elif [[ -f /boot/config.txt ]]; then
        echo "dtoverlay=disable-bt" >> /boot/config.txt
    fi
    
    log_success "蓝牙已禁用"
}

# ============================================
# 模块主入口
# ============================================

# 快速配置（一键执行常用配置）
module_quick_setup() {
    log_info "开始系统快速配置..."
    
    # 选择镜像源
    local mirror
    mirror=$(show_mirror_menu)
    
    # 1. 更换镜像源
    change_mirror "$mirror"
    change_raspbian_mirror "$mirror"
    
    # 2. 更新系统
    update_package_list
    upgrade_packages
    
    # 3. 配置中文环境
    if ask_yes_no "是否配置中文环境" "Y"; then
        setup_chinese_locale
        install_chinese_fonts
    fi
    
    # 4. 系统优化
    optimize_swappiness 10
    
    # 5. 清理
    clean_packages
    
    log_success "系统快速配置完成！"
}

# 自定义配置
module_custom_setup() {
    log_info "自定义系统配置"
    
    # 镜像源
    if ask_yes_no "更换软件源"; then
        local mirror
        mirror=$(show_mirror_menu)
        change_mirror "$mirror"
    fi
    
    # 系统更新
    if ask_yes_no "更新系统软件包"; then
        update_package_list
        upgrade_packages
    fi
    
    # 中文环境
    if ask_yes_no "配置中文环境"; then
        setup_chinese_locale
    fi
    
    # SSH 配置
    if ask_yes_no "配置 SSH 密钥登录（禁用密码）"; then
        setup_ssh_key
    fi
    
    # 文件系统扩展
    if ask_yes_no "扩展文件系统到整个 SD 卡"; then
        expand_filesystem
    fi
}

# 模块主入口
module_main() {
    local action="${1:-quick}"
    
    case $action in
        quick)
            module_quick_setup
            ;;
        custom)
            module_custom_setup
            ;;
        update)
            update_package_list
            upgrade_packages
            ;;
        mirror)
            local mirror
            mirror=$(show_mirror_menu)
            change_mirror "$mirror"
            ;;
        locale)
            setup_chinese_locale
            ;;
        ssh)
            setup_ssh_key
            ;;
        expand)
            expand_filesystem
            ;;
        *)
            log_error "未知操作: $action"
            return 1
            ;;
    esac
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$(dirname "$0")/../lib/core.sh"
    source "$(dirname "$0")/../lib/ui.sh"
    module_main "$@"
fi
