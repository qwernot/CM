FROM debian:bookworm-slim
USER root
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates tzdata && rm -rf /var/lib/apt/lists/*
COPY cmsingbox /usr/local/bin/cmsingbox
COPY sing-box /usr/local/libexec/sing-box
VOLUME ["/data"]
EXPOSE 9092/tcp 2080/tcp 53/tcp 53/udp
ENTRYPOINT ["/bin/sh", "-c", "mkdir -p /data/bin; if [ ! -x /data/bin/sing-box ]; then cp /usr/local/libexec/sing-box /data/bin/sing-box; chmod 0755 /data/bin/sing-box; fi; exec /usr/local/bin/cmsingbox -data /data -port 9092"]
