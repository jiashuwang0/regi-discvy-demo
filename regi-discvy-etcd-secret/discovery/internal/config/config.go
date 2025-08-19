package config

import (
	"os"

	"github.com/zeromicro/go-zero/zrpc"
)

type Config struct {
	zrpc.RpcServerConf
	RegistrationRpc zrpc.RpcClientConf `json:",optional"`
	Secret          Secret             `json:"secret"`
}

type Secret struct {
	SecretUser string `json:"secret_user"`
	SecretPass string `json:"secret_pass"`
}

func (s *Secret) Load() {
	s.SecretUser = os.Getenv("SECRET_USER")
	s.SecretPass = os.Getenv("SECRET_PASS")
}
