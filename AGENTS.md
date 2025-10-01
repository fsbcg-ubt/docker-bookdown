# AI Assistant Guide

Docker image for rendering books via bookdown. Published to `ghcr.io/fsbcg-ubt/docker-bookdown`.

## Documentation

- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Setup, workflows, build commands, testing procedures
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - PR process, commit standards, style guidelines
- **[STYLE_GUIDE.md](STYLE_GUIDE.md)** - Documentation writing standards
- **[README.md](README.md)** - User documentation, usage examples
- **[Makefile](Makefile)** - All commands (`make help`)

## Essential Commands

```bash
make build && make validate-all  # Required before PR submission
make test                        # Verify all components
make check-versions              # Check for dependency updates
make update-deps-auto            # Update dependencies (auto-detect PR or latest)
```

## Version Formats

| Component | Format | Example | Validation Regex |
|-----------|--------|---------|------------------|
| R base | `X.X.X` | `4.4.2` | Keep existing |
| Bookdown | `X.XX` | `0.42` | `^[0-9]+\.[0-9]{2}$` |
| Pandoc | `X.X.X` | `3.6.2` | `^[0-9]+\.[0-9]+\.[0-9]+$` |
| TinyTeX | `vYYYY.MM` | `v2025.01` | `^v20[0-9]{2}\.(0[1-9]\|1[0-2])$` |
| R TinyTeX | `X.XX` | `0.54` | `^[0-9]+\.[0-9]{2}$` |
| Image | `X.X.X` | `0.3.7` | `^[0-9]+\.[0-9]+\.[0-9]+$` |

TinyTeX: Use `v` prefix in commits, omit in Dockerfile.

## Commit Formats

### Dependency Updates
Each component requires individual commit:

```
Bookdown updated to 0.42.
Pandoc updated to 3.6.2.
TinyTex updated to v2025.01.
R TinyTex updated to 0.54.
Image version bumped to 0.3.7.
R base image updated. Version 4.4.2 is kept.
```

### Other Changes
```
type: subject

body (optional)
```

Types: `feat:` `fix:` `docs:` `chore:` `refactor:` `test:` `ci:`

## Workflows

### Update Dependencies
```bash
make check-versions              # Check for updates
make update-deps-auto            # Auto-detect PR or latest
make update-deps-pr PR=123       # Update via Renovate PR
make update-bookdown V=0.45      # Update specific component
make build && make test          # Verify changes
```

### PR Submission
1. `make build && make validate-all`
2. `make test`
3. Follow commit message formats exactly
4. One commit per dependency update
5. Update documentation if functionality changes

### Testing Components
```bash
make test                        # Automated test suite
make validate-all                # Validate version formats
```

For detailed testing procedures, see [DEVELOPMENT.md](DEVELOPMENT.md).

## Common Patterns

### Adding Dependencies
1. Add ARG in Dockerfile
2. Update Makefile validation if needed
3. Test all formats: `make build && make test && make validate-all`
4. Document in README if user-facing

### Updating via Renovate PR
```bash
make check-renovate-pr           # List open Renovate PRs
make update-deps-pr PR=123       # Apply updates from PR
make build && make test          # Verify
git push                         # Push to PR branch
```

### Dockerfile Conventions
- Use ARG for all versions
- Specific version tags only, never `latest`
- Group related RUN commands
- Order layers by change frequency

Full conventions in [CONTRIBUTING.md](CONTRIBUTING.md).
