# zstd-live

> A modern Zig-native tool for generating live HTML documentation from Zig standard library

[![CI](https://github.com/paaloeye/zstd-live/workflows/CI/badge.svg)](https://github.com/paaloeye/zstd-live/actions)
[![Deploy](https://github.com/paaloeye/zstd-live/workflows/Deploy%20to%20Cloudflare%20Pages/badge.svg)](https://github.com/paaloeye/zstd-live/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENCE)

**Live Documentation**: [zstd-live.pages.dev](https://zstd-live.pages.dev)

## Overview

zstd-live generates beautiful, live HTML documentation from Zig standard library source code. It features a two-column layout inspired by docco.coffee, with documentation and public identifiers on the left and syntax-highlighted source code on the right.

### Key Features

- **Multi-version support**: Generate docs for multiple Zig versions (0.15.0-master, 0.14.1, 0.13.0, 0.12.0, 0.11.0)
- **Native Zig implementation**: Fast and reliable
- **Modern deployment**: Automatically deployed to Cloudflare Pages
- **Interactive navigation**: Convert `@import()` statements to clickable links
- **Progressive enhancement**: JavaScript-powered search and navigation
- **Mobile-friendly**: Responsive design for all devices

## Quick Start

### Installation

#### From Release (Recommended)

Download the latest release for your platform from [GitHub Releases](https://github.com/paaloeye/zstd-live/releases):

```bash
# Linux/macOS
curl -L https://github.com/paaloeye/zstd-live/releases/latest/download/zstd-live-linux-x86_64.tar.gz | tar xz
sudo mv zstd-live-linux-x86_64 /usr/local/bin/zstd-live

# macOS with Homebrew (coming soon)
brew install paaloeye/tap/zstd-live
```

#### Build from Source

```bash
git clone https://github.com/paaloeye/zstd-live.git
cd zstd-live
make build
make install
```

### Basic Usage

```bash
# Generate docs for all supported Zig versions
zstd-live generate --all-versions --output ./docs

# Generate docs for specific version
zstd-live generate --version 0.14.1 --output ./docs

# Serve docs locally for development
zstd-live serve --port 8080

# Update Zig stdlib sources
zstd-live update
```

## Development

### Requirements

- Zig 0.13.0 or later
- Make (optional, but recommended)

### Build Commands

```bash
# Build the application
make build

# Run tests
make test

# Format code
make format

# Generate documentation
make generate

# Serve locally
make serve

# Full development setup
make dev
```

### Project Structure

```
src/
├── main.zig              # CLI entry point
├── generator.zig         # Documentation generator
├── parser.zig           # Zig source parser
├── template.zig         # HTML template system
├── version_manager.zig  # Multi-version support
├── file_utils.zig       # File operations
└── config.zig           # Configuration

.github/workflows/        # CI/CD pipelines
├── ci.yml               # Test and build
├── deploy.yml           # Cloudflare deployment
└── release.yml          # Release automation

assets/                  # Static assets
├── styles.css           # Enhanced styling
├── index.html           # Landing page template
└── zig-stdlib-book.svg  # Project logo
```

## Configuration

### Supported Zig Versions

The tool currently supports these Zig versions (configurable in `src/config.zig`):

- `0.15.0-master` (latest development)
- `0.14.1` (latest stable)
- `0.13.0`
- `0.12.0`
- `0.11.0`

### Output Structure

Generated documentation is organised as:

```
dist/
├── index.html         # Version selector landing page
├── assets/            # Shared CSS, JS, images
├── 0.14.1/            # Version-specific docs
│   ├── std.zig.html
│   ├── array_list.zig.html
│   └── ...
└── 0.15.0-master/     # Latest development docs
    ├── std.zig.html
    └── ...
```

## Deployment

### Cloudflare Pages

The project is configured for automatic deployment to Cloudflare Pages:

1. **Automatic Deployment**: Pushes to `main` branch trigger deployment
2. **Daily Updates**: Scheduled rebuilds to catch new Zig changes
3. **Default Domain**: Served at `zstd-live.pages.dev`
4. **Performance**: Optimised caching and compression

### Manual Deployment

```bash
# Generate all documentation
make generate
```

## Contributing

We welcome contributions! Please see our contributing guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and add tests
4. Ensure code is formatted (`make format`)
5. Run tests (`make test`)
6. Commit your changes (`git commit -m 'feat: add amazing feature'`)
7. Push to the branch (`git push origin feat/amazing-feature`)
8. Open a Pull Request

### Development Workflow

- Use conventional commits for all commit messages
- Ensure all tests pass before submitting PR
- Update documentation for new features
- Follow Zig formatting standards

## Architecture

### Multi-Version Support

The tool manages multiple Zig versions by:

1. **Version Detection**: Automatically detects available Zig installations
2. **Source Caching**: Downloads and caches stdlib sources for each version
3. **Parallel Generation**: Efficiently processes multiple versions
4. **Smart Updates**: Only updates changed versions

### Parsing Strategy

- Uses Zig tokenization instead of regex
- Handles complex language constructs accurately
- Provides better error reporting
- Supports future Zig language evolution

## License

This project is licensed under the MIT License - see the [LICENCE](./LICENCE) file for details.

## Acknowledgements

- Original [docco.coffee](https://web.archive.org/web/20120428101624/http://jashkenas.github.com/docco/) for the two-column layout inspiration
- The Zig community for the amazing programming language and standard library
- [ratfactor](https://ratfactor.com/) for the original zstd-browse implementation

---

*🤖 This README was generated with [Claude Code](https://claude.ai/code)*
