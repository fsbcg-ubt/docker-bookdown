FROM r-base:4.2.1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev

RUN R -e "install.packages('bookdown',dependencies=TRUE)"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    pandoc

RUN mkdir /book
VOLUME /book
WORKDIR /book