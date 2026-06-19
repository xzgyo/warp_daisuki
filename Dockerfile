FROM debian:stable-slim

RUN printf '%s\n' \
        'Types: deb' \
        'URIs: http://mirrors.tuna.tsinghua.edu.cn/debian' \
        'Suites: stable stable-updates stable-backports' \
        'Components: main contrib non-free non-free-firmware' \
        'Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg' \
        '' \
        'Types: deb' \
        'URIs: http://mirrors.tuna.tsinghua.edu.cn/debian-security' \
        'Suites: stable-security' \
        'Components: main contrib non-free non-free-firmware' \
        'Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg' \
        > /etc/apt/sources.list.d/debian.sources && \
    apt update && apt upgrade -y && \
    apt install -y --no-install-recommends curl gnupg lsb-release iproute2 ca-certificates socat && \
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | \
        tee /etc/apt/sources.list.d/cloudflare-client.list && \
    apt update && \
    apt install -y --no-install-recommends cloudflare-warp && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 1080

ENTRYPOINT ["/entrypoint.sh"]
