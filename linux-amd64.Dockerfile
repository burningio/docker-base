FROM alpine@sha256:1304f174557314a7ed9eddb4eab12fed12cb0cd9809e4c28f29af86979a3c870 AS builder

ARG UNRAR_VER=6.1.7

RUN apk --update --no-cache add \
    autoconf \
    automake \
    binutils \
    build-base \
    cmake \
    cppunit-dev \
    curl-dev \
    libtool \
    linux-headers \
    zlib-dev \
  # Install unrar from source
  && cd /tmp \
  && wget https://www.rarlab.com/rar/unrarsrc-${UNRAR_VER}.tar.gz -O /tmp/unrar.tar.gz \
  && tar -xzf /tmp/unrar.tar.gz \
  && cd unrar \
  && make -f makefile \
  && install -Dm 755 unrar /usr/bin/unrar

FROM alpine@sha256:1304f174557314a7ed9eddb4eab12fed12cb0cd9809e4c28f29af86979a3c870

ENV APP_DIR="/app" CONFIG_DIR="/config" PUID="1000" PGID="1000" UMASK="002" TZ="Etc/UTC" ARGS=""
ENV XDG_CONFIG_HOME="${CONFIG_DIR}/.config" XDG_CACHE_HOME="${CONFIG_DIR}/.cache" XDG_DATA_HOME="${CONFIG_DIR}/.local/share" LANG="C.UTF-8" LC_ALL="C.UTF-8"
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

VOLUME ["${CONFIG_DIR}"]
ENTRYPOINT ["/init"]

# install packages
RUN apk add --no-cache tzdata shadow bash curl wget jq grep sed coreutils findutils python3 unzip p7zip ca-certificates

# copy unrar from builder
COPY --from=builder /usr/bin/unrar /usr/bin

# make folders
RUN mkdir "${APP_DIR}" && \
# create user
    useradd -u 1000 -U -d "${CONFIG_DIR}" -s /bin/false hotio && \
    usermod -G users hotio

# https://github.com/just-containers/s6-overlay/releases
ARG S6_VERSION=2.2.0.3

# install s6-overlay
RUN curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-amd64.tar.gz" | tar xzf - -C /

ARG BUILD_ARCHITECTURE
ENV BUILD_ARCHITECTURE=$BUILD_ARCHITECTURE

COPY root/ /
