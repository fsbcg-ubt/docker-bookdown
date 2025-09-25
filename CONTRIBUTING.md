# Contributing

## Core Requirements

All changes must build successfully. Run `make build` before submitting. Ensure `make validate-all` passes for version format validation.

## Bug Reports

Check existing issues before reporting. Include:

- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Docker version and OS
- Complete error output
- Minimal reproduction case if possible

## Pull Requests

Create focused PRs with meaningful titles that describe what the change accomplishes. The description must explain what the PR introduces and why it's needed.

### PR Requirements

- Fork from `main` branch
- Follow Dockerfile and documentation style guidelines
- Update documentation for functionality changes
- Build successfully with `make build`
- Use conventional commit messages

### What happens next

PRs are reviewed within a week. Reviewers may request changes. Once approved, maintainers merge and include in the next release.

## Commit Messages

```
type: subject

body (optional)
```

Types: `feat:` `fix:` `docs:` `chore:` `refactor:` `test:`

Subject: 50 characters maximum. No period. Explain why, not what changed.

### Dependency Updates

Each component requires individual commit:

| Component | Format |
|-----------|--------|
| R base | `R base image updated. Version X.X.X is kept.` |
| Bookdown | `Bookdown updated to X.XX.` |
| Pandoc | `Pandoc updated to X.X.X.` |
| TinyTeX | `TinyTex updated to vYYYY.MM.` |
| R TinyTeX | `R TinyTex updated to X.XX.` |

Reference issues when applicable.

## Style Guidelines

Follow the [Style Guide](STYLE_GUIDE.md) for all documentation. Key points:

### Dockerfile
- Specific version tags, never `latest`
- Group related commands to minimize layers
- Order by change frequency
- Document complex operations
- Use ARG for versions
- Include LABEL metadata

### Documentation
- Be concise and direct
- Avoid boilerplate content
- Update all affected files
- Maintain consistent formatting

## Development

- [Development Guide](DEVELOPMENT.md) - Setup and technical workflows
- [GitHub Issues](https://github.com/fsbcg-ubt/docker-bookdown/issues) - Bug reports and discussions