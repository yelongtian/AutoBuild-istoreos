#!/bin/bash
# diy-part2.sh - iStoreOS自定义脚本（第二部分）
# 适用于视美太rk3399IoT-3399E开发板

echo "开始执行diy-part2.sh脚本..."

# 检查是否在istoreos目录
if [ ! -d "istoreos" ]; then
    echo "错误：不在istoreos目录"
    exit 1
fi

cd istoreos

echo "当前目录：$(pwd)"

# 修改默认IP地址
echo "修改默认IP地址..."
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate

# 修改主机名
echo "修改主机名..."
sed -i 's/OpenWrt/iStoreOS-RK3399/g' package/base-files/files/bin/config_generate

# 修改默认时区
echo "修改默认时区..."
sed -i 's/UTC/CST-8/g' package/base-files/files/bin/config_generate
sed -i '/exit 0/d' package/base-files/files/etc/rc.local
echo 'echo "Asia/Shanghai" > /etc/timezone' >> package/base-files/files/etc/rc.local
echo 'exit 0' >> package/base-files/files/etc/rc.local

# 修改默认密码
echo "修改默认密码..."
# 默认密码：password
sed -i 's/root::0:0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' package/base-files/files/etc/shadow

# 配置WiFi
echo "配置WiFi..."
cat > package/base-files/files/etc/config/wireless << 'EOF'
config wifi-device 'radio0'
    option type 'mac80211'
    option path 'platform/soc/30000000.mmc/mmc_host/mmc1/mmc1:0001/mmc1:0001:1'
    option channel '11'
    option band '2g'
    option htmode 'HT20'
    option disabled '0'
    option country 'CN'

config wifi-iface 'default_radio0'
    option device 'radio0'
    option network 'lan'
    option mode 'ap'
    option ssid 'iStoreOS-RK3399-2.4G'
    option encryption 'none'

config wifi-device 'radio1'
    option type 'mac80211'
    option path 'platform/soc/30000000.mmc/mmc_host/mmc2/mmc2:0001/mmc2:0001:1'
    option channel '36'
    option band '5g'
    option htmode 'VHT80'
    option disabled '0'
    option country 'CN'

config wifi-iface 'default_radio1'
    option device 'radio1'
    option network 'lan'
    option mode 'ap'
    option ssid 'iStoreOS-RK3399-5G'
    option encryption 'none'
EOF

# 配置网络
echo "配置网络..."
cat > package/base-files/files/etc/config/network << 'EOF'
config interface 'loopback'
    option ifname 'lo'
    option proto 'static'
    option ipaddr '127.0.0.1'
    option netmask '255.0.0.0'

config globals 'globals'
    option ula_prefix 'fdca:3ba5:f479::/48'

config interface 'lan'
    option type 'bridge'
    option ifname 'eth0'
    option proto 'static'
    option ipaddr '192.168.100.1'
    option netmask '255.255.255.0'
    option ip6assign '60'
    option gateway '192.168.100.254'
    option dns '114.114.114.114 223.5.5.5'

config interface 'wan'
    option ifname 'eth1'
    option proto 'dhcp'
    option peerdns '0'
    option dns '114.114.114.114 223.5.5.5'

config interface 'wan6'
    option ifname 'eth1'
    option proto 'dhcpv6'
EOF

# 配置防火墙
echo "配置防火墙..."
cat > package/base-files/files/etc/config/firewall << 'EOF'
config defaults
    option syn_flood '1'
    option input 'ACCEPT'
    option output 'ACCEPT'
    option forward 'REJECT'

config zone
    option name 'lan'
    list network 'lan'
    option input 'ACCEPT'
    option output 'ACCEPT'
    option forward 'ACCEPT'

config zone
    option name 'wan'
    list network 'wan'
    list network 'wan6'
    option input 'REJECT'
    option output 'ACCEPT'
    option forward 'REJECT'
    option masq '1'
    option mtu_fix '1'

config forwarding
    option src 'lan'
    option dest 'wan'

config rule
    option name 'Allow-DHCP-Renew'
    option src 'wan'
    option proto 'udp'
    option dest_port '68'
    option target 'ACCEPT'
    option family 'ipv4'

config rule
    option name 'Allow-Ping'
    option src 'wan'
    option proto 'icmp'
    option icmp_type 'echo-request'
    option family 'ipv4'
    option target 'ACCEPT'

config rule
    option name 'Allow-IGMP'
    option src 'wan'
    option proto 'igmp'
    option family 'ipv4'
    option target 'ACCEPT'

config rule
    option name 'Allow-DHCPv6'
    option src 'wan'
    option proto 'udp'
    option src_ip 'fc00::/6'
    option dest_ip 'fc00::/6'
    option dest_port '546'
    option family 'ipv6'
    option target 'ACCEPT'

config rule
    option name 'Allow-MLD'
    option src 'wan'
    option proto 'icmp'
    option src_ip 'fe80::/10'
    list icmp_type '130/0'
    list icmp_type '131/0'
    list icmp_type '132/0'
    list icmp_type '143/0'
    option family 'ipv6'
    option target 'ACCEPT'

config rule
    option name 'Allow-ICMPv6-Input'
    option src 'wan'
    option proto 'icmp'
    list icmp_type 'echo-request'
    list icmp_type 'echo-reply'
    list icmp_type 'destination-unreachable'
    list icmp_type 'packet-too-big'
    list icmp_type 'time-exceeded'
    list icmp_type 'bad-header'
    list icmp_type 'unknown-header-type'
    list icmp_type 'router-solicitation'
    list icmp_type 'neighbour-solicitation'
    list icmp_type 'router-advertisement'
    list icmp_type 'neighbour-advertisement'
    option limit '1000/sec'
    option family 'ipv6'
    option target 'ACCEPT'

config rule
    option name 'Allow-ICMPv6-Forward'
    option src 'wan'
    option dest '*'
    option proto 'icmp'
    list icmp_type 'echo-request'
    list icmp_type 'echo-reply'
    list icmp_type 'destination-unreachable'
    list icmp_type 'packet-too-big'
    list icmp_type 'time-exceeded'
    list icmp_type 'bad-header'
    list icmp_type 'unknown-header-type'
    option limit '1000/sec'
    option family 'ipv6'
    option target 'ACCEPT'

config rule
    option name 'Allow-IPSec-ESP'
    option src 'wan'
    option dest 'lan'
    option proto 'esp'
    option target 'ACCEPT'

config rule
    option name 'Allow-ISAKMP'
    option src 'wan'
    option dest 'lan'
    option dest_port '500'
    option proto 'udp'
    option target 'ACCEPT'
EOF

# 配置系统
echo "配置系统..."
cat > package/base-files/files/etc/config/system << 'EOF'
config system
    option hostname 'iStoreOS-RK3399'
    option timezone 'CST-8'
    option ttylogin '0'
    option log_size '64'
    option urandom_seed '0'

config timeserver 'ntp'
    list server 'ntp.aliyun.com'
    list server 'ntp1.aliyun.com'
    list server 'ntp2.aliyun.com'
    option enable_server '0'

config led
    option name 'status'
    option sysfs 'rk3399:green:status'
    option trigger 'heartbeat'

config led
    option name 'wan'
    option sysfs 'rk3399:blue:wan'
    option trigger 'netdev'
    option dev 'eth1'
    option mode 'link tx rx'

config led
    option name 'lan'
    option sysfs 'rk3399:green:lan'
    option trigger 'netdev'
    option dev 'eth0'
    option mode 'link tx rx'
EOF

# 配置Samba
echo "配置Samba..."
mkdir -p package/base-files/files/etc/samba
cat > package/base-files/files/etc/samba/smb.conf << 'EOF'
[global]
    netbios name = iStoreOS
    display charset = UTF-8
    interfaces = 127.0.0.1/8 lo 192.168.100.0/24
    server string = iStoreOS Samba Server
    unix charset = UTF-8
    workgroup = WORKGROUP
    bind interfaces only = yes
    deadtime = 30
    domain master = no
    encrypt passwords = true
    enable core files = no
    guest account = root
    guest ok = yes
    invalid users = root
    local master = yes
    load printers = no
    map to guest = Bad User
    max protocol = SMB2
    min receivefile size = 16384
    null passwords = yes
    passdb backend = smbpasswd
    security = user
    smb passwd file = /etc/samba/smbpasswd
    socket options = TCP_NODELAY IPTOS_LOWDELAY
    syslog = 2
    use sendfile = yes
    writeable = yes

[共享]
    path = /mnt
    valid users = root
    read only = no
    guest ok = yes
    create mask = 0777
    directory mask = 0777
EOF

# 配置FTP
echo "配置FTP..."
cat > package/base-files/files/etc/vsftpd.conf << 'EOF'
anonymous_enable=YES
local_enable=YES
write_enable=YES
local_umask=022
anon_upload_enable=YES
anon_mkdir_write_enable=YES
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=YES
pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES
anon_root=/mnt
local_root=/mnt
EOF

echo "diy-part2.sh脚本执行完成"
