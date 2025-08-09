# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## IMPORTANT

- PREFER British English over American English spelling and grammar
- Files and Directories MUST NOT have **dashes** in names/paths (Use **underscore** instead)
- NEVER use Git LFS
- ALWAYS run `make format` before `git commit` (uses `zig build fmt`)
- USE Emoji in [README.md](./README.md) or **docs/\*.md** with care. NOT MUCH.
- ALWAYS use `[x]` or `[ ]` instead of ✅ / 🔲 / for checkmarks
- NEVER use `[x]` or [ ]` in Markdown tables; USE ✅ / 🔲 / instead. **Reason**: it's not supported
- PREFER [GitHub Emoji API](https://api.github.com/emojis) over UTF Emoji
- ALWAYS add footer to new Markdown files with a AI generated content banner (!IMPORTANT)
- USE `zig fetch <url>` when add dependencies to build.zon
- ALWAYS run `make help` if you see a Makefile to learn targets and semantic of that subdirectory

## Project Overview

This is a Zig-native tool called "zstd-live" that generates live HTML documentation sites from Zig standard library source code. It creates a two-column layout inspired by docco.coffee, where the left column shows documentation and public identifiers, and the right column displays the raw Zig source code with syntax highlighting. The tool supports multiple Zig versions and converts `@import()` calls into clickable hyperlinks for navigation.

**Repository**: https://github.com/paaloeye/zstd-live
**Live Site**: https://zstd-live.pages.dev
**Hosting**: Cloudflare Pages (static)

## Build and Development Commands

### Core Build Commands
```bash
# Build Zig application
make build           # Preferred: uses Makefile wrapper
# OR: zig build       # Direct Zig build

# Run tests
make test            # Runs all unit tests
# OR: zig build test

# Format code (REQUIRED before commit)
make format          # Uses zig build fmt
# OR: zig build fmt

# Check formatting without modifying files
make check-fmt       # Uses zig build check-fmt
# OR: zig build check-fmt

# Run application with arguments
zig build run -- <args>

# Clean build artifacts
make clean           # Removes zig-out/ and dist/
```

### Documentation Generation
```bash
# Generate docs for all supported Zig versions
make generate                     # Builds first, then generates all versions

# Generate docs for specific version
make generate-version VERSION=0.14.1    # Requires VERSION parameter

# Generate docs for all versions (manual)
./zig-out/bin/zstd-live generate --all-versions --output ./dist

# Generate docs for specific version (manual)
./zig-out/bin/zstd-live generate --version 0.14.1 --output ./dist
```

### Development Server
```bash
# Serve docs locally on default port (8080)
make serve                        # Builds first, then serves

# Serve on custom port
make serve-port PORT=3000        # Requires PORT parameter

# Manual serve command
./zig-out/bin/zstd-live serve --port 8080
```

### Version Management
```bash
# Update Zig stdlib sources for all versions
make update                      # Updates all supported versions

# Update specific Zig version
make update-version VERSION=0.15.0-master

# Manual update command
./zig-out/bin/zstd-live update --version 0.15.0-master
```

### Development Workflow
```bash
# Full development setup: build + generate + serve
make dev                         # One-command development setup

# Complete validation (format check + tests + build + generate)
make release-check               # Full release validation

# Run all checks (format + tests)
make check                       # Quick validation

# Install to local bin (useful for testing)
make install                     # Installs to ~/.local/bin/
```

### Supported Zig Versions
Current versions defined in `src/config.zig`:
- `0.15.0-master` (latest development) - Downloads from GitHub master branch
- `0.14.1` (latest stable) - Downloads from GitHub tag 0.14.1
- `0.13.0` (stable) - Downloads from GitHub tag 0.13.0
- `0.12.0` (stable) - Downloads from GitHub tag 0.12.0
- `0.11.0` (stable) - Downloads from GitHub tag 0.11.0

**Adding New Versions**: Edit the `SUPPORTED_VERSIONS` array in `src/config.zig` with new `ZigVersion` structs containing `name`, `tag`, `url`, and `description` fields.

## Code Architecture

### Core Application Structure (Zig)
```
src/
├── main.zig             # CLI entry point with argument parsing
├── generator.zig        # Main documentation generator logic
├── parser.zig           # Zig source code parser
├── template.zig         # HTML template system
├── version_manager.zig  # Multi-version Zig stdlib support
├── file_utils.zig       # File operations and directory traversal
└── config.zig           # Configuration and version definitions
```

### Core Components

#### main.zig
CLI application entry point:
- **Argument parsing**: Handles version selection, output paths, commands
- **Command routing**: Routes to generation, serving, or update functions
- **Error handling**: Centralised error reporting and user feedback

#### generator.zig
Main documentation generation engine:
- **Multi-version support**: Processes multiple Zig stdlib versions
- **File traversal**: Recursively processes `.zig` files
- **HTML generation**: Coordinates parsing and template rendering
- **Asset management**: Copies static files and creates directory structure

#### parser.zig
Zig source code analysis:
- **Comment extraction**: Processes `///` and `//!` documentation comments
- **Declaration detection**: Identifies public functions, constants, structs, tests
- **Import resolution**: Transforms `@import("file.zig")` into relative links
- **Syntax highlighting**: Preserves code formatting for display

#### template.zig
HTML template system:
- **Two-column layout**: Maintains docco-style presentation
- **Dynamic content**: Version-specific navigation and metadata
- **Asset inclusion**: CSS, JavaScript, and image handling
- **SEO optimisation**: Meta tags and structured data

#### version_manager.zig
Multi-version Zig stdlib management:
- **Version configuration**: Supported versions and download URLs
- **Source management**: Downloads and caches Zig stdlib sources
- **Version detection**: Identifies available local versions
- **Update automation**: Fetches new versions from GitHub releases

### Static Assets
- **assets/styles.css**: Enhanced docco-inspired styling with version selector
- **assets/index.html**: Landing page template with version navigation
- **assets/zig-stdlib-book.svg**: Project logo/icon
- **assets/js/**: Client-side navigation and search functionality

### Documentation Structure

The generated HTML uses a table-based two-column layout:
- **Left column (.doc)**: Documentation comments, public identifiers, function signatures
- **Right column (.code)**: Raw Zig source code with preserved formatting
- **Special formatting**: Different styles for functions, methods, constants, tests

### Zig Language Parsing

The Zig parser recognises and processes these language constructs:
- `pub const foo` → Creates heading with potential import links
- `pub fn foo()` → Creates function heading
- `pub fn foo()` (indented) → Creates method heading with special styling
- `test "description"` → Creates test section with description
- `test identifier` → Creates test section with identifier name
- `///` documentation comments → Converted to formatted HTML
- `//!` module documentation → Processed as module-level docs
- `@import("file.zig")` → Transformed into navigation links

### Multi-Version Support

- **Version Detection**: Automatically detects available Zig installations
- **Source Management**: Downloads and caches stdlib sources for each version
- **Output Organisation**: Separate directories for each version (`dist/0.14.1/`, `dist/0.15.0-master/`)
- **Shared Assets**: Common CSS, JavaScript, and images across all versions
- **Version Navigation**: Landing page with version selector and comparison

## Development Notes

### Build System
- **Primary**: Zig's native build system (`build.zig`) with Makefile wrapper for convenience
- **Formatting**: Automatic formatting enforced via `zig build fmt` - REQUIRED before commits
- **Testing**: Unit tests run via `zig build test` targeting `main.zig`
- **Dependencies**: Pure Zig standard library only, no external dependencies

### Deployment & Hosting
- **CI/CD**: GitHub Actions handle build, test, and deployment pipeline
- **Hosting**: Cloudflare Pages (`zstd-live.pages.dev`)
- **Configuration**: `wrangler.toml` configures Cloudflare Pages deployment
- **Redirects**: `_redirects` file provides `/latest/*` and `/stable/*` shortcuts
- **Caching**: Optimised cache headers for HTML (1h), static assets (1y)

### File Processing
- **Source Discovery**: Recursively processes `.zig` files in Zig stdlib directories
- **Filtering**: Skips `zig-cache` directories and respects standard ignore patterns
- **Output Structure**: Mirrors input directory structure with `.zig.html` extensions
- **Asset Management**: Copies static assets (`assets/`) shared across all versions

### URL Structure & Navigation
- **Version Routing**: `/latest/*` → `/0.15.0-master/*`, `/stable/*` → `/0.14.1/*`
- **Import Links**: Transforms `@import("file.zig")` into relative navigation links
- **Landing Page**: `index.html` provides version selector and project navigation
- **Progressive Enhancement**: JavaScript enhances navigation without breaking basic functionality

## File Naming Conventions

- **Generated HTML**: Maintains `.zig.html` extension for compatibility
- **Directory Structure**: Mirrors input Zig stdlib layout within version subdirectories
- **Static Assets**: Shared across versions in root `assets/` directory
- **Source Files**: Use underscores instead of dashes (following IMPORTANT guidelines)

## Commit Messages

Follow conventional commit format with detailed explanations and proper sign-off. Use British Spelling.

### Format

```
<type>(<scope>): <subject>

<detailed body explaining what and why in bullet points>

BREAKING CHANGE: <description if applicable>

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
Signed-Off-By: Paal Øye-Strømme <paal.o.eye@gmail.com>
```

### Best Practices

- **Type**: Use `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- **Scope**: Specify affected module/component (e.g., `supabase`, `components`, `hooks`)
- **Subject**: Imperative mood, no period, max 50 characters
- **Body**: Explain the what and why, not how. Include context and reasoning in bullet points using "-" as for item mark
- **Breaking Changes**: Always document with `BREAKING CHANGE:` footer
- **Sign-off**: Include Claude Code attribution for AI-generated commits in `Co-Authored-By` and the main committer in `Signed-Off-By`

### Examples

```bash
feat(supabase): add verify-email function

- added verify-email Edge function to confirm users's email
- added tests

fix(components): add toaster

- toaster is used for notification
- no testes yet

docs:: update module usage examples and references

- for consistency
- improved readability

refactor(hooks): change useToast

- fixes #1
- added extra options
```
