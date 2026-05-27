#!/bin/bash
# ==========================================
# Disney+ 解锁一键配置脚本 (基于 Cloudflare WARP)
# 模仿自 warp-google-unlock 风格
# ==========================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

# 检查 Root 权限
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[错误] 请使用 root 用户权限运行此脚本！${PLAIN}"
  exit 1
fi

echo -e "${GREEN}==========================================${PLAIN}"
echo -e "${GREEN}    开始配置 WARP 代理以解锁 Disney+      ${PLAIN}"
echo -e "${GREEN}==========================================${PLAIN}"

# 1. 安装基础依赖
echo -e "\n${YELLOW}[1/4] 正在更新包列表并安装必要依赖...${PLAIN}"
apt-get update -q
apt-get install -y curl gnupg lsb-release

# 2. 添加 Cloudflare 官方 GPG 密钥和源
echo -e "\n${YELLOW}[2/4] 正在添加 Cloudflare WARP 仓库...${PLAIN}"
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list

# 3. 安装 WARP 客户端
echo -e "\n${YELLOW}[3/4] 正在安装 Cloudflare WARP 客户端...${PLAIN}"
apt-get update -q
apt-get install -y cloudflare-warp

# 4. 配置并启动 WARP (SOCKS5 代理模式)
echo -e "\n${YELLOW}[4/4] 正在注册并配置 WARP SOCKS5 模式 (端口: 40000)...${PLAIN}"

# 兼容新老版本的注册命令
warp-cli --accept-tos register 2>/dev/null || warp-cli --accept-tos registration new

# 设置为本地代理模式，防止接管全局网络
warp-cli --accept-tos set-mode proxy
# 设置代理端口
warp-cli --accept-tos set-proxy-port 40000
# 连接 WARP
warp-cli --accept-tos connect

# 等待连接建立
echo "等待 WARP 建立连接..."
sleep 5

# 5. 状态检查
STATUS=$(warp-cli --accept-tos status | grep -i 'status' | awk '{print $3}')
if [[ "$STATUS" == *"Connected"* ]]; then
    echo -e "\n${GREEN}==========================================${PLAIN}"
    echo -e "${GREEN} [成功] Cloudflare WARP SOCKS5 代理已启动！${PLAIN}"
    echo -e "${GREEN} 本地监听地址: 127.0.0.1:40000            ${PLAIN}"
    echo -e "${GREEN}==========================================${PLAIN}"
    
    echo -e "\n${YELLOW}【重要：下一步配置指南】${PLAIN}"
    echo -e "脚本已建立好解锁隧道。请在您的 V2Ray / Xray 或 Sing-box 配置文件中，"
    echo -e "将以下 Disney+ 相关域名的流量路由至 SOCKS5 (127.0.0.1:40000)："
    echo -e "  - disneyplus.com"
    echo -e "  - bamgrid.com"
    echo -e "  - dssott.com"
    echo -e "  - disney.com"
    echo -e "  - disney-plus.net"
    echo -e "  - disneynow.com"
    echo -e "或直接在路由规则中使用 ${GREEN}geosite:disney${PLAIN}"
else
    echo -e "\n${RED}[失败] WARP 未能成功连接，请使用 'warp-cli status' 检查报错日志。${PLAIN}"
fi
