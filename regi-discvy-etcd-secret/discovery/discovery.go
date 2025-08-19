package main

import (
	"context"
	"flag"
	"fmt"
	"time"

	"discovery/discovery"
	"discovery/internal/config"
	"discovery/internal/server"
	"discovery/internal/svc"
	"discovery/registration"

	"github.com/zeromicro/go-zero/core/conf"
	"github.com/zeromicro/go-zero/core/logx"
	"github.com/zeromicro/go-zero/core/service"
	"github.com/zeromicro/go-zero/zrpc"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

var configFile = flag.String("f", "etc/discovery.yaml", "the config file")

func main() {
	flag.Parse()

	var c config.Config
	conf.MustLoad(*configFile, &c)
	c.Secret.Load()
	ctx := svc.NewServiceContext(c)

	s := zrpc.MustNewServer(c.RpcServerConf, func(grpcServer *grpc.Server) {
		discovery.RegisterDiscoveryServer(grpcServer, server.NewDiscoveryServer(ctx))

		if c.Mode == service.DevMode || c.Mode == service.TestMode {
			reflection.Register(grpcServer)
		}
	})
	defer s.Stop()

	go Cron(c)

	logx.Infof("Starting rpc server at %s...", c.ListenOn)
	s.Start()
}

func Cron(c config.Config) {
	initRegistrationClient(c)
	ticker := time.NewTicker(10 * time.Second)

	for range ticker.C {
		resp, err := registrationClient.Ping(context.Background(), &registration.Request{
			Ping: "hello from discovery",
		})
		if err != nil {
			panic(err)
		}
		logx.Infof("Received pong: %s \nsecret: %s", resp.Pong, c.Secret.SecretUser+":"+c.Secret.SecretPass)
	}

}

var registrationClient registration.RegistrationClient

func initRegistrationClient(c config.Config) {
	conn, err := zrpc.NewClient(c.RegistrationRpc)
	logx.Infof("registrationRpc.Target: %s", c.RegistrationRpc.Target)
	if err != nil {
		fmt.Println("Failed to connect to registration server:", err)
		panic(err)
	}

	// 创建 registration 客户端
	registrationClient = registration.NewRegistrationClient(conn.Conn())

}
