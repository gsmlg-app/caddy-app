//go:build !android && !ios

package main

// Blank imports to register Caddy modules at init time.
// These modules are compiled into the shared library so that
// Caddy JSON config can reference them at runtime.
import (
	// Caddy standard modules (HTTP server, TLS, headers, reverse_proxy, etc.).
	_ "github.com/caddyserver/caddy/v2/modules/standard"

	// DNS challenge providers for ACME TLS certificate issuance.
	_ "github.com/caddy-dns/cloudflare"
	_ "github.com/caddy-dns/duckdns"
	_ "github.com/caddy-dns/route53"

	// S3-compatible storage backend for TLS certificates and Caddy state.
	_ "github.com/ss098/certmagic-s3"
)
