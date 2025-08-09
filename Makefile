.PHONY: help build test format check-fmt clean generate serve deploy install
.DEFAULT_GOAL := help

# Variables
BINARY_NAME := zstd-live
OUTPUT_DIR := dist
ZIG_OUT := zig-out
SRC_DIR := src

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build Zig application
	@echo "Building $(BINARY_NAME)..."
	@zig build

test: ## Run all tests
	@echo "Running tests..."
	@zig build test

format: ## Format all source code
	@echo "Formatting source code..."
	@zig build fmt

check-fmt: ## Check source code formatting
	@echo "Checking source code formatting..."
	@zig build check-fmt

clean: ## Clean build artifacts and generated documentation
	@echo "Cleaning build artifacts..."
	@rm -rf $(ZIG_OUT)
	@rm -rf ./.zig-cache
	@rm -rf $(OUTPUT_DIR)
	@echo "Clean completed."

install: build ## Install the binary to local bin directory
	@echo "Installing $(BINARY_NAME)..."
	@mkdir -p ~/.local/bin
	@cp $(ZIG_OUT)/bin/$(BINARY_NAME) ~/.local/bin/
	@echo "$(BINARY_NAME) installed to ~/.local/bin/"

generate: build ## Generate documentation for all supported Zig versions
	@echo "Generating documentation for all supported versions..."
	@./$(ZIG_OUT)/bin/$(BINARY_NAME) generate --all-versions --output $(OUTPUT_DIR)
	@echo "Documentation generated in $(OUTPUT_DIR)/"

generate-version: build ## Generate documentation for specific version
	@if [ -z "$(VERSION)" ]; then echo "Usage: make generate-version VERSION=0.14.1"; exit 1; fi
	@echo "Generating documentation for Zig $(VERSION)..."
	@./$(ZIG_OUT)/bin/$(BINARY_NAME) generate --version $(VERSION) --output $(OUTPUT_DIR)

serve: build ## Serve documentation locally on port 8080
	@echo "Starting local development server..."
	@./$(ZIG_OUT)/bin/$(BINARY_NAME) serve --port 8080

serve-port: build ## Serve documentation on custom port
	@if [ -z "$(PORT)" ]; then echo "Usage: make serve-port PORT=3000"; exit 1; fi
	@echo "Starting local development server on port $(PORT)..."
	@./$(ZIG_OUT)/bin/$(BINARY_NAME) serve --port $(PORT)

update: build ## Update Zig stdlib sources for all versions
	@echo "Updating Zig stdlib sources..."
	@./$(ZIG_OUT)/bin/$(BINARY_NAME) update

update-version: build ## Update specific Zig version
	@if [ -z "$(VERSION)" ]; then echo "Usage: make update-version VERSION=0.15.0-master"; exit 1; fi
	@echo "Updating Zig $(VERSION) stdlib sources..."
	@./$(ZIG_OUT)/bin/$(BINARY_NAME) update --version $(VERSION)

deploy: generate ## Deploy to Cloudflare Pages (requires environment setup)
	@echo "Deploying to Cloudflare Pages..."
	@echo "Note: This target is primarily for GitHub Actions. For manual deployment, push to main branch."

dev: build ## Full development setup: build, generate, and serve
	@echo "Setting up development environment..."
	@make generate
	@make serve

# Development helpers
watch: ## Watch for changes and rebuild (requires inotify-tools or similar)
	@echo "Watching for changes..."
	@while inotifywait -e modify -r $(SRC_DIR); do make build; done

check: check-fmt test ## Run all checks (format + tests)
	@echo "All checks passed!"

# Release helpers
release-check: clean check build generate ## Full release validation
	@echo "Release validation completed successfully!"
