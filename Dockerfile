FROM r-base@sha256:08961f4e20fa015160674d6ff026f7e7d43484f5e7c115c6318d7c52c1bccbb6

ARG BOOKDOWN_VERSION=0.44
ARG PANDOC_VERSION=3.8
ARG TINYTEX_VERSION=2025.09
ARG R_TINYTEX_VERSION=0.54

LABEL org.opencontainers.image.title="Docker Bookdown Image"
LABEL org.opencontainers.image.description="Docker Image to render Bookdown projects with Pandoc."
LABEL org.opencontainers.image.authors="Martin Bens <martin.bens@uni-bayreuth.de>"

LABEL org.opencontainers.image.source="https://github.com/fsbcg-ubt/docker-bookdown"
LABEL org.opencontainers.image.version="0.3.6"
LABEL org.opencontainers.image.licenses="MIT"

LABEL org.opencontainers.image.base.name="registry.hub.docker.com/r-base"
LABEL org.opencontainers.image.base.digest="sha256:08961f4e20fa015160674d6ff026f7e7d43484f5e7c115c6318d7c52c1bccbb6"

LABEL maintainer="Martin Bens <martin.bens@uni-bayreuth.de>"
LABEL r_version="4.4.2"
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