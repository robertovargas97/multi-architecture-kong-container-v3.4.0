FROM ubuntu:jammy

LABEL maintainer="Kong Docker Maintainers <docker@konghq.com> (@team-gateway-bot)"

ARG ASSET=ce
ENV ASSET $ASSET

ARG EE_PORTS

COPY kong.deb /tmp/kong.deb

ARG KONG_VERSION=3.4.0
ENV KONG_VERSION $KONG_VERSION

ARG KONG_AMD64_SHA="9a4203174a29895d5dd71092a05b15b26ee9644e068d14d970aed28461d358fa"
ARG KONG_ARM64_SHA="b64e19216ce125039a6a832dc93bf277e05f233a91f1647b351cad3f166edd81"

# hadolint ignore=DL3015
RUN set -ex; \
    arch=$(dpkg --print-architecture); \
    case "${arch}" in \
      amd64) KONG_SHA256=$KONG_AMD64_SHA ;; \
      arm64) KONG_SHA256=$KONG_ARM64_SHA ;; \
    esac; \
    apt-get update \
    && if [ "$ASSET" = "ce" ] ; then \
      apt-get install -y curl curl nano sudo \
      && UBUNTU_CODENAME=$(cat /etc/os-release | grep UBUNTU_CODENAME | cut -d = -f 2) \
      && curl -fL https://download.konghq.com/gateway-${KONG_VERSION%%.*}.x-ubuntu-${UBUNTU_CODENAME}/pool/all/k/kong/kong_${KONG_VERSION}_$arch.deb -o /tmp/kong.deb \
      && curl -fL https://raw.githubusercontent.com/IVRTech/wait-for-it/master/wait-for-it.sh -o /wait-for-it.sh \
      && chmod +x /wait-for-it.sh \
      && apt-get purge -y curl \
      && echo "$KONG_SHA256  /tmp/kong.deb" | sha256sum -c - \
      || exit 1; \
    else \
      # this needs to stay inside this "else" block so that it does not become part of the "official images" builds (https://github.com/docker-library/official-images/pull/11532#issuecomment-996219700)
      apt-get upgrade -y ; \
    fi; \
    apt-get install -y --no-install-recommends unzip git \
    && apt install --yes /tmp/kong.deb \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/kong.deb \
    && ln -sf /usr/local/openresty/bin/resty /usr/local/bin/resty \
    && ln -sf /usr/local/openresty/luajit/bin/luajit /usr/local/bin/luajit \
    && ln -sf /usr/local/openresty/luajit/bin/luajit /usr/local/bin/lua \
    && ln -sf /usr/local/openresty/nginx/sbin/nginx /usr/local/bin/nginx \
    && if [ "$ASSET" = "ce" ] ; then \
      kong version ; \
    fi

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8000 8443 8001 8444 $EE_PORTS

STOPSIGNAL SIGQUIT

HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health

CMD ["kong", "docker-start"]