//go:build android || ios

package caddy_bridge

import (
	"encoding/json"
	"os"
	"sync"

	"github.com/caddyserver/caddy/v2"
)

var (
	isRunning bool
	mu        sync.RWMutex
)

func SetEnvironment(envJSON string) string {
	var env map[string]string
	if err := json.Unmarshal([]byte(envJSON), &env); err != nil {
		return err.Error()
	}
	for k, v := range env {
		if err := os.Setenv(k, v); err != nil {
			return err.Error()
		}
	}
	return ""
}

func StartCaddy(configJSON string) string {
	err := caddy.Load([]byte(configJSON), true)
	if err != nil {
		return err.Error()
	}
	mu.Lock()
	isRunning = true
	mu.Unlock()
	return ""
}

func StopCaddy() string {
	err := caddy.Stop()
	if err != nil {
		return err.Error()
	}
	mu.Lock()
	isRunning = false
	mu.Unlock()
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
	mu.RLock()
	running := isRunning
	mu.RUnlock()

	if !running {
		result, _ := json.Marshal(map[string]string{"status": "stopped"})
		return string(result)
	}
	result, _ := json.Marshal(map[string]string{"status": "running"})
	return string(result)
}
