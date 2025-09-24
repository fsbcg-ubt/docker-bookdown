# Docker Bookdown Image

The image provided by this repository via DockerHub can be used to render books via bookdown (https://bookdown.org/).

Currently, only the rendering of gitbooks for GitHub pages is tested.

```bash
docker run --rm --mount src=$(pwd),target=/book,type=bind ghcr.io/fsbcg-ubt/docker-bookdown:latest Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::gitbook')"
```

The gitbook files are written in a `_book` folder inside the mounted directory.

The support for PDF rendering via LaTex will be added later.

## Development

This project uses a Makefile to manage dependencies and releases. The Docker image packages bookdown, pandoc, and TinyTeX with specific versions tracked in the Dockerfile.

### Prerequisites

Verify required tools:
```bash
make check-tools
```

Required: make, docker, git, jq, awk, sed, grep, curl, column
Optional enhancements: semver, gum (for better UX)

### Dependency Update Workflow

1. Check for available updates:
```bash
make check-versions
```

2. Update all dependencies to latest versions:
```bash
make update-deps
```

3. Update specific component:
```bash
make update-bookdown V=0.45
make update-pandoc V=3.9.0
make update-tinytex V=2025.10
```

4. Handle Renovate PR updates:
```bash
make update-deps-pr PR=123
```

### Release Process

After merging dependency updates:
```bash
make release          # View release preparation
make create-release   # Create GitHub release
```

### Additional Commands

```bash
make help            # Show all available commands
make validate-all    # Validate version formats
make build           # Build Docker image locally
make test            # Test the built image
```