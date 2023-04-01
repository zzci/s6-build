ARG SKALIBS_VERSION="2.13.1.0"
ARG EXECLINE_VERSION="2.9.2.1"
ARG S6_VERSION="2.11.3.0"

FROM alpine:3.17 AS base
RUN apk --update --no-cache add patch bash clang curl git llvm make tar tree xz musl-dev gcc g++ linux-headers
WORKDIR /src

FROM base AS src-skalibs
ARG SKALIBS_VERSION
RUN curl -sSL "https://skarnet.org/software/skalibs/skalibs-${SKALIBS_VERSION}.tar.gz" | tar xz --strip 1

FROM base AS src-execline
ARG EXECLINE_VERSION
RUN curl -sSL "https://skarnet.org/software/execline/execline-${EXECLINE_VERSION}.tar.gz" | tar xz --strip 1

FROM base AS src-s6
ARG S6_VERSION
RUN curl -sSL "https://skarnet.org/software/s6/s6-${S6_VERSION}.tar.gz" | tar xz --strip 1

FROM base AS build

WORKDIR /usr/local/src/skalibs
COPY --from=src-skalibs /src .
RUN  \
  set -ex; \
  ./configure --enable-static-libc --disable-shared \
  --with-default-path=/command:/build/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin --with-sysdep-devurandom=yes; \
  make -j$(nproc); \
  make install -j$(nproc)


WORKDIR /usr/local/src/execline
COPY --from=src-execline /src .
RUN  \
  set -ex && \
  ./configure --enable-static-libc --disable-shared --disable-pedantic-posix; \
  make -j$(nproc); \
  make install  -j$(nproc)

WORKDIR /usr/local/src/s6
COPY --from=src-s6 /src .
RUN  \
  set -ex; \
  DESTDIR=/out ./configure --enable-static-libc --disable-shared ; \
  make -j$(nproc); \
  make DESTDIR=/out install -j$(nproc)

FROM alpine:3.17 AS final

ENV PATH=/command/bin:$PATH

COPY --from=build /out/bin /command/bin
RUN apk --no-cache add ttyd nginx

ADD rootfs /

WORKDIR /work