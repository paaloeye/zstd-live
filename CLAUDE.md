# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## IMPORTANT

- ALWAYS read [GOTCHA.md](./GOTCHA.md) before making changes - Contains critical pitfalls and solutions
- PREFER British English over American English spelling and grammar
- Files and Directories MUST NOT have **dashes** in names/paths (Use **underscore** instead)
- NEVER use Git LFS
- ALWAYS run `make format` before `git commit` (uses `zig build fmt`)
- USE Emoji in [README.md](./README.md) or **docs/\*.md** with care. NOT MUCH.
- ALWAYS use `[x]` or `[ ]` instead of ✅ / 🔲 / for checkmarks
- NEVER use `[x]` or `[ ]` in Markdown tables; USE ✅ / 🔲 / instead. **Reason**: it's not supported
- PREFER [GitHub Emoji API](https://api.github.com/emojis) over UTF Emoji
- ALWAYS add footer to new Markdown files with a AI generated content banner (!IMPORTANT)
- USE `zig fetch <url>` when add dependencies to build.zon
- ALWAYS run `make help` if you see a Makefile to learn targets and semantic of that subdirectory
- PREFER `make clean` over `rm -rf`

## Project Overview

This is a Zig-native tool called "zstd-live" that generates live HTML documentation sites from Zig standard library source code. It creates a two-column layout inspired by docco.coffee, where the left column shows documentation and public identifiers, and the right column displays the raw Zig source code with syntax highlighting. The tool supports multiple Zig versions and converts `@import()` calls into clickable hyperlinks for navigation.

**Repository**: https://github.com/paaloeye/zstd-live
**Live Site**: https://zstd-live.pages.dev
**Hosting**: Cloudflare Pages (static)

### v2.0.0 Release Highlights

- **🚀 Professional Release Pipeline**: Automated cross-platform builds with GitHub Actions Ship workflow
- **📦 Enhanced Packaging**: Release archives with proper directory structure and comprehensive documentation
- **🔐 Security Improvements**: SHA256 checksums for all release assets
- **🏷️ Professional Project Management**: 30-label system for issues and PRs
- **🌐 Cross-Platform Excellence**: Support for 7 platforms (macOS, Linux, Windows on multiple architectures)
- **📋 Rich Release Notes**: Automated changelog generation with installation guides and build information
- **🛠️ Native Build System**: Pure Zig implementation with no external dependencies
- **⚡ Performance Optimisations**: ReleaseFast builds for all platforms

## Build and Development Commands

### Core Build Commands
```bash
# Build Zig application
make build           # Preferred: uses Makefile wrapper
# OR: zig build       # Direct Zig build

# Build release binaries for all supported platforms
make release         # Cross-compiles for macOS/Linux on x86_64/aarch64/riscv64
# OR: zig build release

# Create release archives for all platforms
make release-archive # Builds and packages binaries with documentation

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

### Cross-Platform Support

The build system supports cross-compilation for the following platforms:

**Supported Targets:**
- `zstd-live-macos-x86_64` (macOS Intel)
- `zstd-live-macos-aarch64` (macOS Apple Silicon)
- `zstd-live-linux-x86_64` (Linux Intel)
- `zstd-live-linux-aarch64` (Linux ARM64)
- `zstd-live-linux-riscv64` (Linux RISC-V)
- `zstd-live-windows-x86_64.exe` (Windows Intel)
- `zstd-live-windows-aarch64.exe` (Windows ARM64)

**Cross-Platform Features:**
- Native HTTP downloads using `std.http.Client` (replaces curl)
- Cross-platform directory creation using `std.fs.cwd().makePath()`
- Platform-specific cache directories (Windows: AppData, macOS: Library/Caches, Linux: .local/share)
- ZIP archive extraction with OS-specific tools (PowerShell on Windows, unzip on Unix)

All release builds use `.ReleaseFast` optimisation for maximum performance.

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

### Release Workflow
```bash
# Create release archives for all platforms
make release-archive             # Cross-compiles and packages binaries

# Complete release process (for GitHub Actions)
make release-check               # Full validation before release

# Manual release creation
git tag v2.0.0-beta.1           # Create pre-release tag
git push origin v2.0.0-beta.1   # Triggers Ship workflow

git tag v2.0.0                  # Create stable release tag
git push origin v2.0.0          # Triggers Ship workflow
```

**Release Automation**: The `.github/workflows/ship.yml` workflow automatically:
- **Shell Compatibility**: Uses POSIX-compliant syntax to avoid `/bin/sh: [[: not found` errors
- **First Release Detection**: Detects if this is the first release and formats accordingly
- **Cross-Platform Builds**: Builds binaries for all 7 supported platforms (macOS, Linux, Windows on multiple architectures)
- **Professional Packaging**: Creates platform-specific archives with proper directory structure and documentation
- **Security**: Generates SHA256 checksums for all release assets with verification instructions
- **Comprehensive Release Notes**: Creates professional release notes with:
  - **Supported Platforms**: Table showing all 7 platforms with binary names
  - **Installation Instructions**: Step-by-step guides for macOS, Linux, and Windows
  - **Quick Start**: Common usage examples with code blocks
  - **Security Section**: SHA256 checksum verification instructions
  - **Automated Changelog**: Git commit history in chronological order
  - **Build Information**: Zig version, build date, commit, and optimisation level
- **Release Classification**: Automatically detects pre-release vs stable from tag format using POSIX case statements
- **Archive Structure**: Each archive contains binary, README.md, and LICENCE files
- **Quality Assurance**: Runs format checks and tests before release

### GitHub Labels & PR Management

The repository uses a comprehensive 30-label system for professional issue and PR management:

#### **Release & Version Management (4 labels)**
```bash
release          # Release-related issues and PRs
v2.0.0           # Issues and PRs for v2.0.0 milestone
pre-release      # Pre-release testing and feedback
breaking-change  # Breaking changes requiring major version bump
```

#### **Issue Types (3 labels)**
```bash
type:feature     # New features and enhancements
type:bugfix      # Bug fixes and corrections
type:maintenance # Maintenance tasks and housekeeping
```

#### **Component/Area Labels (5 labels)**
```bash
ci/cd           # Continuous integration and deployment
build-system    # Build configuration, Makefile, Zig build
cross-platform  # Platform compatibility and cross-compilation
workflow        # GitHub Actions workflows
documentation   # Improvements or additions to documentation
```

#### **Platform & Architecture (6 labels)**
```bash
platform:macos / platform:linux / platform:windows
arch:x86_64 / arch:aarch64 / arch:riscv64
```

#### **Priority & Status (9 labels)**
```bash
# Priority
priority:high / priority:medium / priority:low

# Status
status:blocked / status:in-progress / status:ready-for-review / status:needs-testing

# Community
community / reviewer-needed
```

#### **Community Labels (3 labels)**
```bash
good-first-issue # Good for newcomers
help-wanted      # Extra attention is needed
question        # Further information is requested
```

#### **PR Labeling Best Practices**

**Example: Major Feature PR**
```bash
gh pr edit <PR_NUMBER> --add-label "v2.0.0,type:feature,ci/cd,workflow,cross-platform"
```

**Example: Platform-Specific Bug**
```bash
gh pr edit <PR_NUMBER> --add-label "type:bugfix,platform:macos,arch:aarch64,priority:high"
```

**Example: Documentation Update**
```bash
gh pr edit <PR_NUMBER> --add-label "documentation,type:maintenance,community"
```

#### **Label Assignment Guidelines**
- **Always include**: At least one `type:*` label
- **Version labels**: Add `v2.0.0` for milestone-related work
- **Component labels**: Add relevant technical area labels
- **Platform labels**: For platform-specific issues
- **Priority labels**: For issues requiring urgent attention
- **Status labels**: To track progress through development workflow

### Contribution Guidelines

#### **Development Workflow**
1. **Fork and Branch**: Fork repository, create feature branch
2. **Development**: Make changes following project conventions
3. **Quality Checks**: Run `make check` (format + tests)
4. **PR Creation**: Create PR with descriptive title and body
5. **Label Assignment**: Apply appropriate labels using guidelines above
6. **Review Process**: Address feedback, maintain `status:ready-for-review`
7. **Merge**: Maintainer merges after approval

#### **PR Status Workflow**
```
[Create PR] → status:ready-for-review
     ↓
[Issues Found] → status:needs-testing / status:blocked
     ↓
[Address Issues] → status:ready-for-review
     ↓
[Approved] → [Merged]
```

#### **Priority Assignment Guidelines**
- `priority:high`: Security fixes, release blockers, critical bugs
- `priority:medium`: Important features, significant improvements
- `priority:low`: Nice-to-have features, minor improvements

#### **Community Contributions**
- Use `community` label for external contributions
- Add `good-first-issue` for newcomer-friendly tasks
- Include `help-wanted` when extra attention is needed
- Use `reviewer-needed` when maintainer review is required

#### **Breaking Changes**
- Always use `breaking-change` label
- Document in commit message with `BREAKING CHANGE:` footer
- Consider if change requires major version bump
- Provide migration guide in PR description

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
- **Release Archives**: `.release/` directory contains cross-platform release packages
- **Cross-Compilation**: Supports 7 platforms via `make release` command

### Project Management

#### **Label Management**
```bash
# List all labels
gh label list

# Create new label
gh label create "new-label" --description "Description" --color "ff6b6b"

# Edit existing label
gh label edit "old-name" --name "new-name" --description "New description"

# Apply labels to PR
gh pr edit <PR_NUMBER> --add-label "label1,label2,label3"
```

#### **PR Review Process**
1. **Initial Review**: Check for proper labeling and description
2. **Technical Review**: Verify code quality, tests, and formatting
3. **Build Verification**: Ensure CI/CD passes on all platforms
4. **Documentation Check**: Verify README/CLAUDE.md updates if needed
5. **Release Impact**: Consider if PR affects v2.0.0 milestone

### Deployment & Hosting
- **CI/CD**: GitHub Actions handle build, test, and deployment pipeline
- **Release Automation**: Ship workflow (`.github/workflows/ship.yml`) handles professional releases
- **Hosting**: Cloudflare Pages (`zstd-live.pages.dev`)
- **Configuration**: `wrangler.toml` configures Cloudflare Pages deployment
- **Redirects**: `_redirects` file provides `/latest/*` and `/stable/*` shortcuts
- **Caching**: Optimised cache headers for HTML (1h), static assets (1y)
- **Security**: All release assets include SHA256 checksums for verification
- **Cross-Platform Distribution**: Automated builds for macOS, Linux, Windows (x86_64, aarch64, riscv64)

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
