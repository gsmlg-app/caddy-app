//go:build android || ios

package caddy_bridge

// Blank imports to register Caddy modules at init time.
// These modules are compiled into the gomobile library so that
// Caddy JSON config can reference them at runtime.
import (
	// DNS challenge providers for ACME TLS certificate issuance.
	_ "github.com/caddy-dns/cloudflare"
	_ "github.com/caddy-dns/duckdns"
	_ "github.com/caddy-dns/route53"

	// S3-compatible storage backend for TLS certificates and Caddy state.
	_ "github.com/ss098/certmagic-s3"
)
