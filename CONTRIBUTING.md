# Contributing to zstd-live

We welcome contributions to zstd-live! This document provides guidelines and information for contributors.

## 🚀 Quick Start

1. **Fork** the repository
2. **Clone** your fork: `git clone https://github.com/YOUR_USERNAME/zstd-live.git`
3. **Setup** development environment: `make dev`
4. **Create** a feature branch: `git checkout -b feat/amazing-feature`
5. **Make** your changes and add tests
6. **Test** your changes: `make check` (runs formatting and tests)
7. **Commit** your changes with conventional commits
8. **Push** and create a Pull Request

## 📋 Development Requirements

- **Zig 0.14.0** or later
- **Make** (optional, but recommended)
- **Git** with conventional commit setup

## 🛠️ Development Commands

```bash
# Build the application
make build

# Run all checks (format + tests)
make check

# Format code (REQUIRED before commits)
make format

# Run tests
make test

# Build release binaries for all platforms
make release

# Create release archives
make release-archive

# Generate documentation locally
make generate

# Serve docs locally
make serve

# Complete development setup
make dev
```

## 🏷️ GitHub Labels System

We use a comprehensive 30-label system for professional issue and PR management:

### **Issue Types** (Always Required)
- `type:feature` - New features and enhancements
- `type:bugfix` - Bug fixes and corrections
- `type:maintenance` - Maintenance tasks and housekeeping

### **Components & Areas**
- `ci/cd` - Continuous integration and deployment
- `build-system` - Build configuration, Makefile, Zig build
- `cross-platform` - Platform compatibility and cross-compilation
- `workflow` - GitHub Actions workflows
- `documentation` - Improvements or additions to documentation

### **Platform & Architecture**
- `platform:macos` / `platform:linux` / `platform:windows`
- `arch:x86_64` / `arch:aarch64` / `arch:riscv64`

### **Priority Levels**
- `priority:high` - Security fixes, release blockers, critical bugs
- `priority:medium` - Important features, significant improvements
- `priority:low` - Nice-to-have features, minor improvements

### **Status Tracking**
- `status:blocked` - Blocked by external factors
- `status:in-progress` - Currently being worked on
- `status:ready-for-review` - Ready for code review
- `status:needs-testing` - Needs testing and validation

### **Release & Version Management**
- `release` - Release-related issues and PRs
- `v2.0.0` - Issues and PRs for v2.0.0 milestone
- `pre-release` - Pre-release testing and feedback
- `breaking-change` - Breaking changes requiring major version bump

### **Community Labels**
- `good-first-issue` - Good for newcomers
- `help-wanted` - Extra attention is needed
- `community` - Community-driven improvements
- `reviewer-needed` - Needs code review from maintainers

## 📝 Contribution Guidelines

### **Pull Request Process**

1. **Create Descriptive PR**
   - Clear title following conventional commits
   - Detailed description of changes
   - Link to related issues

2. **Apply Appropriate Labels**
   ```bash
   # Example: Major feature
   gh pr edit <PR_NUMBER> --add-label "v2.0.0,type:feature,ci/cd,workflow"

   # Example: Platform-specific bug
   gh pr edit <PR_NUMBER> --add-label "type:bugfix,platform:macos,priority:high"

   # Example: Documentation update
   gh pr edit <PR_NUMBER> --add-label "documentation,type:maintenance,community"
   ```

3. **Label Assignment Guidelines**
   - **Always include**: At least one `type:*` label
   - **Version labels**: Add `v2.0.0` for milestone-related work
   - **Component labels**: Add relevant technical area labels
   - **Platform labels**: For platform-specific issues
   - **Priority labels**: For issues requiring urgent attention
   - **Status labels**: To track progress through development workflow

### **PR Status Workflow**
```
[Create PR] → status:ready-for-review
     ↓
[Issues Found] → status:needs-testing / status:blocked
     ↓
[Address Issues] → status:ready-for-review
     ↓
[Approved] → [Merged]
```

### **Code Standards**

- **Formatting**: Must pass `make check-fmt` (Zig's built-in formatter)
- **Testing**: All new features must include tests
- **Documentation**: Update README.md or CLAUDE.md for significant changes
- **Conventional Commits**: Use conventional commit messages

### **Breaking Changes**
- Always use `breaking-change` label
- Document in commit message with `BREAKING CHANGE:` footer
- Provide migration guide in PR description
- Consider if change requires major version bump

## 🔄 Development Workflow

### **For New Contributors**
1. Look for issues labeled `good-first-issue`
2. Comment on the issue to get assigned
3. Follow the development setup above
4. Ask questions in the issue or discussions

### **For Regular Contributors**
1. Create feature branch from `main`
2. Make changes following project conventions
3. Run quality checks: `make check`
4. Create PR with proper labels
5. Address review feedback promptly

### **For Maintainers**
1. **Initial Review**: Check proper labeling and description
2. **Technical Review**: Verify code quality, tests, formatting
3. **Build Verification**: Ensure CI/CD passes on all platforms
4. **Documentation Check**: Verify README/CLAUDE.md updates
5. **Release Impact**: Consider if PR affects v2.0.0 milestone

## 🎯 Types of Contributions Welcome

### **Code Contributions**
- Bug fixes
- New features
- Performance improvements
- Cross-platform compatibility
- Test coverage improvements

### **Documentation Contributions**
- README improvements
- Code comments
- Architecture documentation
- Tutorial creation
- API documentation

### **Community Contributions**
- Issue triage
- Testing pre-releases
- Community support
- Translation efforts
- Blog posts and tutorials

## 🐛 Reporting Bugs

When reporting bugs, please include:

1. **Environment Information**
   - Operating system and version
   - Zig version
   - Architecture (x86_64, aarch64, etc.)

2. **Bug Description**
   - Clear description of the issue
   - Steps to reproduce
   - Expected vs actual behavior

3. **Additional Context**
   - Error messages or logs
   - Screenshots if applicable
   - Relevant configuration

## 💡 Suggesting Features

For new features:

1. **Check existing issues** to avoid duplicates
2. **Describe the feature** clearly and concisely
3. **Explain the use case** and benefits
4. **Consider implementation** complexity
5. **Add appropriate labels** (`type:feature`, relevant components)

## 🔐 Security

For security vulnerabilities, please follow responsible disclosure:

1. **Do not** create public issues for security vulnerabilities
2. **Email** security concerns to the maintainers
3. **Wait** for acknowledgment before public disclosure
4. **Follow** our security policy (when available)

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙋 Getting Help

- **Documentation**: Check README.md and CLAUDE.md first
- **Issues**: Search existing issues before creating new ones
- **Discussions**: Use GitHub Discussions for questions
- **Labels**: Use `help-wanted` or `question` labels appropriately

## 🎉 Recognition

Contributors are recognized in several ways:

- Listed in release notes for significant contributions
- GitHub contributor statistics
- Potential invitation to become a maintainer
- Community recognition and thanks

---

Thank you for contributing to zstd-live! Your efforts help make this project better for everyone. 🚀

*This document follows the project's commitment to professional open source development and comprehensive contributor support.*
