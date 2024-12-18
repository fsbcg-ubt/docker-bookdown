FROM r-base@sha256:e7032f2f6fd273ee944a717b436bc66d1a89b1b90a9bbcaafcf1318d68a7d8b2

ARG BOOKDOWN_VERSION=0.41
ARG PANDOC_VERSION=3.5
ARG TINYTEX_VERSION=2024.10
ARG R_TINYTEX_VERSION=0.53

LABEL org.opencontainers.image.title="Docker Bookdown Image"
LABEL org.opencontainers.image.description="Docker Image to render Bookdown projects with Pandoc."
LABEL org.opencontainers.image.authors="Martin Bens <martin.bens@uni-bayreuth.de>"

LABEL org.opencontainers.image.source="https://github.com/fsbcg-ubt/docker-bookdown"
LABEL org.opencontainers.image.version="0.3.4"
LABEL org.opencontainers.image.licenses="MIT"

LABEL org.opencontainers.image.base.name="registry.hub.docker.com/r-base"
LABEL org.opencontainers.image.base.digest="sha256:d48acc908bb73ab844c049ac3b83dd6ced3647eb16dadcc3dad20abab4e5715a"

LABEL maintainer="Martin Bens <martin.bens@uni-bayreuth.de>"
LABEL r_version="4.1.1"
LABEL bookdown_version="${BOOKDOWN_VERSION}"
LABEL pandoc_version="${PANDOC_VERSION}"
LABEL tinytex_version="${TINYTEX_VERSION}"
LABEL r_tinytex_version="${R_TINYTEX_VERSION}"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev

RUN R -e "install.packages('bookdown',version='${BOOKDOWN_VERSION}',dependencies=TRUE)"

# Download the specified pandoc version. (see: https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8)
RUN curl -s https://api.github.com/repos/jgm/pandoc/releases/tags/${PANDOC_VERSION} | \
    grep "browser_download_url.*amd64.deb" | \
    cut -d : -f 2,3 | \
    tr -d \" | \
    wget -qi - && \
    dpkg -i pandoc-*.deb

# Install TinyText for PDF books.
RUN R -e "install.packages('tinytex',version='${R_TINYTEX_VERSION}',dependencies=TRUE)" && \
    R -e "tinytex::install_tinytex(force=TRUE,version='${TINYTEX_VERSION}')"

RUN mkdir /book
VOLUME /book
WORKDIR /book