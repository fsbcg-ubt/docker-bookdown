FROM r-base:4.2.1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev

ARG BOOKDOWN_VERSION=0.29
RUN R -e "install.packages('bookdown',version='${BOOKDOWN_VERSION}',dependencies=TRUE)"

ARG PANDOC_VERSION=2.19.2
# Download the specified pandoc version. (see: https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8)
RUN curl -s https://api.github.com/repos/jgm/pandoc/releases/tags/${PANDOC_VERSION} | \
    grep "browser_download_url.*amd64.deb" | \
    cut -d : -f 2,3 | \
    tr -d \" | \
    wget -qi - && \
    dpkg -i pandoc-*.deb

RUN mkdir /book
VOLUME /book
WORKDIR /book