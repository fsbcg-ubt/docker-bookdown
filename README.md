# Docker Bookdown Image

A Docker image for rendering books via [bookdown](https://bookdown.org/), available through GitHub Container Registry.

## Quick Start

Render a bookdown project in your current directory:

```bash
docker run --rm --mount src=$(pwd),target=/book,type=bind \
  ghcr.io/fsbcg-ubt/docker-bookdown:latest \
  Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::gitbook')"
```

The rendered gitbook files will be written to a `_book` folder in your mounted directory.

## Usage Examples

### Render to GitBook Format

```bash
docker run --rm -v $(pwd):/book ghcr.io/fsbcg-ubt/docker-bookdown:latest \
  Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::gitbook')"
```

### Render to PDF Format

```bash
docker run --rm -v $(pwd):/book ghcr.io/fsbcg-ubt/docker-bookdown:latest \
  Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::pdf_book')"
```

### Render to EPUB Format

```bash
docker run --rm -v $(pwd):/book ghcr.io/fsbcg-ubt/docker-bookdown:latest \
  Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::epub_book')"
```

## What's Included

The Docker image includes:

- **R** - Statistical computing environment
- **Bookdown** - Authoring books with R Markdown
- **Pandoc** - Universal document converter
- **TinyTeX** - Lightweight LaTeX distribution for PDF output
- **R TinyTeX** - R interface to TinyTeX

## Available Versions

- `latest` - Most recent stable release
- `X.X.X` - Specific version tags (e.g., `0.3.6`)

Pull a specific version:

```bash
docker pull ghcr.io/fsbcg-ubt/docker-bookdown:0.3.6
```

## Documentation & Support

- **[Contributing Guide](CONTRIBUTING.md)** - How to contribute to this project
- **[Development Guide](DEVELOPMENT.md)** - Technical setup and development workflows
- **[Style Guide](STYLE_GUIDE.md)** - Documentation writing standards
- **[Issues & Discussions](https://github.com/fsbcg-ubt/docker-bookdown/issues)** - Get help or report problems

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Built on top of the [rocker/r-ver](https://hub.docker.com/r/rocker/r-ver) Docker image and powered by:
- The [bookdown](https://github.com/rstudio/bookdown) project by Yihui Xie
- [Pandoc](https://pandoc.org/) by John MacFarlane
- [TinyTeX](https://yihui.org/tinytex/) for LaTeX support