# us-east1-docker.pkg.dev/tf-k8s-cluster-infra-9734/thirdparty/tbot-wrapped:18.6.4
FROM alpine:3.20

# Minimal deps for TLS + DNS
RUN apk add --no-cache ca-certificates tzdata bash

# --- Add the tbot binary (v18.1.6) ---
# Option A: COPY from your own build artifact
# COPY tbot /usr/local/bin/tbot
#
# Option B: pull official tarball at build time (example):
#   (Replace URL/checksum with what you use internally)
ARG TB_VERSION=18.1.6
ARG TB_OS=linux
ARG TB_ARCH=amd64

RUN set -eux; \
  wget -qO /tmp/teleport.tar.gz "https://cdn.teleport.dev/teleport-v${TB_VERSION}-${TB_OS}-${TB_ARCH}-bin.tar.gz"; \
  mkdir -p /tmp/teleport; \
  tar -xzf /tmp/teleport.tar.gz -C /tmp/teleport; \
  cp /tmp/teleport/teleport/tbot /usr/local/bin/tbot; \
  chmod +x /usr/local/bin/tbot; \
  rm -rf /tmp/teleport /tmp/teleport.tar.gz

# --- Wrapper that never exits ---
# Retries tbot forever; logs exit codes; configurable sleep.
ENV TBOT_RETRY_DELAY=10
ENV TBOT_ARGS="start"

# If TBOT_CONFIG is base64 (your current pattern), the binary reads it directly.
# Nothing else needed here.
CMD ["/bin/bash","-lc","\
  echo 'tbot wrapper: starting (retry delay='${TBOT_RETRY_DELAY}'s)'; \
  while true; do \
    /usr/local/bin/tbot ${TBOT_ARGS} || echo \"tbot exited with code $? — will retry\" >&2; \
    sleep \"${TBOT_RETRY_DELAY}\"; \
  done \
"]
