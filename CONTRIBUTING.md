# Contributing to InnovateMart Project Bedrock

**Project Maintainer:** Michael Aworetan

## How to Contribute

This project welcomes contributions from the community. Whether you're fixing bugs, improving documentation, or adding new features, your help is appreciated.

## Development Setup

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- kubectl
- Docker (for local testing)

### Local Development
```bash
# Clone the repository
git clone <your-fork>
cd aworetan-innovatemart-bedrock

# Set up development environment
cd terraform/state-bootstrap
terraform init && terraform apply

# Deploy to sandbox environment
cd ../envs/sandbox
terraform init && terraform apply
```

## Contribution Guidelines

### Code Standards
- Use consistent Terraform formatting (`terraform fmt`)
- Follow Kubernetes best practices for manifests
- Include resource limits and security contexts
- Document any new variables or modules

### Testing
- Test infrastructure changes in sandbox environment first
- Validate Kubernetes manifests with `kubectl --dry-run=client`
- Ensure CI/CD pipeline passes before merging

### Pull Request Process
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly in sandbox environment
5. Commit with clear messages
6. Push to your fork
7. Open a Pull Request

### Commit Message Format
```
type(scope): brief description

Detailed explanation of changes made and why.

Fixes #issue-number
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## Areas for Contribution

### High Priority
- Cost optimization improvements
- Security enhancements
- Documentation improvements
- Monitoring and alerting setup

### Medium Priority
- Additional environment configurations
- Performance optimizations
- Backup and disaster recovery
- Multi-region support

### Low Priority
- UI/UX improvements for applications
- Additional microservices
- Advanced networking features

## Security

If you discover a security vulnerability, please email the maintainer directly rather than opening a public issue.

## Questions?

Feel free to open an issue for:
- Bug reports
- Feature requests
- Documentation clarifications
- General questions about the project

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---
*Thank you for contributing to make this project better!*