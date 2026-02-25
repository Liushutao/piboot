#!/bin/bash
# lib/core.sh - PiBoot 核心函数库
# 提供日志、系统检测、工具函数等基础功能

set -e

# ============================================
# 常量定义
# ============================================

# 版本号（如果没定义则使用默认值）
PIBOOT_VERSION="${PIBOOT_VERSION:-1.0.0}"
PIBOOT_RELEASE_DATE="${PIBOOT_RELEASE_DATE:-2025-02-25}"

# 颜色定义
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_PURPLE='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_NC='\033[0m' # No Color

# 日志级别
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3
readonly LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# 路径定义
readonly PIBOOT_DIR="${HOME}/.piboot"
readonly PIBOOT_CONFIG_DIR="${PIBOOT_DIR}/config"
readonly PIBOOT_LOG_DIR="${PIBOOT_DIR}/logs"
readonly PIBOOT_BACKUP_DIR="${PIBOOT_DIR}/backups"
readonly PIBOOT_MODULES_DIR="${PIBOOT_DIR}/modules"

# ============================================
# 日志函数
# ============================================

# 打印带时间戳的日志
_log() {
    local level="$1"
    local color="$2"
    local message="$3"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${color}[${timestamp}] [${level}]${COLOR_NC} ${message}"
    
    # 同时写入日志文件
    if [[ -d "$PIBOOT_LOG_DIR" ]]; then
        echo "[${timestamp}] [${level}] ${message}" >> "${PIBOOT_LOG_DIR}/piboot.log"
    fi
}

# 调试日志
log_debug() {
    if [[ $LOG_LEVEL -le $LOG_LEVEL_DEBUG ]]; then
        _log "DEBUG" "$COLOR_CYAN" "$1"
    fi
}

# 信息日志
log_info() {
    if [[ $LOG_LEVEL -le $LOG_LEVEL_INFO ]]; then
        _log "INFO" "$COLOR_GREEN" "$1"
    fi
}

# 警告日志
log_warn() {
    if [[ $LOG_LEVEL -le $LOG_LEVEL_WARN ]]; then
        _log "WARN" "$COLOR_YELLOW" "$1"
    fi
}

# 错误日志
log_error() {
    if [[ $LOG_LEVEL -le $LOG_LEVEL_ERROR ]]; then
        _log "ERROR" "$COLOR_RED" "$1"
    fi
}

# 成功信息
log_success() {
    echo -e "${COLOR_GREEN}✓${COLOR_NC} $1"
}

# 失败信息
log_fail() {
    echo -e "${COLOR_RED}✗${COLOR_NC} $1"
}

# ============================================
# 系统检测函数
# ============================================

# 检查是否以 root 运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "请使用 sudo 运行此脚本"
        echo "例如: sudo ./install.sh"
        return 1
    fi
    log_debug "Root 权限检查通过"
    return 0
}

# 检查是否在 Raspberry Pi 上运行
check_raspberry_pi() {
    local model=""
    
    if [[ -f /proc/device-tree/model ]]; then
        model=$(tr -d '\0' < /proc/device-tree/model)
        log_debug "检测到硬件: $model"
        
        if [[ "$model" == *"Raspberry Pi"* ]]; then
            # 提取型号
            if [[ "$model" == *"Raspberry Pi 5"* ]]; then
                echo "pi5"
            elif [[ "$model" == *"Raspberry Pi 4"* ]]; then
                echo "pi4"
            elif [[ "$model" == *"Raspberry Pi 3"* ]]; then
                echo "pi3"
            else
                echo "pi"
            fi
            return 0
        fi
    fi
    
    # 备用检测方法
    if [[ -f /proc/cpuinfo ]]; then
        if grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
            echo "pi"
            return 0
        fi
    fi
    
    echo "unknown"
    return 1
}

# 获取详细的硬件信息
get_hardware_info() {
    local info=""
    
    # 型号
    if [[ -f /proc/device-tree/model ]]; then
        info="Model: $(tr -d '\0' < /proc/device-tree/model)\n"
    fi
    
    # 内存
    if [[ -f /proc/meminfo ]]; then
        local mem_kb
        mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        local mem_gb=$((mem_kb / 1024 / 1024))
        info+="Memory: ${mem_gb}GB\n"
    fi
    
    # CPU 信息
    if [[ -f /proc/cpuinfo ]]; then
        local cores
        cores=$(grep -c processor /proc/cpuinfo)
        info+="CPU Cores: $cores\n"
    fi
    
    # 温度
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        local temp
        temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        local temp_c=$((temp / 1000))
        info+="Temperature: ${temp_c}°C\n"
    fi
    
    echo -e "$info"
}

# 检测操作系统
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
        return 0
    fi
    echo "unknown"
    return 1
}

# 获取系统版本
get_os_version() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$VERSION_ID"
        return 0
    fi
    echo "unknown"
    return 1
}

# 获取完整 OS 信息
get_os_info() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$NAME $VERSION_ID"
        return 0
    fi
    echo "Unknown OS"
    return 1
}

# ============================================
# 网络相关函数
# ============================================

# 检查网络连接
check_network() {
    local timeout=3
    local test_hosts=("223.5.5.5" "114.114.114.114" "8.8.8.8")
    
    log_info "检查网络连接..."
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W "$timeout" "$host" >/dev/null 2>&1; then
            log_debug "网络连接正常 (通过 $host)"
            return 0
        fi
    done
    
    log_error "无法连接到网络"
    return 1
}

# 测试 DNS 解析
check_dns() {
    local test_domain="github.com"
    
    if nslookup "$test_domain" >/dev/null 2>&1 || \
       host "$test_domain" >/dev/null 2>&1 || \
       getent hosts "$test_domain" >/dev/null 2>&1; then
        log_debug "DNS 解析正常"
        return 0
    fi
    
    log_warn "DNS 解析可能有问题"
    return 1
}

# 获取本机 IP 地址
get_ip_address() {
    hostname -I | awk '{print $1}'
}

# 获取所有 IP 地址
get_all_ip_addresses() {
    hostname -I
}

# ============================================
# 命令和包管理
# ============================================

# 检查命令是否存在
cmd_exists() {
    command -v "$1" &> /dev/null
}

# 安装软件包（带错误处理）
install_package() {
    local package="$1"
    
    log_info "安装软件包: $package"
    
    if cmd_exists apt-get; then
        apt-get update -qq
        apt-get install -y -qq "$package" || {
            log_error "安装 $package 失败"
            return 1
        }
    elif cmd_exists yum; then
        yum install -y "$package" || {
            log_error "安装 $package 失败"
            return 1
        }
    elif cmd_exists pacman; then
        pacman -S --noconfirm "$package" || {
            log_error "安装 $package 失败"
            return 1
        }
    else
        log_error "不支持的包管理器"
        return 1
    fi
    
    log_success "$package 安装完成"
    return 0
}

# 安装多个软件包
install_packages() {
    local packages=("$@")
    local missing=()
    
    # 检查哪些包需要安装
    for pkg in "${packages[@]}"; do
        if ! dpkg -l "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        log_debug "所有软件包已安装"
        return 0
    fi
    
    log_info "安装软件包: ${missing[*]}"
    apt-get update -qq
    apt-get install -y -qq "${missing[@]}"
}

# ============================================
# 文件和目录操作
# ============================================

# 创建目录（如果不存在）
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_debug "创建目录: $dir"
    fi
}

# 备份文件
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup_name="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup_name"
        log_info "已备份: $file -> $backup_name"
        echo "$backup_name"
        return 0
    fi
    return 1
}

# 安全写入文件（先备份）
safe_write() {
    local file="$1"
    local content="$2"
    
    # 备份原文件
    if [[ -f "$file" ]]; then
        backup_file "$file"
    fi
    
    # 写入新内容
    echo "$content" > "$file"
    log_debug "写入文件: $file"
}

# 下载文件（带重试）
download_file() {
    local url="$1"
    local output="$2"
    local retries="${3:-3}"
    local count=0
    
    while [[ $count -lt $retries ]]; do
        if curl -fsSL -o "$output" "$url" 2>/dev/null || \
           wget -q -O "$output" "$url" 2>/dev/null; then
            log_debug "下载成功: $url"
            return 0
        fi
        
        count=$((count + 1))
        log_warn "下载失败，第 $count 次重试..."
        sleep 2
    done
    
    log_error "下载失败: $url"
    return 1
}

# ============================================
# 用户交互
# ============================================

# 询问是/否
ask_yes_no() {
    local question="$1"
    local default="${2:-Y}"
    local response
    
    if [[ "$default" == "Y" ]]; then
        read -r -p "$question [Y/n]: " response
        [[ -z "$response" || "$response" =~ ^[Yy]$ ]]
    else
        read -r -p "$question [y/N]: " response
        [[ "$response" =~ ^[Yy]$ ]]
    fi
}

# 询问输入
ask_input() {
    local prompt="$1"
    local default="$2"
    local response
    
    if [[ -n "$default" ]]; then
        read -r -p "$prompt [$default]: " response
        echo "${response:-$default}"
    else
        read -r -p "$prompt: " response
        echo "$response"
    fi
}

# 密码输入（隐藏）
ask_password() {
    local prompt="$1"
    local password
    
    read -r -s -p "$prompt: " password
    echo
    echo "$password"
}

# ============================================
# 系统服务管理
# ============================================

# 检查服务是否运行
is_service_running() {
    local service="$1"
    
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        return 0
    fi
    return 1
}

# 启动服务
start_service() {
    local service="$1"
    log_info "启动服务: $service"
    systemctl start "$service" || {
        log_error "启动 $service 失败"
        return 1
    }
    log_success "$service 已启动"
}

# 启用服务（开机自启）
enable_service() {
    local service="$1"
    log_info "启用服务: $service"
    systemctl enable "$service" || {
        log_error "启用 $service 失败"
        return 1
    }
    log_success "$service 已设为开机自启"
}

# 重启服务
restart_service() {
    local service="$1"
    log_info "重启服务: $service"
    systemctl restart "$service" || {
        log_error "重启 $service 失败"
        return 1
    }
    log_success "$service 已重启"
}

# ============================================
# 进度和状态显示
# ============================================

# 显示进度（用于循环中）
show_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-进度}"
    local percent=$((current * 100 / total))
    
    printf "\r%s: %3d%% (%d/%d)" "$message" "$percent" "$current" "$total"
    
    if [[ $current -eq $total ]]; then
        echo
    fi
}

# 显示分隔线
show_separator() {
    local char="${1:-=}"
    local width="${2:-60}"
    printf "%${width}s\n" | tr " " "$char"
}

# 显示标题
show_title() {
    local title="$1"
    show_separator
    echo -e "${COLOR_CYAN}${title}${COLOR_NC}"
    show_separator
}

# ============================================
# 初始化
# ============================================

# 初始化 PiBoot 环境
init_piboot() {
    log_info "初始化 PiBoot 环境..."
    
    # 创建必要的目录
    ensure_dir "$PIBOOT_DIR"
    ensure_dir "$PIBOOT_CONFIG_DIR"
    ensure_dir "$PIBOOT_LOG_DIR"
    ensure_dir "$PIBOOT_BACKUP_DIR"
    ensure_dir "$PIBOOT_MODULES_DIR"
    
    # 保存版本信息
    echo "$PIBOOT_VERSION" > "${PIBOOT_DIR}/version"
    
    log_success "PiBoot 环境初始化完成"
}

# 加载配置文件
load_config() {
    local config_file="${PIBOOT_CONFIG_DIR}/config.json"
    
    if [[ -f "$config_file" ]]; then
        cat "$config_file"
    else
        echo '{}'
    fi
}

# 保存配置文件
save_config() {
    local config="$1"
    local config_file="${PIBOOT_CONFIG_DIR}/config.json"
    
    echo "$config" > "$config_file"
    log_debug "配置已保存"
}

# ============================================
# 错误处理
# ============================================

# 错误退出
error_exit() {
    local code="${1:-1}"
    local message="${2:-未知错误}"
    
    log_error "$message"
    log_error "PiBoot 异常退出 (错误码: $code)"
    log_error "日志位置: ${PIBOOT_LOG_DIR}/piboot.log"
    
    exit "$code"
}

# 设置错误陷阱
set_error_trap() {
    trap 'error_exit $? "命令执行失败: $BASH_COMMAND (行号: $LINENO)"' ERR
}

# ============================================
# 模块加载
# ============================================

# 加载模块
load_module() {
    local module_name="$1"
    local module_path="${PIBOOT_MODULES_DIR}/${module_name}.sh"
    
    if [[ -f "$module_path" ]]; then
        source "$module_path"
        log_debug "加载模块: $module_name"
        return 0
    else
        log_error "模块不存在: $module_name"
        return 1
    fi
}

# 检查模块是否存在
module_exists() {
    local module_name="$1"
    [[ -f "${PIBOOT_MODULES_DIR}/${module_name}.sh" ]]
}
