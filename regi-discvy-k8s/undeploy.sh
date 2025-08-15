#!/bin/bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🗑️  开始清理 Discovery & Registration 服务部署...${NC}"

# 检查命名空间是否存在
if kubectl get namespace discovery-system > /dev/null 2>&1; then
    echo -e "${YELLOW}📦 删除 Registration 服务...${NC}"
    kubectl delete -f k8s/registration-deployment.yaml --ignore-not-found=true
    
    echo -e "${YELLOW}📦 删除 Discovery 服务...${NC}"
    kubectl delete -f k8s/discovery-deployment.yaml --ignore-not-found=true
    
    echo -e "${YELLOW}⚙️  删除配置...${NC}"
    kubectl delete -f k8s/configmaps.yaml --ignore-not-found=true
    
    echo -e "${YELLOW}🔐 删除 RBAC 配置...${NC}"
    kubectl delete -f k8s/rbac.yaml --ignore-not-found=true
    
    echo -e "${YELLOW}📦 删除命名空间...${NC}"
    kubectl delete -f k8s/namespace.yaml --ignore-not-found=true
    
    echo -e "${YELLOW}⏳ 等待资源清理完成...${NC}"
    kubectl wait --for=delete namespace/discovery-system --timeout=60s || true
else
    echo -e "${YELLOW}ℹ️  命名空间 discovery-system 不存在，无需清理${NC}"
fi

# 删除 Docker 镜像
echo -e "${YELLOW}🐳 清理 Docker 镜像...${NC}"
eval $(minikube docker-env)
docker rmi discovery:latest 2>/dev/null || echo -e "${YELLOW}ℹ️  镜像 discovery:latest 不存在${NC}"
docker rmi registration:latest 2>/dev/null || echo -e "${YELLOW}ℹ️  镜像 registration:latest 不存在${NC}"

echo -e "${GREEN}✅ 清理完成！${NC}" 