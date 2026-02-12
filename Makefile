.PHONY: help setup bridge-linux bridge-macos bridge-android bridge-test \
       build-linux build-macos test analyze format clean

GO_BRIDGE := go/caddy_bridge

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Install tools and bootstrap workspace
	dart pub global activate melos
	dart pub global activate mason_cli
	melos bootstrap
	mason get

# --- Go bridge targets ---

bridge-linux: ## Build Go bridge for Linux (.so)
	$(MAKE) -C $(GO_BRIDGE) linux

bridge-macos: ## Build Go bridge for macOS (.dylib)
	$(MAKE) -C $(GO_BRIDGE) macos

bridge-android: ## Build Go bridge for Android (.aar)
	$(MAKE) -C $(GO_BRIDGE) android

bridge-test: ## Run Go bridge unit tests
	$(MAKE) -C $(GO_BRIDGE) test

bridge-clean: ## Clean Go bridge build artifacts
	$(MAKE) -C $(GO_BRIDGE) clean

# --- Flutter build targets ---

build-linux: bridge-linux ## Build Flutter app for Linux (includes Go bridge)
	mkdir -p linux/libs
	cp $(GO_BRIDGE)/build/libcaddy_bridge.so linux/libs/
	flutter build linux --release

build-macos: bridge-macos ## Build Flutter app for macOS (includes Go bridge)
	mkdir -p macos/libs
	cp $(GO_BRIDGE)/build/libcaddy_bridge.dylib macos/libs/
	flutter build macos --release

# --- Quality targets ---

test: ## Run all Flutter/Dart tests
	melos run test

analyze: ## Run static analysis
	melos run analyze

format: ## Format all code
	melos run format

format-check: ## Check formatting (CI)
	melos run format-check

# --- Combined targets ---

prepare: setup ## Full setup: bootstrap + gen-l10n + build-runner
	melos run prepare

ci: analyze test ## Run CI checks locally (analyze + test)

clean: bridge-clean ## Clean all build artifacts
	flutter clean
