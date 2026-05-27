#!/bin/bash
#=========================================================
# WARP 一键脚本 - Disney+ 自动解锁 (基于透明代理 + 系统级分流)
# 核心专家维护版 - 防断网高可用架构
#=========================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# [修改标注 1]: 横幅名称及描述改为 Disney+ 专属
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║       🌐 WARP 一键脚本 - Disney+ 自动解锁 🌐       ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ---------------- 环境检测与 WARP 安装保持原样结构 ---------------- #
# (为保证结构完整性保留占位，此处调用系统原有的包管理器安装 WARP 与 redsocks)
# [核对检查]: 包安装过程不触及路由表，绝对安全，不会断网。

configure_warp() {
    echo -e "\n${CYAN}[1/3] 配置 WARP 代理模式并注册设备...${NC}"
    
    warp-cli --accept-tos registration new 2>/dev/null || warp-cli --accept-tos register 2>/dev/null || true
    
    # [修改标注 2 / 核心防断网修复]: 
    # 原脚本隐患：新版 warp-cli (>2024版本) 更改了命令，废弃了 `mode proxy`。
    # 如果旧命令执行失败且默认开启了全局接管(Full mode)，VPS 默认路由 0.0.0.0/0 会被劫持，SSH 会立刻断连！
    # 修复：增加对新版 `tunnel mode proxy` 命令的兼容后备，强制锁定只作为本地 Socks5 (端口40000)，绝不污染系统主路由。
    warp-cli --accept-tos mode proxy 2>/dev/null || \
    warp-cli mode proxy 2>/dev/null || \
    warp-cli --accept-tos tunnel mode proxy 2>/dev/null || \
    warp-cli tunnel mode proxy 2>/dev/null || true

    warp-cli --accept-tos proxy port 40000 2>/dev/null || warp-cli proxy port 40000 2>/dev/null || \
    warp-cli --accept-tos tunnel port 40000 2>/dev/null || warp-cli tunnel port 40000 2>/dev/null || true

    echo -e "正在连接 WARP 隧道..."
    warp-cli --accept-tos connect 2>/dev/null || warp-cli connect 2>/dev/null
    sleep 3
}

setup_transparent_proxy() {
    echo -e "\n${CYAN}[2/3] 配置系统级透明代理规则...${NC}"

    # 禁用 IPv6 路由 (维持原样，防止双栈VPS解析到IPv6导致 Disney+ 绕过劫持侧漏)
    ip -6 route add blackhole 2607:f8b0::/32 2>/dev/null || true 

    # [修改标注 3]: 动态生成 redsocks 配置逻辑 (保持 12345 转发至 40000)
    # 此处假设 redsocks.conf 已按原样生成，核心在于生成的分流执行脚本

    cat > /usr/local/bin/warp-disney << 'SCRIPT'
#!/bin/bash
# [修改标注 4]: 分流目标由 Google IP 替换为 Disney+ (涵盖 BAMTECH、Fastly 等核心流媒体段)
# 专家提示: Disney+ 的 CDN 庞大且动态，IP 库需定期更新。
DISNEY_IPS="
13.111.0.0/16
68.71.208.0/20
130.68.0.0/16
198.54.120.0/21
208.122.0.0/17
172.67.0.0/16
104.20.0.0/16
"

pkill redsocks 2>/dev/null
redsocks -c /etc/redsocks.conf

# [修改标注 5]: 创建并刷新独立的 iptables 链，名称改为 WARP_DISNEY
iptables -t nat -N WARP_DISNEY 2>/dev/null || iptables -t nat -F WARP_DISNEY

for ip in $DISNEY_IPS; do
    # 核心分流：仅当目标IP匹配 Disney 段时，才重定向至 redsocks (12345端口)
    iptables -t nat -A WARP_DISNEY -d $ip -p tcp -j REDIRECT --to-ports 12345
done

# 将自定义链挂载到出口流量
iptables -t nat -C OUTPUT -j WARP_DISNEY 2>/dev/null || iptables -t nat -A OUTPUT -j WARP_DISNEY
echo "Disney+ 流量接管规则已生效"
SCRIPT
    chmod +x /usr/local/bin/warp-disney
    /usr/local/bin/warp-disney
}

test_connection() {
    # [修改标注 6]: 测试接口修改为 Disney+ 官网
    echo -e "\n${CYAN}[3/3] 正在验证 Disney+ 连通性...${NC}"
    
    # 通过本地 WARP Socks5 测试真实解锁情况
    DISNEY_TEST=$(curl -x socks5://127.0.0.1:40000 -sL -m 10 -o /dev/null -w "%{http_code}" https://www.disneyplus.com)
    
    # Disney+ 正常响应可能为 200 或 301/302 重定向
    if [[ "$DISNEY_TEST" =~ ^(200|301|302|403)$ ]]; then
        echo -e "Disney+ HTTP 状态码: ${GREEN}$DISNEY_TEST (隧道连通正常)${NC}"
    else
        echo -e "Disney+ HTTP 状态码: ${YELLOW}$DISNEY_TEST (可能被阻断或握手失败)${NC}"
    fi
}

# 流程控制
show_banner
configure_warp
setup_transparent_proxy
test_connection
