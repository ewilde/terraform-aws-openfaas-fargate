FROM alpine:3.7 AS build-env
RUN apk update && apk add curl wget unzip
RUN wget -O nat.zip https://github.com/nats-io/nats-streaming-server/releases/download/v0.9.2/nats-streaming-server-v0.9.2-linux-amd64.zip
RUN unzip -p nat.zip nats-streaming-server-v0.9.2-linux-amd64/nats-streaming-server > nats-streaming-server
RUN chmod +x nats-streaming-server


FROM alpine:3.7
COPY --from=build-env /nats-streaming-server /

# Expose client and management ports
EXPOSE 4222 8222

# Run with default memory based store
ENTRYPOINT ["/nats-streaming-server"]
CMD ["-m", "8222"]
