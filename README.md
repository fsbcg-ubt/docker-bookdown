# Docker Bookdown Image

The image provided by this repository via DockerHub can be used to render books via bookdown (https://bookdown.org/).

Currently, only the rendering of gitbooks for GitHub pages is tested.

```bash
docker run --rm --mount src=$(pwd),target=/book,type=bind ghcr.io/fsbcg-ubt/docker-bookdown:latest Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::gitbook')"
```

The gitbook files are written in a `_book` folder inside the mounted directory.

The support for PDF rendering via LaTex will be added later.