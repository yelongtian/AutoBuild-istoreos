#!/bin/bash
# build.sh - 本地构建脚本
# 用于在本地环境构建iStoreOS固件

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 检查系统环境
check_environment() {
    info "检查系统环境..."
    
    # 检查操作系统
    if [ ! -f /etc/os-release ]; then
        error "不支持的操作系统"
    fi
    
    # 检查必要工具
    local required_tools=(
        "git" "make" "gcc" "g++" "autoconf" "automake" 
        "bison" "flex" "gettext" "libtool" "pkg-config"
        "python3" "perl" "unzip" "wget" "curl"
    )
    
    for tool in "${required_tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            error "缺少必要工具: $tool，请先安装"
        fi
    done
    
    info "系统环境检查完成"
}

# 安装依赖
install_dependencies() {
    info "安装依赖包..."
    
    if [ -f /etc/debian_version ]; then
        sudo apt update -y
        sudo apt install -y \
            ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
            bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext \
            gcc-multilib g++-multilib git gperf haveged help2man intltool libc6-dev-i386 \
            libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev \
            libncurses5-dev libncursesw5-dev libreadline-dev libssl-dev libtool lrzsz \
            mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python2.7 \
            python3 python3-pip libpython3-dev qemu-utils rsync scons squashfs-tools \
            subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev
    elif [ -f /etc/redhat-release ]; then
        sudo dnf groupinstall -y "Development Tools"
        sudo dnf install -y \
            ncurses-devel zlib-devel openssl-devel elfutils-libelf-devel \
            gcc gcc-c++ make bison flex gettext automake autoconf libtool \
            python3 perl unzip wget curl git
    else
        warning "不支持的Linux发行版，可能需要手动安装依赖"
    fi
    
    info "依赖包安装完成"
}

# 克隆源码
clone_source() {
    local repo_url="${1:-https://github.com/istoreos/istoreos.git}"
    local branch="${2:-main}"
    
    info "克隆iStoreOS源码..."
    
    if [ -d "istoreos" ]; then
        warning "源码目录已存在，将更新源码"
        cd istoreos
        git pull
        cd ..
    else
        git clone "$repo_url" --depth=1
    fi
    
    info "源码克隆完成"
}

# 更新feeds
update_feeds() {
    info "更新feeds..."
    
    cd istoreos
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    cd ..
    
    info "feeds更新完成"
}

# 加载配置
load_config() {
    info "加载配置文件..."
    
    if [ -f "config.sh" ]; then
        source config.sh
        info "使用自定义配置文件"
    else
        warning "未找到config.sh，使用默认配置"
    fi
    
    info "配置文件加载完成"
}

# 生成配置
generate_config() {
    info "生成配置文件..."
    
    cd istoreos
    
    # 基础配置
    echo "CONFIG_TARGET_rockchip=y" > .config
    echo "CONFIG_TARGET_rockchip_armv8=y" >> .config
    echo "CONFIG_TARGET_DEVICE_rockchip_armv8_DEVICE_firefly-rk3399=y" >> .config
    
    # 系统配置
    echo "CONFIG_BUSYBOX_CUSTOM=y" >> .config
    echo "CONFIG_TARGET_ROOTFS_SQUASHFS=y" >> .config
    echo "CONFIG_TARGET_ROOTFS_TARGZ=y" >> .config
    
    # 网络配置
    echo "CONFIG_PACKAGE_dnsmasq-full=y" >> .config
    echo "CONFIG_PACKAGE_ip6tables=y" >> .config
    echo "CONFIG_PACKAGE_iptables-mod-extra=y" >> .config
    
    # LuCI界面
    echo "CONFIG_PACKAGE_luci=y" >> .config
    echo "CONFIG_PACKAGE_luci-theme-argon=y" >> .config
    echo "CONFIG_PACKAGE_luci-app-istore=y" >> .config
    
    # 存储支持
    echo "CONFIG_PACKAGE_block-mount=y" >> .config
    echo "CONFIG_PACKAGE_kmod-fs-ext4=y" >> .config
    echo "CONFIG_PACKAGE_kmod-fs-ntfs=y" >> .config
    
    # 应用程序
    echo "CONFIG_PACKAGE_luci-app-samba4=y" >> .config
    echo "CONFIG_PACKAGE_luci-app-vsftpd=y" >> .config
    echo "CONFIG_PACKAGE_luci-app-ddns=y" >> .config
    
    make defconfig
    
    cd ..
    
    info "配置文件生成完成"
}

# 编译固件
build_firmware() {
    local jobs="${1:-$(nproc)}"
    
    info "开始编译固件，使用 $jobs 个核心..."
    
    cd istoreos
    
    # 下载源码
    make download -j$jobs
    
    # 编译固件
    make -j$jobs || make -j1 V=s
    
    cd ..
    
    info "固件编译完成"
}

# 打包产物
package_firmware() {
    info "打包固件产物..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local package_name="istoreos-rk3399-${timestamp}"
    
    mkdir -p "output/${package_name}"
    
    # 复制固件文件
    cp istoreos/bin/targets/rockchip/armv8/*.img* "output/${package_name}/" 2>/dev/null || true
    cp istoreos/bin/targets/rockchip/armv8/*.bin* "output/${package_name}/" 2>/dev/null || true
    
    # 创建说明文件
    cat > "output/${package_name}/firmware_info.txt" << EOF
iStoreOS固件信息
================

构建时间: $(date '+%Y-%m-%d %H:%M:%S')
目标平台: rockchip/armv8
硬件型号: 视美太rk3399IoT-3399E

默认配置:
- 管理IP: 192.168.100.1
- 用户名: root
- 密码: password
- WiFi名称: iStoreOS-RK3399-2.4G / iStoreOS-RK3399-5G
- WiFi密码: 无默认密码

包含功能:
- 基础路由功能
- LuCI Web管理界面
- Samba文件共享
- FTP服务器
- DDNS动态域名
- UPnP自动端口映射
EOF
    
    # 创建压缩包
    cd output
    zip -r "${package_name}.zip" "${package_name}/"
    tar -czf "${package_name}.tar.gz" "${package_name}/"
    cd ..
    
    info "固件打包完成"
    info "产物位置: output/${package_name}"
}

# 清理构建
clean_build() {
    info "清理构建环境..."
    
    if [ -d "istoreos" ]; then
        cd istoreos
        make clean || true
        cd ..
    fi
    
    info "构建环境清理完成"
}

# 显示帮助信息
show_help() {
    echo "iStoreOS本地构建脚本"
    echo "用法: $0 [选项] [命令]"
    echo
    echo "命令:"
    echo "  all             执行完整构建流程"
    echo "  check           检查系统环境"
    echo "  install-deps    安装依赖包"
    echo "  clone           克隆源码"
    echo "  update-feeds    更新feeds"
    echo "  config          生成配置"
    echo "  build           编译固件"
    echo "  package         打包产物"
    echo "  clean           清理构建"
    echo
    echo "选项:"
    echo "  -j <jobs>       指定编译核心数"
    echo "  -h              显示帮助信息"
    echo "  -v              显示版本信息"
    echo
    echo "示例:"
    echo "  $0 all -j 4        # 使用4个核心执行完整构建"
    echo "  $0 build -j 8       # 使用8个核心编译固件"
    echo "  $0 clean           # 清理构建环境"
}

# 主函数
main() {
    local command="all"
    local jobs=$(nproc)
    
    # 解析命令行参数
    while getopts "j:hv" opt; do
        case $opt in
            j)
                jobs="$OPTARG"
                ;;
            h)
                show_help
                exit 0
                ;;
            v)
                echo "iStoreOS构建脚本 v1.0"
                exit 0
                ;;
            \?)
                echo "无效选项: -$OPTARG" >&2
                show_help
                exit 1
                ;;
        esac
    done
    
    # 获取命令
    shift $((OPTIND-1))
    if [ $# -gt 0 ]; then
        command="$1"
    fi
    
    case $command in
        all)
            check_environment
            install_dependencies
            clone_source
            update_feeds
            load_config
            generate_config
            build_firmware "$jobs"
            package_firmware
            ;;
        check)
            check_environment
            ;;
        install-deps)
            install_dependencies
            ;;
        clone)
            clone_source
            ;;
        update-feeds)
            update_feeds
            ;;
        config)
            load_config
            generate_config
            ;;
        build)
            build_firmware "$jobs"
            ;;
        package)
            package_firmware
            ;;
        clean)
            clean_build
            ;;
        *)
            error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
    
    info "脚本执行完成"
}

# 启动主函数
main "$@"
