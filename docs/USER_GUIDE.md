# Caddy App User Guide

Welcome to Caddy App! This guide will help you get started with running and managing your Caddy web server.

## Table of Contents

1. [What is Caddy App?](#what-is-caddy-app)
2. [Getting Started](#getting-started)
3. [Dashboard Overview](#dashboard-overview)
4. [Configuration](#configuration)
5. [Secrets Management](#secrets-management)
6. [Log Viewer](#log-viewer)
7. [Common Use Cases](#common-use-cases)
8. [Troubleshooting](#troubleshooting)

---

## What is Caddy App?

Caddy App is a cross-platform application that lets you run and manage a [Caddy web server](https://caddyserver.com/) directly on your device. No terminal or command-line knowledge required!

**Key Features:**
- 🚀 **One-tap server start/stop** - Simple controls for server lifecycle
- ⚙️ **Visual configuration** - GUI for routes, TLS, and storage settings
- 🔒 **Secure secrets** - Platform-native encrypted storage for API tokens
- 📊 **Real-time logs** - Color-coded log viewer with search and filtering
- 💾 **Config presets** - Save and switch between multiple configurations
- 🔄 **Hot reload** - Update config without downtime
- 🌐 **HTTPS support** - Automatic TLS with Let's Encrypt via DNS challenges
- ☁️ **S3 storage** - Certificate persistence across devices

**Supported Platforms:**
- Linux (desktop)
- macOS (desktop)
- Android (mobile)
- iOS (coming soon)

---

## Getting Started

### First Launch

1. **Launch the app** - You'll see the home screen with server status
2. **Navigate to Dashboard** - Tap "Caddy Server" card or use the navigation menu
3. **Start the server** - Tap the "Start" button with default configuration
4. **Check status** - The server should show "Running" with an uptime counter

### Quick Start: Serve Static Files

1. Go to **Configuration** screen
2. In the **Visual Editor** tab:
   - Set **Listen Address**: `localhost:8080`
   - Add a route:
     - Path: `/*`
     - Handler: **Static File Server**
     - Root: `/path/to/your/files` (e.g., `/Users/you/Documents/site`)
3. Tap **Apply** to start/reload the server
4. Open your browser to `http://localhost:8080`

### Quick Start: Reverse Proxy

1. Go to **Configuration** screen
2. In the **Visual Editor** tab:
   - Set **Listen Address**: `localhost:8080`
   - Add a route:
     - Path: `/*`
     - Handler: **Reverse Proxy**
     - Upstreams: `localhost:3000` (your app's port)
3. Tap **Apply**
4. Caddy will proxy requests to your backend app

---

## Dashboard Overview

The **Dashboard** is your main control center.

### Status Card

Shows the current server state:
- **Stopped** - Server is not running
- **Running** - Server is active (shows uptime since start)
- **Error** - Server encountered a problem (tap to view details)

### Action Buttons

- **Start** - Launches the server with current configuration
- **Stop** - Gracefully shuts down the server
- **Reload** - Hot-reloads configuration without downtime (only when running)

### Metrics (when running)

- **Requests Handled** - Total HTTP requests processed
- **Active Routes** - Number of configured routes
- **Error Count** - Log entries with ERROR level
- **Admin API** - Status of admin endpoint (localhost:2019)

### Settings

- **Admin API** - Toggle the Caddy admin API (for advanced management)
- **Auto-restart on Resume** - Automatically restart server when app returns to foreground

### Keyboard Shortcuts (Desktop)

- **Ctrl+S** - Start server
- **Ctrl+Q** - Stop server
- **Ctrl+R** - Reload server

---

## Configuration

The **Configuration** screen has two modes: **Visual Editor** and **Raw JSON**.

### Visual Editor

User-friendly interface for building configurations.

#### Listen Address

The network address Caddy binds to:
- `localhost:2015` - Local access only, port 2015 (default)
- `:8080` - All interfaces, port 8080
- `:80` - HTTP (requires root/admin on Linux/macOS)
- `:443` - HTTPS (requires TLS configuration)

**Tip:** Use `localhost` for development, `:80`/`:443` for production.

#### Routes

Routes define how Caddy handles requests. Each route has:
- **Path** - URL pattern (e.g., `/*`, `/api/*`, `/static/*`)
- **Handler** - What to do with requests

**Handlers:**

1. **Static File Server**
   - Serves files from a directory
   - **Root**: Filesystem path (e.g., `/var/www/html`)
   - Use case: Websites, SPAs, file hosting

2. **Reverse Proxy**
   - Forwards requests to upstream servers
   - **Upstreams**: Backend addresses (one per line)
   - Example: `localhost:3000`, `backend1.local:8080`
   - Use case: API gateways, load balancing, microservices

**Route Order Matters:** Routes are evaluated top-to-bottom. Drag to reorder.

#### TLS Configuration

Enable automatic HTTPS with Let's Encrypt:

1. Toggle **Enable TLS**
2. Enter your **Domain** (e.g., `example.com`)
3. Select **DNS Provider**:
   - **Cloudflare** - Requires `CF_API_TOKEN` secret
   - **Route53** - Requires `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` secrets
   - **DuckDNS** - Requires `DUCKDNS_TOKEN` secret

**Note:** DNS challenge works on any network (no port 80/443 required).

#### S3 Storage

Store TLS certificates in S3-compatible storage:

1. Toggle **Enable S3 Storage**
2. Configure:
   - **Endpoint**: S3 API endpoint (e.g., `s3.amazonaws.com`)
   - **Bucket**: Bucket name
   - **Region**: AWS region (e.g., `us-east-1`)
   - **Prefix**: Key prefix (default: `caddy/`)
3. Add secrets: `caddy_AWS_ACCESS_KEY_ID`, `caddy_AWS_SECRET_ACCESS_KEY`

**Use case:** Share certificates across multiple devices/servers.

### Raw JSON Editor

For advanced users who want full control.

1. Switch to **Raw JSON** tab
2. Edit the Caddy JSON directly
3. Tap **Validate** to check syntax
4. Tap **Apply** to load configuration

**Tip:** Use the **Visual Editor** to generate base config, then switch to **Raw JSON** for fine-tuning.

### Configuration Presets

Built-in templates for common scenarios:

- **Static File Server** - Serve files from a directory
- **Reverse Proxy** - Forward to backend service
- **SPA Server** - Single-page app with index.html fallback
- **API Gateway** - Mixed static + proxied API routes
- **HTTPS with DNS** - TLS with DNS challenge
- **HTTPS with S3** - TLS + S3 certificate storage

**How to use:**
1. Tap **Presets** button
2. Select a preset
3. Customize settings
4. Save with a name

### Saving Configurations

1. Configure your server in the editor
2. Tap **Save** button
3. Enter a name (e.g., "Production", "Dev Server")
4. Configuration is stored and can be loaded later

**Switching Configs:**
1. Tap **Load** button
2. Select a saved configuration
3. Tap **Apply** to activate

### Comparing Configurations

When the server is running and you edit the config:
1. Tap **Reload** button
2. A **diff dialog** shows changes (old vs new)
3. Review changes before applying

---

## Secrets Management

Secrets (API tokens, passwords) are stored securely using platform-native encryption.

### Adding a Secret

1. Go to **Secrets** screen
2. Tap the **+** button
3. Enter:
   - **Key**: Secret name (e.g., `CF_API_TOKEN`)
   - **Value**: Secret value (hidden by default)
4. Tap **Save**

**Note:** The app automatically prefixes keys with `caddy_` internally.

### Using Secrets in Configuration

Secrets are injected as environment variables when the server starts.

**In your Caddy config**, reference secrets using `{env.VARIABLE_NAME}`:

```json
{
  "apps": {
    "tls": {
      "automation": {
        "policies": [{
          "issuers": [{
            "module": "acme",
            "challenges": {
              "dns": {
                "provider": {
                  "name": "cloudflare",
                  "api_token": "{env.CF_API_TOKEN}"
                }
              }
            }
          }]
        }]
      }
    }
  }
}
```

### Required Secrets by Feature

| Feature | Required Secrets |
|---------|------------------|
| Cloudflare DNS | `CF_API_TOKEN` |
| Route53 DNS | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` |
| DuckDNS | `DUCKDNS_TOKEN` |
| S3 Storage | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` |

### Editing/Deleting Secrets

- **Edit**: Tap the secret, update value, save
- **Delete**: Swipe left (mobile) or tap delete button (desktop)

**Security Note:** Secrets are stored in:
- **Linux**: Secret Service (GNOME Keyring, KWallet)
- **macOS**: Keychain
- **Android**: EncryptedSharedPreferences

---

## Log Viewer

Real-time view of Caddy server logs.

### Features

- **Color-coded levels**:
  - 🔴 **ERROR** - Red
  - 🟠 **WARN** - Orange
  - ⚪ **INFO** - Default
  - ⚪ **DEBUG** - Gray
- **Auto-scroll** - Automatically scroll to new entries (toggle off to review)
- **Search** - Filter logs by text
- **Level filter** - Show only specific log levels
- **Copy** - Long-press a log line to copy to clipboard
- **Export** - Save logs to a file

### Using the Log Viewer

1. Go to **Logs** screen
2. Logs appear in real-time as the server runs
3. Use **search bar** to find specific entries
4. Tap **filter icon** to select log level (ALL, DEBUG, INFO, WARN, ERROR)
5. Tap **clear** to empty the log buffer

### Understanding Logs

**Common log patterns:**

- `[INFO] admin admin endpoint started` - Admin API ready
- `[INFO] http.log.access handled request` - HTTP request processed
- `[ERROR] http.log.error` - Request handling error
- `[WARN] tls.obtain` - TLS certificate warning

**Request logs show:**
- HTTP method and path
- Status code
- Response size
- Duration

**Example:**
```
[INFO] http.log.access GET /index.html 200 2.5KB 15ms
```

---

## Common Use Cases

### Use Case 1: Local Development Server

**Scenario:** You're building a website and need a local server for testing.

**Steps:**
1. Go to **Configuration**
2. Use **Static File Server** preset
3. Set **Root** to your project folder (e.g., `/Users/you/mysite`)
4. Set **Listen Address** to `localhost:8080`
5. Tap **Apply**
6. Open `http://localhost:8080` in your browser

**Tip:** Enable **Auto-restart on Resume** so the server restarts when you return to the app.

---

### Use Case 2: Reverse Proxy for API Development

**Scenario:** Your frontend runs on port 3000, backend API on port 4000. You want both on one port.

**Steps:**
1. Go to **Configuration**
2. Use **API Gateway** preset
3. Configure:
   - **Listen Address**: `localhost:8080`
   - **Route 1**:
     - Path: `/api/*`
     - Handler: Reverse Proxy
     - Upstreams: `localhost:4000`
   - **Route 2**:
     - Path: `/*`
     - Handler: Reverse Proxy
     - Upstreams: `localhost:3000`
4. Tap **Apply**
5. Access frontend at `http://localhost:8080`, API at `http://localhost:8080/api`

---

### Use Case 3: HTTPS with Let's Encrypt

**Scenario:** You have a domain and want automatic HTTPS.

**Steps:**
1. Add secrets:
   - Go to **Secrets**
   - Add `CF_API_TOKEN` (get from Cloudflare dashboard)
2. Go to **Configuration**
3. Use **HTTPS with DNS** preset
4. Configure:
   - **Domain**: `yourdomain.com`
   - **DNS Provider**: Cloudflare
   - **Listen Address**: `:443`
   - Add your routes (static files or proxy)
5. Tap **Apply**
6. Caddy will automatically obtain and renew certificates!

**Requirements:**
- Domain registered and using Cloudflare nameservers
- Cloudflare API token with DNS edit permissions
- Port 443 accessible (if behind firewall)

---

### Use Case 4: Multi-Device Certificate Sharing

**Scenario:** You run Caddy on multiple devices and want to share TLS certificates.

**Steps:**
1. Set up an S3 bucket:
   - Create bucket (e.g., `my-caddy-certs`)
   - Note region and endpoint
2. Add secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
3. Go to **Configuration**
4. Use **HTTPS with S3** preset
5. Configure:
   - **Domain**: `yourdomain.com`
   - **DNS Provider**: Cloudflare (or your choice)
   - **S3 Endpoint**: `s3.amazonaws.com`
   - **S3 Bucket**: `my-caddy-certs`
   - **S3 Region**: `us-east-1`
6. Tap **Apply**
7. Repeat on other devices - they'll share certificates from S3!

**Benefits:**
- No duplicate certificate requests (rate limits)
- Instant certificate availability on new devices
- Automatic synchronization

---

### Use Case 5: Single-Page Application (SPA)

**Scenario:** You have a React/Vue/Angular app with client-side routing.

**Steps:**
1. Build your app (e.g., `npm run build` → `dist/` folder)
2. Go to **Configuration**
3. Use **SPA Server** preset
4. Set **Root** to your build folder (e.g., `/Users/you/myapp/dist`)
5. Set **Listen Address**: `localhost:8080`
6. Tap **Apply**
7. Navigate to any route - Caddy will serve `index.html` for all routes!

**Why this works:** The preset includes a fallback handler that returns `index.html` for non-file paths, enabling client-side routing.

---

### Use Case 6: Multiple Named Configurations

**Scenario:** You switch between development, staging, and production configs.

**Steps:**
1. Create **Development** config:
   - Configure for `localhost:8080` → `localhost:3000`
   - Save as "Development"
2. Create **Staging** config:
   - Configure for `:80` → `staging.example.com`
   - Save as "Staging"
3. Create **Production** config:
   - Configure for `:443` with TLS → `example.com`
   - Save as "Production"
4. Switch between configs:
   - Tap **Load** → Select config → **Apply**

**Tip:** Each config remembers admin API and other settings.

---

## Troubleshooting

### Problem: "Address already in use"

**Cause:** Another process is using the port.

**Solutions:**
1. **Change port**: Go to Configuration → Change Listen Address to a different port
2. **Stop other process**: Find and stop the conflicting process:
   - Linux/macOS: `sudo lsof -i :2015` (replace 2015 with your port)
   - Kill process: `sudo kill <PID>`
3. **Restart app**: Close and reopen Caddy App

---

### Problem: Server won't start with TLS

**Cause:** Missing secrets or incorrect DNS configuration.

**Check:**
1. **Secrets exist**: Go to Secrets → Verify required secrets are added
2. **Secret values correct**: Check for typos or expired tokens
3. **Domain valid**: Ensure domain uses your DNS provider's nameservers
4. **Check logs**: Go to Logs → Look for TLS-related errors

**Common TLS errors:**
- `acme: error presenting token` - DNS API credentials wrong
- `timeout` - DNS propagation delay (wait a few minutes)
- `too many certificates already issued` - Let's Encrypt rate limit (use staging or wait)

---

### Problem: Config changes not applied

**Cause:** Configuration validation failed.

**Check:**
1. Tap **Validate** button in Configuration screen
2. Review error message
3. Common issues:
   - Empty routes list
   - Invalid listen address format
   - Missing handler settings
   - Conflicting TLS settings

---

### Problem: High memory usage

**Cause:** Large log buffer.

**Solution:**
1. Go to **Logs** screen
2. Tap **Clear** button to empty buffer
3. Consider filtering logs to reduce entries

**Note:** Log buffer is limited to 10,000 entries automatically.

---

### Problem: Server doesn't auto-restart on resume

**Check:**
1. Go to **Dashboard**
2. Verify **Auto-restart on Resume** is enabled
3. Ensure a config was saved before backgrounding the app

**How it works:**
- When app is paused, current config is saved
- When app resumes, BLoC checks the setting
- If enabled, server restarts with saved config

---

### Problem: Can't access server from other devices

**Cause:** Using `localhost` address or firewall blocking.

**Solutions:**
1. **Change listen address**: Use `:8080` instead of `localhost:8080`
2. **Check firewall**: Allow the port through your firewall
   - Linux: `sudo ufw allow 8080`
   - macOS: System Preferences → Security → Firewall → Options
3. **Find device IP**: Use `ifconfig` (Linux/macOS) or `ipconfig` (Windows)
4. **Access from other device**: `http://<device-ip>:8080`

---

### Problem: Logs not showing

**Cause:** Log streaming not connected or filter too restrictive.

**Check:**
1. **Server is running**: Logs only stream when server is active
2. **Log filter**: Ensure filter is set to "ALL" or appropriate level
3. **Search query**: Clear search box if filtering by text
4. **Restart server**: Stop and start to reset log stream

---

### Problem: S3 storage not working

**Cause:** Incorrect credentials or bucket permissions.

**Check:**
1. **Secrets**: Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are correct
2. **Bucket exists**: Ensure bucket is created in specified region
3. **Permissions**: IAM user needs:
   - `s3:PutObject`
   - `s3:GetObject`
   - `s3:DeleteObject`
   - `s3:ListBucket`
4. **Endpoint**: Use correct S3 endpoint for your provider
   - AWS: `s3.amazonaws.com` or `s3.<region>.amazonaws.com`
   - MinIO: `http://<server>:9000`
   - DigitalOcean: `<region>.digitaloceanspaces.com`

---

### Problem: App crashes on start

**Cause:** Orphaned Caddy instance or database corruption.

**Solution:**
1. **Restart device**: Ensures no orphaned processes
2. **Clear app data** (Android):
   - Settings → Apps → Caddy App → Storage → Clear Data
   - **Warning:** This deletes saved configs and secrets!
3. **Reinstall app**: Last resort if corruption persists

---

### Getting Help

If you're still stuck:

1. **Check logs**: The Logs screen often reveals the issue
2. **Export logs**: Tap Export and share with support
3. **Check Caddy docs**: [caddyserver.com/docs](https://caddyserver.com/docs/)
4. **Report bug**: Open an issue on GitHub with:
   - Steps to reproduce
   - Exported logs
   - Platform and app version

---

## Tips & Best Practices

### Security

- ✅ **Use secrets for sensitive data** (never hardcode tokens in config)
- ✅ **Use `localhost` for development** (prevents external access)
- ✅ **Enable TLS in production** (automatic with Let's Encrypt)
- ❌ **Don't expose admin API publicly** (keep it on localhost:2019)
- ❌ **Don't commit exported configs with secrets** (use vault)

### Performance

- ✅ **Clear logs regularly** (prevents memory buildup)
- ✅ **Use specific log filters** (reduces buffer size)
- ✅ **Disable admin API if not needed** (saves resources)
- ❌ **Don't run on battery constantly** (server drains battery on mobile)

### Configuration Management

- ✅ **Name configs descriptively** ("Production API Gateway" vs "Config 1")
- ✅ **Use presets as starting points** (then customize)
- ✅ **Test configs before saving** (validate and check logs)
- ✅ **Export important configs** (backup to file)

### Development Workflow

- ✅ **Use auto-restart for dev** (convenient when switching apps)
- ✅ **Keep logs visible** (catch issues immediately)
- ✅ **Use reload instead of restart** (zero-downtime updates)
- ❌ **Don't run multiple instances** (causes port conflicts)

---

## Keyboard Shortcuts Reference

### Desktop Only

| Shortcut | Action |
|----------|--------|
| Ctrl+S | Start server |
| Ctrl+Q | Stop server |
| Ctrl+R | Reload server |

### All Platforms

| Action | Gesture |
|--------|---------|
| Copy log line | Long press / Right click |
| Reorder routes | Drag and drop |
| Delete secret | Swipe left (mobile) / Delete button (desktop) |

---

## Next Steps

Now that you're familiar with Caddy App, try:

1. **Explore presets** - Test different configuration templates
2. **Set up HTTPS** - Get a free Let's Encrypt certificate
3. **Save multiple configs** - Create profiles for different projects
4. **Monitor logs** - Watch your server in action
5. **Read Caddy docs** - Learn advanced Caddy features at [caddyserver.com](https://caddyserver.com/docs/)

Enjoy your portable web server! 🚀
