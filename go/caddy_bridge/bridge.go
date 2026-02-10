//go:build !android && !ios

package main

import "C"
import (
	"encoding/json"
	"os"

	"github.com/caddyserver/caddy/v2"
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
	return C.CString("")
}

//export StopCaddy
func StopCaddy() *C.char {
	err := caddy.Stop()
	if err != nil {
		return C.CString(err.Error())
	}
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
	cfg := caddy.ActiveContext().Cfg
	if cfg == nil {
		result, _ := json.Marshal(map[string]string{"status": "stopped"})
		return C.CString(string(result))
	}
	result, _ := json.Marshal(map[string]string{"status": "running"})
	return C.CString(string(result))
}

func main() {}
