#!/bin/bash
# modules/01_docker.sh - Docker 安装模块
# 负责：Docker 和 Docker Compose 的安装与配置

# 模块信息
MODULE_NAME="Docker"
MODULE_DESC="Docker 容器平台和 Docker Compose"
MODULE_VERSION="1.0.0"

# ============================================
# 检测与清理
# ============================================

# 检测是否已安装 Docker
is_docker_installed() {
    if command -v docker &> /dev/null; then
        return 0
    fi
    return 1
}

# 检测 Docker 版本
get_docker_version() {
    if is_docker_installed; then
        docker --version | awk '{print $3}' | tr -d ','
    else
        echo "not installed"
    fi
}

# 清理旧版本 Docker
cleanup_old_docker() {
    log_info "清理旧版本 Docker..."
    
    local old_packages="docker docker-engine docker.io containerd runc"
    
    for pkg in $old_packages; do
        if dpkg -l | grep -q "^ii  $pkg "; then
            log_info "移除旧包: $pkg"
            apt-get remove -y "$pkg" 2>/dev/null || true
        fi
    done
    
    log_success "旧版本清理完成"
}

# ============================================
# 安装 Docker
# ============================================

# 安装依赖包
install_docker_dependencies() {
    log_info "安装 Docker 依赖..."
    
    apt-get update -qq
    apt-get install -y -qq \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common \
        apt-transport-https
    
    log_success "依赖安装完成"
}

# 添加 Docker 官方 GPG 密钥
add_docker_gpg_key() {
    log_info "添加 Docker GPG 密钥..."
    
    # 创建密钥目录
    install -m 0755 -d /etc/apt/keyrings
    
    # 下载并添加 GPG 密钥
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    log_success "GPG 密钥添加完成"
}

# 添加 Docker 软件源
add_docker_repository() {
    log_info "添加 Docker 软件源..."
    
    local arch
    arch=$(dpkg --print-architecture)
    
    local codename
    codename=$(lsb_release -cs 2>/dev/null || echo "noble")
    
    # 创建源列表
    echo \
        "deb [arch=$arch signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu \
        $codename stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 更新软件包列表
    apt-get update -qq
    
    log_success "Docker 软件源添加完成"
}

# 安装 Docker 引擎
install_docker_engine() {
    log_info "安装 Docker 引擎..."
    
    apt-get install -y -qq \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
    
    log_success "Docker 引擎安装完成"
}

# 安装 Docker Compose（独立版，兼容旧版）
install_docker_compose() {
    log_info "安装 Docker Compose..."
    
    # 检测架构
    local arch
    arch=$(uname -m)
    
    case $arch in
        x86_64)
            arch="x86_64"
            ;;
        aarch64|arm64)
            arch="aarch64"
            ;;
        armv7l)
            arch="armv7"
            ;;
        *)
            log_warn "未知架构: $arch，尝试使用插件版"
            return 0
            ;;
    esac
    
    # 获取最新版本
    local version
    version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | \
        grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ -z "$version" ]]; then
        version="v2.24.0"  # 默认版本
    fi
    
    log_info "安装 Docker Compose $version..."
    
    # 下载
    local url="https://github.com/docker/compose/releases/download/${version}/docker-compose-linux-${arch}"
    curl -fsSL "$url" -o /usr/local/bin/docker-compose
    
    # 添加执行权限
    chmod +x /usr/local/bin/docker-compose
    
    # 创建软链接
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log_success "Docker Compose 安装完成"
}

# ============================================
# 配置 Docker
# ============================================

# 配置 Docker 国内镜像加速
setup_docker_mirror() {
    log_info "配置 Docker 镜像加速..."
    
    # 创建配置目录
    mkdir -p /etc/docker
    
    # 国内镜像源
    cat > /etc/docker/daemon.json << 'EOF'
{
    "registry-mirrors": [
        "https://docker.mirrors.ustc.edu.cn",
        "https://hub-mirror.c.163.com",
        "https://mirror.baidubce.com"
    ],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2"
}
EOF
    
    # 重启 Docker
    systemctl restart docker
    
    log_success "Docker 镜像加速配置完成"
}

# 配置 Docker 用户组
setup_docker_group() {
    log_info "配置 Docker 用户组..."
    
    # 创建 docker 组（如果不存在）
    if ! getent group docker > /dev/null; then
        groupadd docker
    fi
    
    # 将当前用户加入 docker 组
    local current_user
    current_user=${SUDO_USER:-$USER}
    
    if [[ -n "$current_user" && "$current_user" != "root" ]]; then
        usermod -aG docker "$current_user"
        log_info "用户 $current_user 已加入 docker 组"
        log_warn "请注销并重新登录以应用权限更改"
    fi
    
    # 启动 Docker 服务
    systemctl enable docker
    systemctl start docker
    
    log_success "Docker 用户组配置完成"
}

# 验证 Docker 安装
verify_docker() {
    log_info "验证 Docker 安装..."
    
    # 检查版本
    local version
    version=$(docker --version)
    log_info "Docker 版本: $version"
    
    # 运行测试容器
    if docker run --rm hello-world > /dev/null 2>&1; then
        log_success "Docker 运行正常"
    else
        log_warn "Docker 测试容器运行失败，但安装可能已完成"
    fi
    
    # 检查 Docker Compose
    if docker compose version > /dev/null 2>&1; then
        log_info "Docker Compose 插件: $(docker compose version)"
    elif docker-compose version > /dev/null 2>&1; then
        log_info "Docker Compose: $(docker-compose version --short)"
    fi
}

# ============================================
# Docker Compose 配置管理
# ============================================

# 创建 Docker Compose 配置目录
init_compose_directory() {
    local compose_dir="${PIBOOT_DIR}/compose"
    
    ensure_dir "$compose_dir"
    
    log_debug "Docker Compose 目录: $compose_dir"
}

# 下载 Compose 模板
download_compose_template() {
    local service="$1"
    local output="$2"
    
    # 内置模板路径
    local template_dir="${SCRIPT_DIR}/../config/docker-compose"
    local template_file="${template_dir}/${service}.yml"
    
    if [[ -f "$template_file" ]]; then
        cp "$template_file" "$output"
        return 0
    fi
    
    # 尝试从 GitHub 下载
    local url="https://raw.githubusercontent.com/liushutao/piboot/main/config/docker-compose/${service}.yml"
    if download_file "$url" "$output"; then
        return 0
    fi
    
    log_error "找不到 $service 的 Compose 模板"
    return 1
}

# ============================================
# 卸载
# ============================================

uninstall_docker() {
    log_warn "正在卸载 Docker..."
    
    # 停止服务
    systemctl stop docker
    systemctl disable docker
    
    # 卸载包
    apt-get remove -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin docker-compose
    
    # 清理数据（可选）
    if ask_yes_no "是否删除所有 Docker 数据（容器、镜像、卷）" "N"; then
        rm -rf /var/lib/docker
        rm -rf /var/lib/containerd
    fi
    
    # 删除配置
    rm -f /etc/apt/sources.list.d/docker.list
    rm -f /etc/apt/keyrings/docker.gpg
    rm -rf /etc/docker
    
    log_success "Docker 已卸载"
}

# ============================================
# 模块主入口
# ============================================

# 完整安装流程
module_install() {
    log_info "开始安装 Docker..."
    
    # 检查是否已安装
    if is_docker_installed; then
        log_warn "Docker 已安装: $(get_docker_version)"
        if ! ask_yes_no "是否重新安装" "N"; then
            # 只配置镜像加速
            setup_docker_mirror
            return 0
        fi
        cleanup_old_docker
    fi
    
    # 安装步骤
    install_docker_dependencies
    add_docker_gpg_key
    add_docker_repository
    install_docker_engine
    install_docker_compose
    setup_docker_mirror
    setup_docker_group
    
    # 验证
    verify_docker
    
    log_success "Docker 安装完成！"
    log_info "使用 'docker ps' 查看运行中的容器"
    log_info "使用 'docker compose' 管理多容器应用"
}

# 快速配置（仅配置镜像加速）
module_quick_config() {
    if is_docker_installed; then
        setup_docker_mirror
        log_success "Docker 镜像加速配置完成"
    else
        log_error "Docker 未安装，请先安装"
        return 1
    fi
}

# 模块主入口
module_main() {
    local action="${1:-install}"
    
    case $action in
        install|setup)
            module_install
            ;;
        uninstall|remove)
            uninstall_docker
            ;;
        config|mirror)
            module_quick_config
            ;;
        status)
            if is_docker_installed; then
                log_info "Docker 已安装: $(get_docker_version)"
                docker system df
            else
                log_info "Docker 未安装"
            fi
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
