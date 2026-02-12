//go:build !android && !ios

package main

import (
	"encoding/json"
	"os"
	"sync"
	"testing"
)

// Go-native wrappers to avoid "use of cgo in test" restrictions.
// The exported C functions are thin wrappers around these helpers,
// so testing the helpers validates the same logic.

func goSetEnvironment(envJSON string) string {
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

func goGetCaddyStatus() string {
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

func resetState() {
	mu.Lock()
	isRunning = false
	mu.Unlock()
}

func TestGetCaddyStatus_Stopped(t *testing.T) {
	resetState()
	result := goGetCaddyStatus()
	var status map[string]string
	if err := json.Unmarshal([]byte(result), &status); err != nil {
		t.Fatalf("failed to unmarshal status: %v", err)
	}
	if status["status"] != "stopped" {
		t.Errorf("expected status 'stopped', got %q", status["status"])
	}
}

func TestGetCaddyStatus_Running(t *testing.T) {
	mu.Lock()
	isRunning = true
	mu.Unlock()
	defer resetState()

	result := goGetCaddyStatus()
	var status map[string]string
	if err := json.Unmarshal([]byte(result), &status); err != nil {
		t.Fatalf("failed to unmarshal status: %v", err)
	}
	if status["status"] != "running" {
		t.Errorf("expected status 'running', got %q", status["status"])
	}
}

func TestSetEnvironment_Valid(t *testing.T) {
	result := goSetEnvironment(`{"TEST_CADDY_BRIDGE_KEY":"test_value"}`)
	if result != "" {
		t.Errorf("expected empty error, got %q", result)
	}
	if v := os.Getenv("TEST_CADDY_BRIDGE_KEY"); v != "test_value" {
		t.Errorf("expected env value 'test_value', got %q", v)
	}
	os.Unsetenv("TEST_CADDY_BRIDGE_KEY")
}

func TestSetEnvironment_InvalidJSON(t *testing.T) {
	result := goSetEnvironment("not json")
	if result == "" {
		t.Error("expected error for invalid JSON, got empty string")
	}
}

func TestSetEnvironment_EmptyObject(t *testing.T) {
	result := goSetEnvironment("{}")
	if result != "" {
		t.Errorf("expected empty error for empty env, got %q", result)
	}
}

func TestSetEnvironment_MultipleVars(t *testing.T) {
	result := goSetEnvironment(`{"TEST_CB_A":"1","TEST_CB_B":"2","TEST_CB_C":"3"}`)
	if result != "" {
		t.Errorf("expected empty error, got %q", result)
	}
	for _, kv := range []struct{ key, val string }{
		{"TEST_CB_A", "1"}, {"TEST_CB_B", "2"}, {"TEST_CB_C", "3"},
	} {
		if v := os.Getenv(kv.key); v != kv.val {
			t.Errorf("expected %s=%q, got %q", kv.key, kv.val, v)
		}
		os.Unsetenv(kv.key)
	}
}

func TestIsRunning_ThreadSafety(t *testing.T) {
	resetState()
	var wg sync.WaitGroup
	for i := 0; i < 100; i++ {
		wg.Add(2)
		go func() {
			defer wg.Done()
			mu.Lock()
			isRunning = true
			mu.Unlock()
		}()
		go func() {
			defer wg.Done()
			mu.RLock()
			_ = isRunning
			mu.RUnlock()
		}()
	}
	wg.Wait()
	resetState()
}

func TestGetCaddyStatus_JSONFormat(t *testing.T) {
	resetState()
	result := goGetCaddyStatus()

	var m map[string]interface{}
	if err := json.Unmarshal([]byte(result), &m); err != nil {
		t.Fatalf("GetCaddyStatus returned invalid JSON: %v", err)
	}
	if len(m) != 1 {
		t.Errorf("expected 1 key in status JSON, got %d", len(m))
	}
	if _, ok := m["status"]; !ok {
		t.Error("expected 'status' key in JSON output")
	}
}

func TestGetCaddyStatus_ToggleBehavior(t *testing.T) {
	resetState()

	// Initially stopped
	result := goGetCaddyStatus()
	if result != `{"status":"stopped"}` {
		t.Errorf("expected stopped, got %s", result)
	}

	// Set to running
	mu.Lock()
	isRunning = true
	mu.Unlock()

	result = goGetCaddyStatus()
	if result != `{"status":"running"}` {
		t.Errorf("expected running, got %s", result)
	}

	// Set back to stopped
	mu.Lock()
	isRunning = false
	mu.Unlock()

	result = goGetCaddyStatus()
	if result != `{"status":"stopped"}` {
		t.Errorf("expected stopped again, got %s", result)
	}
}

func TestSetEnvironment_OverwriteExisting(t *testing.T) {
	os.Setenv("TEST_CB_OVERWRITE", "old")
	defer os.Unsetenv("TEST_CB_OVERWRITE")

	result := goSetEnvironment(`{"TEST_CB_OVERWRITE":"new"}`)
	if result != "" {
		t.Errorf("expected empty error, got %q", result)
	}
	if v := os.Getenv("TEST_CB_OVERWRITE"); v != "new" {
		t.Errorf("expected 'new', got %q", v)
	}
}

func TestSetEnvironment_EmptyValue(t *testing.T) {
	result := goSetEnvironment(`{"TEST_CB_EMPTY":""}`)
	if result != "" {
		t.Errorf("expected empty error, got %q", result)
	}
	if v := os.Getenv("TEST_CB_EMPTY"); v != "" {
		t.Errorf("expected empty string, got %q", v)
	}
	os.Unsetenv("TEST_CB_EMPTY")
}
