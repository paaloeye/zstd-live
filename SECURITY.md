# Security Policy

## Supported Versions

We provide security updates for the following versions of zstd-live:

| Version | Supported          |
| ------- | ------------------ |
| 2.0.x   | :white_check_mark: |
| < 2.0   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security vulnerability in zstd-live, please follow these steps:

### 1. Do Not Create Public Issues

**Please do not report security vulnerabilities through public GitHub issues.** This helps protect users while we work on a fix.

### 2. Report Privately

Send details of the vulnerability to the project maintainers via:

- **GitHub Security Advisories**: Use the "Report a vulnerability" feature on our GitHub repository
- **Email**: Contact the maintainers directly (check repository for current contact information)

### 3. Include Detailed Information

When reporting a vulnerability, please provide:

- **Description**: A clear description of the vulnerability
- **Steps to Reproduce**: Detailed steps to reproduce the issue
- **Impact**: Potential impact and attack scenarios
- **Affected Versions**: Which versions are affected
- **Environment**: Operating system, architecture, Zig version
- **Proof of Concept**: If applicable, a minimal proof of concept

### 4. Response Timeline

We aim to respond to security reports within:

- **Initial Response**: 48 hours
- **Vulnerability Assessment**: 7 days
- **Fix Development**: 30 days (depending on complexity)
- **Public Disclosure**: After fix is released and users have had time to update

## Security Measures

### Build Security

- **SHA256 Checksums**: All release assets include SHA256 checksums for verification
- **Automated Builds**: All releases are built via GitHub Actions with minimal human intervention
- **Signed Releases**: Release artifacts are built from tagged commits with full provenance

### Code Security

- **Memory Safety**: Built with Zig, which provides memory safety features
- **No External Dependencies**: Pure Zig standard library implementation reduces attack surface
- **Static Analysis**: Code undergoes formatting checks and automated testing
- **Cross-Platform Testing**: All supported platforms are tested in CI/CD

### Supply Chain Security

- **Reproducible Builds**: Builds are reproducible and can be verified
- **Minimal Dependencies**: No external dependencies beyond Zig standard library
- **Automated Updates**: Renovate bot helps keep dependencies current (where applicable)
- **Source Verification**: All source code is available and auditable

## Vulnerability Response Process

1. **Report Received**: We acknowledge receipt of your report
2. **Initial Assessment**: We evaluate the severity and impact
3. **Investigation**: We investigate and reproduce the issue
4. **Fix Development**: We develop and test a fix
5. **Coordinated Disclosure**: We coordinate release timeline with reporter
6. **Public Release**: We release the fix and security advisory
7. **Post-Release**: We monitor for any additional issues

## Security Best Practices for Users

### Verification

- **Verify Checksums**: Always verify SHA256 checksums of downloaded releases
- **Use Official Sources**: Download releases only from GitHub releases page
- **Check Signatures**: Verify any signatures provided with releases

### Usage

- **Keep Updated**: Update to the latest version promptly when security fixes are released
- **Principle of Least Privilege**: Run zstd-live with minimal necessary permissions
- **Secure Environment**: Use zstd-live in secure, trusted environments

### Reporting Issues

- **Security Issues**: Follow this security policy for security-related issues
- **General Issues**: Use GitHub issues for non-security related bugs and features

## Disclosure Policy

- **Coordinated Disclosure**: We prefer coordinated disclosure with security researchers
- **Credit**: Security researchers will be credited in security advisories (if desired)
- **Timeline**: We aim for responsible disclosure timelines that protect users while recognizing researcher contributions

## Contact

For security-related inquiries:

- Use GitHub Security Advisories on this repository
- Check repository README for current maintainer contact information
- Look for security contact information in repository settings

## Attribution

This security policy is based on industry best practices and community standards for open source security policies.

---

*We appreciate the security research community's efforts to improve the security of open source software. Thank you for helping make zstd-live more secure.*
