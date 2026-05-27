#!/usr/bin/env bash

# ==================================================
# Disney+ Unlock via Cloudflare WARP
# Author: ChatGPT
# Inspired by warp-google.sh
# ==================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PLAIN='\033[0m'

SERVICE_NAME="warp-disney"

check_root() {
    [[ $EUID -ne 0 ]] && echo -e "${RED}请使用 root 运行${PLAIN}" && exit 1
}

detect_os() {
    if [[ -f /etc/debian_version ]]; then
        OS="debian"
    elif [[ -f /etc/redhat-release ]]; then
        OS="centos"
    else
        echo -e "${RED}不支持的系统${PLAIN}"
        exit 1
    fi
}

install_warp() {
    echo -e "${GREEN}安装 Cloudflare WARP...${PLAIN}"

    if [[ "$OS" == "debian" ]]; then
        apt update
        apt install -y curl gnupg lsb-release iptables

        curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg \
            | gpg --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

        echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] \
https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" \
            > /etc/apt/sources.list.d/cloudflare-client.list

        apt update
        apt install -y cloudflare-warp

    else
        yum install -y curl epel-release
        rpm -ivh https://pkg.cloudflareclient.com/cloudflare-release-el8.rpm
        yum install -y cloudflare-warp
    fi

    warp-cli --accept-tos register
    warp-cli --accept-tos mode warp
    warp-cli --accept-tos connect

    sleep 5

    echo -e "${GREEN}WARP 已连接${PLAIN}"
}

create_routing() {

cat > /usr/local/bin/warp-disney-route.sh << 'EOF'
#!/usr/bin/env bash

DISNEY_DOMAINS=(
    disneyplus.com
    disney-plus.net
    disneyplus.disney.com
    bamgrid.com
    disney.api.edge.bamgrid.com
)

WARP_IF="CloudflareWARP"

for domain in "${DISNEY_DOMAINS[@]}"; do
    ips=$(dig +short $domain | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

    for ip in $ips; do
        ip rule add to $ip lookup main 2>/dev/null || true
    done
done

EOF

chmod +x /usr/local/bin/warp-disney-route.sh
}

create_service() {

cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=Disney+ WARP Route
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/warp-disney-route.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable ${SERVICE_NAME}
    systemctl start ${SERVICE_NAME}
}

check_unlock() {

    echo -e "${GREEN}检测 Disney+ 解锁状态...${PLAIN}"

    result=$(curl -s https://disney.api.edge.bamgrid.com/devices)

    if [[ "$result" == *"errors"* ]]; then
        echo -e "${RED}Disney+ 可能未解锁${PLAIN}"
    else
        echo -e "${GREEN}Disney+ 已解锁${PLAIN}"
    fi
}

uninstall_all() {

    systemctl stop ${SERVICE_NAME} 2>/dev/null || true
    systemctl disable ${SERVICE_NAME} 2>/dev/null || true

    rm -f /etc/systemd/system/${SERVICE_NAME}.service
    rm -f /usr/local/bin/warp-disney-route.sh

    warp-cli --accept-tos disconnect || true

    if [[ "$OS" == "debian" ]]; then
        apt remove -y cloudflare-warp
    else
        yum remove -y cloudflare-warp
    fi

    systemctl daemon-reload

    echo -e "${GREEN}卸载完成${PLAIN}"
}

show_status() {

    echo "------------------------"
    warp-cli --accept-tos status || true
    echo "------------------------"

    curl -s https://www.cloudflare.com/cdn-cgi/trace | grep warp

    echo "------------------------"

    check_unlock
}

install_all() {
    install_warp
    create_routing
    create_service
    check_unlock
}

main() {

    check_root
    detect_os

    case "$1" in
        install)
            install_all
            ;;
        uninstall)
            uninstall_all
            ;;
        status)
            show_status
            ;;
        *)
            echo "用法:"
            echo "bash warp-disney.sh install"
            echo "bash warp-disney.sh uninstall"
            echo "bash warp-disney.sh status"
            ;;
    esac
}

main "$@"
