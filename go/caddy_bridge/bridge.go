//go:build !android && !ios

package main

import "C"
import (
	"encoding/json"

	"github.com/caddyserver/caddy/v2"
)

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
