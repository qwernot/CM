FROM alpine:3.22
USER root
COPY cmsingbox /usr/local/bin/cmsingbox
VOLUME ["/data"]
EXPOSE 9092/tcp 2080/tcp 53/tcp 53/udp
ENTRYPOINT ["/usr/local/bin/cmsingbox", "-data", "/data", "-port", "9092"]

