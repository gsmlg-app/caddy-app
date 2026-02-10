//go:build android || ios

package caddy_bridge

import (
	"encoding/json"

	"github.com/caddyserver/caddy/v2"
)

func StartCaddy(configJSON string) string {
	err := caddy.Load([]byte(configJSON), true)
	if err != nil {
		return err.Error()
	}
	return ""
}

func StopCaddy() string {
	err := caddy.Stop()
	if err != nil {
		return err.Error()
	}
	return ""
}

func ReloadCaddy(configJSON string) string {
	err := caddy.Load([]byte(configJSON), true)
	if err != nil {
		return err.Error()
	}
	return ""
}

func GetCaddyStatus() string {
	cfg := caddy.ActiveContext().Cfg
	if cfg == nil {
		result, _ := json.Marshal(map[string]string{"status": "stopped"})
		return string(result)
	}
	result, _ := json.Marshal(map[string]string{"status": "running"})
	return string(result)
}
