# Discovery & Registration 服务 Minikube 部署指南

这个项目演示了如何将基于 go-zero 框架的两个独立 gRPC 服务（Discovery 和 Registration）部署到本地的 minikube 环境中。

## 前置条件

在开始部署之前，请确保您的系统中已安装以下工具：

- [Docker](https://docs.docker.com/get-docker/)
- [minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## 项目架构

```
📦 service-regi-discvy
├── 📁 discovery/                 # Discovery 服务
│   ├── 🐳 Dockerfile            # Discovery Docker 构建文件
│   ├── 📄 discovery.go          # 主程序
│   ├── 📄 discovery.proto       # gRPC 定义
│   └── 📁 etc/                  # 配置文件
├── 📁 registration/             # Registration 服务
│   ├── 🐳 Dockerfile            # Registration Docker 构建文件
│   ├── 📄 registration.go       # 主程序
│   ├── 📄 registration.proto    # gRPC 定义
│   └── 📁 etc/                  # 配置文件
├── 📁 k8s/                      # Kubernetes 配置文件
│   ├── namespace.yaml           # 命名空间
│   ├── configmaps.yaml          # 两个服务的配置
│   ├── discovery-deployment.yaml    # Discovery 服务部署
│   └── registration-deployment.yaml # Registration 服务部署
├── 🚀 deploy.sh                 # 一键部署脚本
├── 🗑️ undeploy.sh               # 一键清理脚本
└── 📖 README.md                 # 本文档
```

## 服务说明

### 🔍 Discovery 服务
- **端口**: 8080
- **NodePort**: 30080
- **功能**: 服务发现相关功能

### 📝 Registration 服务  
- **端口**: 8080 (容器内)
- **NodePort**: 30081
- **功能**: 服务注册相关功能

## 快速开始

### 1. 启动 minikube

```bash
# 启动 minikube
minikube start

# 验证状态
minikube status
```

### 2. 一键部署

```bash
# 给脚本添加执行权限
chmod +x deploy.sh

# 执行部署
./deploy.sh
```

部署脚本会自动完成以下步骤：
- ✅ 检查 minikube 状态
- 🏗️ 构建 Discovery 服务 Docker 镜像
- 🏗️ 构建 Registration 服务 Docker 镜像
- 📦 创建 Kubernetes 命名空间
- ⚙️ 部署服务配置
- 🔍 部署 Discovery 服务 (2 个副本)
- 📝 部署 Registration 服务 (2 个副本)
- ⏳ 等待所有服务就绪

### 3. 验证部署

部署完成后，您将看到类似以下的输出：

```
🔍 Discovery 服务访问地址:     192.168.49.2:30080
📝 Registration 服务访问地址:  192.168.49.2:30081
```

## 服务访问

两个服务都通过 NodePort 暴露，您可以通过以下方式访问：

```bash
# 获取 minikube IP
MINIKUBE_IP=$(minikube ip)

# 服务地址
echo "Discovery 服务: $MINIKUBE_IP:30080"
echo "Registration 服务: $MINIKUBE_IP:30081"
```

## 监控和管理

### 查看服务状态

```bash
# 查看所有资源
kubectl get all -n discovery-system

# 查看 Pod 详情
kubectl describe pods -n discovery-system

# 查看 Discovery 服务日志
kubectl logs -f deployment/discovery -n discovery-system

# 查看 Registration 服务日志
kubectl logs -f deployment/registration -n discovery-system
```

### 扩容服务

```bash
# 扩容 Discovery 服务到 3 个副本
kubectl scale deployment discovery --replicas=3 -n discovery-system

# 扩容 Registration 服务到 3 个副本
kubectl scale deployment registration --replicas=3 -n discovery-system
```

### 使用 Kubernetes Dashboard

```bash
# 启动 Dashboard
minikube dashboard
```

## 服务配置

服务配置通过 ConfigMap 管理，配置文件路径：`k8s/configmaps.yaml`

### Discovery 服务配置
- `Name`: discovery.rpc
- `ListenOn`: 0.0.0.0:8080
- `Mode`: dev (无需 etcd)

### Registration 服务配置
- `Name`: registration.rpc
- `ListenOn`: 0.0.0.0:0
- `Mode`: dev (无需 etcd)

## 服务发现

两个服务都提供了 Headless Service 用于集群内服务发现：
- `discovery-headless.discovery-system.svc.cluster.local:8080`
- `registration-headless.discovery-system.svc.cluster.local:8080

## 故障排查

### 常见问题

1. **Pod 启动失败**
   ```bash
   kubectl describe pod <pod-name> -n discovery-system
   kubectl logs <pod-name> -n discovery-system
   ```

2. **镜像构建问题**
   - 确保运行了 `eval $(minikube docker-env)`
   - 确保镜像构建成功：
     ```bash
     docker images | grep discovery
     docker images | grep registration
     ```

3. **端口冲突**
   - Discovery: 30080
   - Registration: 30081
   - 确保这些端口未被占用

### 重新部署

如果需要重新部署，可以先清理现有资源：

```bash
# 清理所有资源
./undeploy.sh

# 重新部署
./deploy.sh
```

## gRPC 客户端测试

您可以使用以下工具测试 gRPC 服务：

### 使用 grpcurl

```bash
# 安装 grpcurl
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

# 测试 Discovery 服务
grpcurl -plaintext $MINIKUBE_IP:30080 list
grpcurl -plaintext -d '{"ping": "hello"}' $MINIKUBE_IP:30080 discovery.Discovery/Ping

# 测试 Registration 服务
grpcurl -plaintext $MINIKUBE_IP:30081 list
grpcurl -plaintext -d '{"ping": "hello"}' $MINIKUBE_IP:30081 registration.Registration/Ping
```

### 使用 Go 客户端

参考对应服务目录中的客户端代码：
- `discovery/discoveryclient/`
- `registration/registrationclient/`

## 清理资源

当不再需要服务时，可以一键清理所有资源：

```bash
# 给脚本添加执行权限
chmod +x undeploy.sh

# 执行清理
./undeploy.sh
```

清理脚本会删除：
- 所有 Kubernetes 资源（两个服务的部署、配置、服务等）
- Docker 镜像（discovery:latest, registration:latest）
- 命名空间

## 技术栈

- **后端框架**: go-zero
- **协议**: gRPC
- **服务发现**: Kubernetes 原生
- **容器化**: Docker
- **编排**: Kubernetes
- **本地环境**: minikube

## 架构优势

1. **微服务架构**: Discovery 和 Registration 独立部署和扩展
2. **无状态设计**: 移除了对外部 etcd 的依赖
3. **云原生**: 使用 Kubernetes 原生服务发现
4. **高可用**: 每个服务运行 2 个副本，支持负载均衡
5. **易于维护**: 独立的 Docker 镜像和部署配置

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目！

## 许可证

本项目采用 MIT 许可证。 