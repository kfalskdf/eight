# =====================================================================
# 阶段 1：从 Cloudflare 官方镜像中取 cloudflared
# 用官方发布的镜像作为来源，版本由 tag 固定，无需自行下载与校验
# =====================================================================
FROM cloudflare/cloudflared:2026.9.3 AS cloudflared

# =====================================================================
# 阶段 2：运行镜像
# =====================================================================
# 基础镜像：Alpine 3.24.2（当前稳定分支；3.18 已于 2025-05 EOL）
FROM alpine:3.24.2

# TARGETARCH 由 buildx 自动注入（amd64 / arm64）。
# 不要用 ENV 覆盖它，否则多架构构建会失效（始终拿到 amd64 二进制）。
ARG TARGETARCH

# sing-box 固定版本的官方 SHA256（来源：v1.14.2 release 资产 digest 字段）
ARG SING_BOX_SHA256_AMD64=a684484d7477d1437282ee411f4d131d0340aaad60a7868841ebd5d87dd8a0c6
ARG SING_BOX_SHA256_ARM64=b43a1fb1bda131c6653576741ce527eb2bdeab7c9308ca90ee8b972abb7e4a7f

# Nezha Agent 版本（官方仓库 nezhahq/agent，构建时用官方 checksums.txt 校验）
ARG NEZHA_AGENT_VERSION=2.3.5

# 设置环境变量
ENV SING_BOX_VERSION=1.14.2 \
    TZ=Asia/Shanghai

# 安装必要软件包（判断是否国内IP，选择对应镜像源）
# 注意：此步骤必须发生在 apk add 之前，而此镜像里只有 busybox 自带的 wget、没有 curl，
#       所以用 wget 探测（原写法用 curl，命令不存在导致条件恒为 false，镜像源从未切换过）。
RUN set -eux; \
    if wget -q -O - -T 5 http://ip-api.com/json 2>/dev/null | grep -q '"countryCode":"CN"'; then \
        sed -i 's|dl-cdn.alpinelinux.org|mirrors.aliyun.com|g' /etc/apk/repositories; \
    fi; \
    apk add --no-cache ca-certificates wget bash coreutils grep gawk tzdata curl gcompat unzip; \
    rm -rf /var/cache/apk/*

# 设置工作目录
WORKDIR /app

# cloudflared：直接复制官方镜像里的二进制
# 版本锁定在阶段 1 的 FROM tag 上，不再使用 releases/latest（构建可复现、可回溯）
COPY --from=cloudflared /usr/local/bin/cloudflared /usr/local/bin/cloudflared

# sing-box：固定版本 + SHA256 校验
RUN set -eux; \
    arch="${TARGETARCH:-amd64}"; \
    case "${arch}" in \
        amd64) expected="${SING_BOX_SHA256_AMD64}" ;; \
        arm64) expected="${SING_BOX_SHA256_ARM64}" ;; \
        *) echo "不支持的架构: ${arch}"; exit 1 ;; \
    esac; \
    url="https://github.com/SagerNet/sing-box/releases/download/v${SING_BOX_VERSION}/sing-box-${SING_BOX_VERSION}-linux-${arch}.tar.gz"; \
    wget -nv -t 3 -O /tmp/sing-box.tar.gz "${url}"; \
    echo "${expected}  /tmp/sing-box.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/sing-box.tar.gz -C /tmp; \
    mv "/tmp/sing-box-${SING_BOX_VERSION}-linux-${arch}/sing-box" /usr/local/bin/sing-box; \
    chmod +x /usr/local/bin/sing-box; \
    rm -rf /tmp/sing-box.tar.gz "/tmp/sing-box-${SING_BOX_VERSION}-linux-${arch}"

# Nezha Agent：改用官方仓库 + 官方 checksums.txt 校验
# （原写法从第三方域名 amd64.ssss.nyc.mn/v1 下载重打包的二进制，来源不可信且无校验）
RUN set -eux; \
    arch="${TARGETARCH:-amd64}"; \
    zipname="nezha-agent_linux_${arch}.zip"; \
    base="https://github.com/nezhahq/agent/releases/download/v${NEZHA_AGENT_VERSION}"; \
    wget -nv -t 3 -O "/tmp/${zipname}" "${base}/${zipname}"; \
    wget -nv -t 3 -O /tmp/nezha-checksums.txt "${base}/checksums.txt"; \
    (cd /tmp && grep " ${zipname}\$" nezha-checksums.txt | sha256sum -c -); \
    unzip -q -o "/tmp/${zipname}" -d /tmp/nezha-extract; \
    mv /tmp/nezha-extract/nezha-agent /usr/local/bin/agent; \
    chmod +x /usr/local/bin/agent; \
    rm -rf /tmp/nezha-extract "/tmp/${zipname}" /tmp/nezha-checksums.txt

# 复制你的脚本（你需要确保 eight.sh 与 Dockerfile 在同一目录下）
COPY eight.sh .

# 给脚本添加执行权限
RUN chmod +x eight.sh

# 设置入口点
ENTRYPOINT ["/bin/bash", "./eight.sh"]
