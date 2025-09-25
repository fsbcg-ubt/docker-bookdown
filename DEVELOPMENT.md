# Development

Technical setup and workflows for Docker Bookdown.

## Prerequisites

Required tools:
- `make` - Build automation
- `docker` - Container runtime
- `git` - Version control
- `jq` - JSON processor
- `awk`, `sed`, `grep` - Text processing
- `curl` - HTTP client

Optional:
- `gh` - GitHub CLI
- `semver` - Version management
- `gum` - Interactive UI

Verify installation:
```bash
make check-tools
```

## Setup

### Fork and Clone
```bash
git clone https://github.com/YOUR_USERNAME/docker-bookdown.git
cd docker-bookdown
git remote add upstream https://github.com/fsbcg-ubt/docker-bookdown.git
```

### Environment Validation
```bash
docker info
gh auth login  # optional
make validate-all
```

## Project Structure
```
docker-bookdown/
├── Dockerfile           # Image definition
├── Makefile            # Build automation
├── README.md           # User documentation
├── CONTRIBUTING.md     # Contribution guide
├── DEVELOPMENT.md      # This file
├── MAINTAINERS.md      # Maintenance procedures
└── .github/
    └── workflows/
        └── publish.yml # CI/CD pipeline
```

## Workflows

### Build and Test
```bash
make build          # Build image
make test           # Run tests
make shell          # Interactive container
make clean          # Remove local images
```

### Dependency Management

Check versions:
```bash
make check-versions      # Check for updates
make check-renovate-pr   # Check Renovate PRs
```

Update dependencies:
```bash
make update-deps-auto              # Auto-detect and update
make update-deps                   # Update all to latest
make update-deps-pr PR=123         # Update via Renovate PR
make update-bookdown V=0.45        # Update specific component
```

### Makefile Commands

| Command | Description |
|---------|-------------|
| `make help` | Show commands |
| `make check-versions` | Check updates |
| `make validate-all` | Validate formats |
| `make show-versions` | Display versions |
| `make build` | Build image |
| `make test` | Run tests |
| `make shell` | Container shell |
| `make ci-check` | CI validation |
| `make ci-test` | Full test suite |
| `make rollback` | Rollback commit |

## Commit Standards

### Dependency Updates

Each component requires individual commit:

| Component | Format | Example |
|-----------|--------|---------|
| R base | `R base image updated. Version X.X.X is kept.` | `R base image updated. Version 4.4.2 is kept.` |
| Bookdown | `Bookdown updated to X.XX.` | `Bookdown updated to 0.42.` |
| Pandoc | `Pandoc updated to X.X.X.` | `Pandoc updated to 3.6.2.` |
| TinyTeX | `TinyTex updated to vYYYY.MM.` | `TinyTex updated to v2025.01.` |
| R TinyTeX | `R TinyTex updated to X.XX.` | `R TinyTex updated to 0.54.` |
| Version | `Image version bumped to X.X.X.` | `Image version bumped to 0.3.7.` |

Note: TinyTeX commits include 'v' prefix; Dockerfile uses YYYY.MM without prefix.

### Convention Types
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation
- `chore:` - Maintenance
- `refactor:` - Restructuring
- `test:` - Test changes
- `ci:` - CI/CD changes

## Docker Development

### Building
```bash
# Default build
make build

# Custom R version
docker build --build-arg R_VERSION=4.3.3 -t docker-bookdown:r4.3 .

# No cache
docker build --no-cache -t docker-bookdown:fresh .

# Multi-platform
docker buildx build --platform linux/amd64,linux/arm64 -t docker-bookdown:multi .
```

### Testing Components
```bash
docker run --rm docker-bookdown:local R --version
docker run --rm docker-bookdown:local R -e "packageVersion('bookdown')"
docker run --rm docker-bookdown:local pandoc --version
docker run --rm docker-bookdown:local R -e "tinytex::tinytex_root()"
```

### Testing Outputs
```bash
# GitBook
docker run --rm -v $(pwd)/test:/book docker-bookdown:local \
  Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::gitbook')"

# PDF
docker run --rm -v $(pwd)/test:/book docker-bookdown:local \
  Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::pdf_book')"

# EPUB
docker run --rm -v $(pwd)/test:/book docker-bookdown:local \
  Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::epub_book')"
```

## Testing

### Automated Tests
```bash
make test
make ci-test
```

### Integration Test
Create test project:
```bash
mkdir -p test-project && cd test-project

cat > index.Rmd << 'EOF'
---
title: "Test Book"
output: bookdown::gitbook
---

# Introduction
Test content.
EOF

cat > _bookdown.yml << 'EOF'
book_filename: "test-book"
delete_merged_file: true
EOF

docker run --rm -v $(pwd):/book docker-bookdown:local \
  Rscript -e "bookdown::render_book('index.Rmd')"
```

### Manual Validation
- [ ] Image builds without errors
- [ ] All output formats work
- [ ] Package versions correct
- [ ] Volume mounting works

#### Version Validation Functions
```bash
validate_bookdown() {
  [[ "$1" =~ ^[0-9]+\.[0-9]{2}$ ]] && return 0 || return 1
}

validate_pandoc() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && return 0 || return 1
}

validate_tinytex() {
  local version="${1#v}"
  [[ "$version" =~ ^20[0-9]{2}\.(0[1-9]|1[0-2])$ ]] && return 0 || return 1
}

validate_r_tinytex() {
  [[ "$1" =~ ^[0-9]+\.[0-9]{2}$ ]] && return 0 || return 1
}

validate_image() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && return 0 || return 1
}
```

For releases, see [MAINTAINERS.md](MAINTAINERS.md#release-procedures).

## Resources

- [Bookdown documentation](https://bookdown.org/yihui/bookdown/)
- [Pandoc manual](https://pandoc.org/MANUAL.html)
- [TinyTeX documentation](https://yihui.org/tinytex/)
- [Docker best practices](https://docs.docker.com/develop/dev-best-practices/)