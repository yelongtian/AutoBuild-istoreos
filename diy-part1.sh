#!/bin/bash
# diy-part1.sh - iStoreOS自定义脚本（第一部分）
# 适用于视美太rk3399IoT-3399E开发板

echo "开始执行diy-part1.sh脚本..."

# 检查是否在istoreos目录
if [ ! -d "istoreos" ]; then
    echo "错误：不在istoreos目录"
    exit 1
fi

cd istoreos

echo "当前目录：$(pwd)"
echo "开始添加自定义源和包..."

# 添加额外的feed源
echo "添加自定义feed源..."

# 添加kenzok8的包
echo "src-git kenzok8 https://github.com/kenzok8/openwrt-packages.git" >> feeds.conf.default
echo "src-git small8 https://github.com/kenzok8/small-package.git" >> feeds.conf.default

# 添加immortalwrt的包
echo "src-git immortalwrt https://github.com/immortalwrt/packages.git" >> feeds.conf.default

# 添加istoreos官方包
echo "src-git istore https://github.com/istoreos/luci-app-istore.git" >> feeds.conf.default

# 添加主题包
echo "src-git themes https://github.com/rosywrt/luci-theme-rosy.git" >> feeds.conf.default

echo "feed源添加完成"

# 更新feeds
echo "更新feeds..."
./scripts/feeds update -a

echo "diy-part1.sh脚本执行完成"
