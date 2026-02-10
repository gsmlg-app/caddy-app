.PHONY: android ios linux macos clean tidy

LDFLAGS := -ldflags="-s -w"

# Custom Caddy modules are registered via blank imports in modules.go
# and modules_mobile.go. This is equivalent to xcaddy --with flags but
# works with both cgo (desktop) and gomobile (mobile) build modes.

tidy:
	go mod tidy

android: tidy
	gomobile bind -target=android $(LDFLAGS) -o build/caddy_bridge.aar ./

ios: tidy
	gomobile bind -target=ios $(LDFLAGS) -o build/CaddyBridge.xcframework ./

linux: tidy
	CGO_ENABLED=1 go build -buildmode=c-shared $(LDFLAGS) -o build/libcaddy_bridge.so ./

macos: tidy
	CGO_ENABLED=1 go build -buildmode=c-shared $(LDFLAGS) -o build/libcaddy_bridge.dylib ./

clean:
	rm -rf build/
