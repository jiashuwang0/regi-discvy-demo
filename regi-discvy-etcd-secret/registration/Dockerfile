# 多阶段构建 - Registration 服务
FROM golang:1.23-alpine AS builder

# 设置 Go 代理和环境变量
ENV GOPROXY=https://goproxy.cn,direct
ENV GOSUMDB=sum.golang.google.cn
ENV GO111MODULE=on
ENV CGO_ENABLED=0

# 安装必要工具
RUN apk add --no-cache git ca-certificates

# 设置工作目录
WORKDIR /app

# 复制 go mod 文件
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制源代码
COPY . ./

# 构建应用
RUN GOOS=linux go build -o registration .

# 运行阶段
FROM alpine:latest

# 安装ca证书
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# 从builder阶段复制二进制文件
COPY --from=builder /app/registration .
COPY --from=builder /app/etc ./etc

# 暴露端口
EXPOSE 8080

# 运行应用
CMD ["./registration"] 