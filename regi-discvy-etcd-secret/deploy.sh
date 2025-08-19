#!/bin/bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 开始在 minikube 中部署 Discovery & Registration 服务${NC}"

# 检查 minikube 是否运行
echo -e "${YELLOW}📋 检查 minikube 状态...${NC}"
if ! minikube status > /dev/null 2>&1; then
    echo -e "${RED}❌ minikube 未运行，请先启动 minikube${NC}"
    echo "运行: minikube start"
    exit 1
fi

# 设置 minikube docker 环境
echo -e "${YELLOW}🔧 配置 Docker 环境...${NC}"
eval $(minikube docker-env)

# 构建 Discovery 服务镜像
echo -e "${YELLOW}🏗️  构建 Discovery 服务镜像...${NC}"
cd discovery
docker build -t discvy-etcd:latest .
cd ..

# 构建 Registration 服务镜像
echo -e "${YELLOW}🏗️  构建 Registration 服务镜像...${NC}"
cd registration
docker build -t regi-etcd:latest .
cd ..

# 创建命名空间
echo -e "${YELLOW}📦 创建 Kubernetes 资源...${NC}"
kubectl apply -f k8s/namespace.yaml

# 部署配置
echo -e "${YELLOW}⚙️  部署配置...${NC}"
kubectl apply -f k8s/configmaps.yaml

# 部署 RBAC 配置
echo -e "${YELLOW}🔐 部署 RBAC 配置...${NC}"
kubectl apply -f k8s/rbac.yaml

# 等待 RBAC 配置生效
echo -e "${YELLOW}⏳ 等待 RBAC 配置生效...${NC}"
sleep 5

# 部署 ETCD
echo -e "${YELLOW}🗄️  部署 ETCD...${NC}"
kubectl apply -f k8s/etcd-deployment.yaml

# 等待 ETCD 启动
echo -e "${YELLOW}⏳ 等待 ETCD 启动...${NC}"
kubectl wait --for=condition=available --timeout=120s deployment/etcd -n base

# 部署 Registration 服务
echo -e "${YELLOW}📝 部署 Registration 服务...${NC}"
kubectl apply -f k8s/registration-deployment.yaml

# 部署 Discovery 服务
echo -e "${YELLOW}🔍 部署 Discovery 服务...${NC}"
kubectl apply -f k8s/discovery-deployment.yaml

# 等待服务就绪
echo -e "${YELLOW}⏳ 等待服务就绪...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/discovery -n discvy-etcd
kubectl wait --for=condition=available --timeout=300s deployment/registration -n regi-etcd

# 获取服务信息
echo -e "${GREEN}✅ 部署完成！${NC}"
echo -e "${GREEN}📋 服务信息:${NC}"

# 获取 NodePort
DISCOVERY_NODEPORT=$(kubectl get svc discovery -n discvy-etcd -o jsonpath='{.spec.ports[0].nodePort}')
REGISTRATION_NODEPORT=$(kubectl get svc registration -n regi-etcd -o jsonpath='{.spec.ports[0].nodePort}')
ETCD_NODEPORT=$(kubectl get svc etcd-external -n base -o jsonpath='{.spec.ports[0].nodePort}')
MINIKUBE_IP=$(minikube ip)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "🔍 Discovery 服务访问地址:     ${GREEN}${MINIKUBE_IP}:${DISCOVERY_NODEPORT}${NC}"
echo -e "📝 Registration 服务访问地址:  ${GREEN}${MINIKUBE_IP}:${REGISTRATION_NODEPORT}${NC}"
echo -e "🗄️  ETCD 服务访问地址:          ${GREEN}${MINIKUBE_IP}:${ETCD_NODEPORT}${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "📊 Kubernetes Dashboard: ${YELLOW}minikube dashboard${NC}"
echo -e "🔍 查看 Discovery Pod 状态: ${YELLOW}kubectl get pods -n discvy-etcd${NC}"
echo -e "🔍 查看 Registration Pod 状态: ${YELLOW}kubectl get pods -n regi-etcd${NC}"
echo -e "📝 查看 Discovery 日志: ${YELLOW}kubectl logs -f deployment/discovery -n discvy-etcd${NC}"
echo -e "📝 查看 Registration 日志: ${YELLOW}kubectl logs -f deployment/registration -n regi-etcd${NC}"
echo -e "🗄️  查看 ETCD 日志: ${YELLOW}kubectl logs -f deployment/etcd -n base${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 显示 Pod 状态
echo -e "${YELLOW}📋 当前 Pod 状态:${NC}"
echo -e "${YELLOW}Discovery 服务:${NC}"
kubectl get pods -n discvy-etcd -o wide
echo -e "${YELLOW}Registration 服务:${NC}"
kubectl get pods -n regi-etcd -o wide

echo ""
echo -e "${GREEN}🎉 部署完成！${NC}"
echo -e "${GREEN}💡 使用示例:${NC}"
echo -e "  Discovery 服务:     grpcurl -plaintext ${MINIKUBE_IP}:${DISCOVERY_NODEPORT} list"
echo -e "  Registration 服务:  grpcurl -plaintext ${MINIKUBE_IP}:${REGISTRATION_NODEPORT} list" 