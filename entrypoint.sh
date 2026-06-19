#!/usr/bin/env bash
set -e

echo "启动warp-svc..."
warp-svc &
WARP_SVC_PID=$!

echo "等待 warp-svc 就绪..."
for i in $(seq 1 30); do
    if warp-cli --accept-tos status > /dev/null 2>&1; then
        break
    fi
    sleep 1
done
echo "服务 warp-svc 已就绪..."

if [ ! -f /var/lib/cloudflare-warp/reg.json ]; then
    echo "注册新 WARP 客户端..."
    yes | warp-cli --accept-tos registration new || {
        echo "注册失败，重试..."
        sleep 1
        yes | warp-cli --accept-tos registration new
    }

    echo "设置隧道协议为 MASQUE..."
    warp-cli --accept-tos tunnel protocol set MASQUE

    echo "设置代理模式..."
    warp-cli --accept-tos mode proxy

    echo "设置 SOCKS5 端口 1081..."
    warp-cli --accept-tos proxy port 1081

    if [ -n "$WARP_LICENSE_KEY" ]; then
        echo "正在应用 WARP+ 许可证..."
        warp-cli --accept-tos registration license "$WARP_LICENSE_KEY"
    fi
else
    echo "WARP 客户端已注册，跳过注册步骤"
fi

echo "正在连接 WARP..."
warp-cli --accept-tos connect

sleep 2
echo "WARP 连接状态："
warp-cli --accept-tos status || true

echo "WARP SOCKS5 代理已就绪（端口 1081）"
trap "echo '正在断开 WARP...'; warp-cli --accept-tos disconnect; exit 0" SIGTERM SIGINT

while true; do
    if ! pgrep -x warp-svc > /dev/null; then
        echo "错误：warp-svc 进程已退出"
        exit 1
    fi
    if ! warp-cli --accept-tos status 2>/dev/null | grep -q "Connected"; then
        echo "警告：WARP 未处于已连接状态，尝试重连..."
        warp-cli --accept-tos connect || true
    fi
    sleep 10
done
