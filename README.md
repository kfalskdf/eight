# eight

基于 sing-box 和 Cloudflare Tunnel 的 VPN 代理容器化方案。

## 功能特性

- sing-box 核心，支持 VLESS 协议
- Cloudflare Tunnel 持久化访问
- Nezha Agent 监控支持（可选）
- Docker 容器化部署
- 支持 x86_64 架构

## 快速开始

### 1. 拉取镜像

```bash
docker pull ghcr.io/kfalskdf/eight:latest
```

### 2. 运行容器

```bash
docker run -d \
  --name eight \
  -e uuid=your-uuid \
  -e token=your-cloudflare-token \
  -e domain=your-domain \
  -p 2777:2777 \
  ghcr.io/kfalskdf/eight:latest
```

## 环境变量

| 变量 | 必填 | 说明 | 默认值 |
|------|------|------|--------|
| `uuid` | 否 | VLESS UUID，不填则自动生成 | 自动生成 |
| `token` | 否 | Cloudflare Tunnel Token | - |
| `domain` | 否 | Cloudflare Tunnel 固定域名 | - |
| `nezha_server` | 否 | Nezha 服务器地址 | - |
| `nezha_key` | 否 | Nezha 密钥 | - |
| `node_name` | 否 | 节点显示名称 | `cf_tunnel` |

## 使用说明

### 临时隧道模式

不填写 `token` 和 `domain` 时，使用 Cloudflare 临时隧道：

```bash
docker run -d \
  --name eight \
  ghcr.io/kfalskdf/eight:latest
```

### 固定隧道模式

填写 `token` 和 `domain` 使用固定域名：

```bash
docker run -d \
  --name eight \
  -e uuid=your-uuid \
  -e token=your-cloudflare-token \
  -e domain=your-domain \
  ghcr.io/kfalskdf/eight:latest
```

### 配合 Nezha 监控

```bash
docker run -d \
  --name eight \
  -e uuid=your-uuid \
  -e token=your-cloudflare-token \
  -e domain=your-domain \
  -e nezha_server=nezha.example.com:443 \
  -e nezha_key=your-nezha-key \
  ghcr.io/kfalskdf/eight:latest
```

## 客户端配置

获取容器日志中的节点链接，或通过订阅获取：

```bash
curl http://localhost:2777/sub
```

## 构建镜像

```bash
docker build -t eight .
```

## 许可证

MIT
