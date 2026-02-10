.PHONY: android ios linux macos clean

LDFLAGS := -ldflags="-s -w"

android:
	gomobile bind -target=android $(LDFLAGS) -o build/caddy_bridge.aar ./

ios:
	gomobile bind -target=ios $(LDFLAGS) -o build/CaddyBridge.xcframework ./

linux:
	CGO_ENABLED=1 go build -buildmode=c-shared $(LDFLAGS) -o build/libcaddy_bridge.so ./

macos:
	CGO_ENABLED=1 go build -buildmode=c-shared $(LDFLAGS) -o build/libcaddy_bridge.dylib ./

clean:
	rm -rf build/
