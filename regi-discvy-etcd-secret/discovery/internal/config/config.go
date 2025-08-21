package config

import (
	"os"
	"reflect"
	"strings"

	"github.com/zeromicro/go-zero/core/logx"
	"github.com/zeromicro/go-zero/zrpc"
)

type Config struct {
	zrpc.RpcServerConf
	RegistrationRpc zrpc.RpcClientConf `json:",optional"`
	Secret          Secret             `json:",optional"`
}

type Secret struct {
	SecretUser string `json:"secret_user" env:"SECRET_USER"`
	SecretPass string `json:"secret_pass" env:"SECRET_PASS"`
}

/*
LoadFromEnv 通用的环境变量加载函数，可以用于任何结构体
会递归处理嵌套结构体，并根据 env tag 从环境变量加载值
*/
func LoadFromEnv(config interface{}) {
	v := reflect.ValueOf(config)
	if v.Kind() != reflect.Ptr || v.Elem().Kind() != reflect.Struct {
		return
	}

	v = v.Elem()
	t := v.Type()

	for i := 0; i < v.NumField(); i++ {
		field := v.Field(i)
		fieldType := t.Field(i)

		if !field.CanSet() {
			continue
		}

		// 处理嵌套结构体
		if field.Kind() == reflect.Struct {
			LoadFromEnv(field.Addr().Interface())
			continue
		}

		// 只处理字符串类型的字段
		if field.Kind() != reflect.String {
			continue
		}

		// 获取 env tag
		envKey := fieldType.Tag.Get("env")
		if envKey == "" {
			// 如果没有 env tag，尝试根据字段名生成
			envKey = strings.ToUpper(fieldType.Name)
		}

		// 如果配置文件中的值为空，则从环境变量读取
		if field.String() == "" {
			if envValue := os.Getenv(envKey); envValue != "" {
				field.SetString(envValue)
				logx.Infof("LoadFromEnv: %s = %s", envKey, envValue)
			}
		}
	}
}
