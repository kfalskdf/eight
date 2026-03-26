# 基础镜像：Alpine 3.18.12
FROM alpine:3.18.12

# 替换为阿里云镜像源（若在国内，可大幅提高下载速度）
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 定义构建参数，保持与原构建一致
ARG TARGETARCH=amd64

# 设置环境变量
ENV SING_BOX_VERSION=1.9.5 \
    TARGETARCH=amd64 \
    TZ=Asia/Shanghai

# 安装必要软件包（与原 RUN 一致）
RUN apk update && \
    apk add --no-cache ca-certificates wget bash coreutils grep gawk tzdata && \
    rm -rf /var/cache/apk/*

# 下载并安装 cloudflared
RUN wget "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${TARGETARCH}" -O /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 下载并安装 sing-box
RUN wget "https://github.com/SagerNet/sing-box/releases/download/v${SING_BOX_VERSION}/sing-box-${SING_BOX_VERSION}-linux-${TARGETARCH}.tar.gz" -O sing-box.tar.gz && \
    tar -xzf sing-box.tar.gz && \
    mv "sing-box-${SING_BOX_VERSION}-linux-${TARGETARCH}/sing-box" /usr/local/bin/ && \
    chmod +x /usr/local/bin/sing-box && \
    rm -rf sing-box.tar.gz "sing-box-${SING_BOX_VERSION}-linux-${TARGETARCH}"

# 下载并安装 agent（放在 /usr/local/bin/）
RUN wget -O /usr/local/bin/agent https://amd64.ssss.nyc.mn/v1 && \
    chmod +x /usr/local/bin/agent

# 设置工作目录
WORKDIR /app

# 复制你的脚本（你需要确保 seven.sh 与 Dockerfile 在同一目录下）
COPY eight.sh .

# 给脚本添加执行权限
RUN chmod +x eight.sh

# 设置入口点
ENTRYPOINT ["/bin/bash", "./eight.sh"]
