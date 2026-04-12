//go:build !android && !ios

package main

import "C"
import (
	"encoding/json"
	"os"
	"sync"

	"github.com/caddyserver/caddy/v2"
	"github.com/caddyserver/caddy/v2/caddyconfig"
)

var (
	isRunning bool
	mu        sync.RWMutex
)

//export SetEnvironment
func SetEnvironment(envJSON *C.char) *C.char {
	data := C.GoString(envJSON)
	var env map[string]string
	if err := json.Unmarshal([]byte(data), &env); err != nil {
		return C.CString(err.Error())
	}
	for k, v := range env {
		if err := os.Setenv(k, v); err != nil {
			return C.CString(err.Error())
		}
	}
	return C.CString("")
}

//export StartCaddy
func StartCaddy(configJSON *C.char) *C.char {
	cfg := C.GoString(configJSON)
	err := caddy.Load([]byte(cfg), true)
	if err != nil {
		return C.CString(err.Error())
	}
	mu.Lock()
	isRunning = true
	mu.Unlock()
	return C.CString("")
}

//export StopCaddy
func StopCaddy() *C.char {
	err := caddy.Stop()
	if err != nil {
		return C.CString(err.Error())
	}
	mu.Lock()
	isRunning = false
	mu.Unlock()
	return C.CString("")
}

//export ReloadCaddy
func ReloadCaddy(configJSON *C.char) *C.char {
	cfg := C.GoString(configJSON)
	err := caddy.Load([]byte(cfg), true)
	if err != nil {
		return C.CString(err.Error())
	}
	return C.CString("")
}

//export GetCaddyStatus
func GetCaddyStatus() *C.char {
	mu.RLock()
	running := isRunning
	mu.RUnlock()

	if !running {
		result, _ := json.Marshal(map[string]string{"status": "stopped"})
		return C.CString(string(result))
	}
	result, _ := json.Marshal(map[string]string{"status": "running"})
	return C.CString(string(result))
}

//export AdaptCaddyfile
func AdaptCaddyfile(caddyfileText *C.char) *C.char {
	adapter := caddyconfig.GetAdapter("caddyfile")
	if adapter == nil {
		errJSON, _ := json.Marshal(map[string]string{"error": "caddyfile adapter not registered"})
		return C.CString(string(errJSON))
	}
	result, _, err := adapter.Adapt([]byte(C.GoString(caddyfileText)), nil)
	if err != nil {
		errJSON, _ := json.Marshal(map[string]string{"error": err.Error()})
		return C.CString(string(errJSON))
	}
	return C.CString(string(result))
}

func main() {}
