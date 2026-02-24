#import "CaddyBridgeStubs.h"

// Stub implementations for CaddyBridge functions.
// These are used when the CaddyBridge.xcframework has not been built.
// Build the real framework with: make -C go/caddy_bridge ios

NSString* _Nullable CaddyBridgeStartCaddy(NSString* _Nullable configJSON) {
    return @"CaddyBridge not available: build xcframework with 'make -C go/caddy_bridge ios'";
}

NSString* _Nullable CaddyBridgeStopCaddy(void) {
    return @"CaddyBridge not available: build xcframework with 'make -C go/caddy_bridge ios'";
}

NSString* _Nullable CaddyBridgeReloadCaddy(NSString* _Nullable configJSON) {
    return @"CaddyBridge not available: build xcframework with 'make -C go/caddy_bridge ios'";
}

NSString* _Nullable CaddyBridgeGetCaddyStatus(void) {
    return @"{\"status\":\"unavailable\"}";
}

NSString* _Nullable CaddyBridgeSetEnvironment(NSString* _Nullable envJSON) {
    return @"CaddyBridge not available: build xcframework with 'make -C go/caddy_bridge ios'";
}
