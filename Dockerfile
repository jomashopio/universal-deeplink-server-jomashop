# Build image
FROM crystallang/crystal:1.19.2-alpine AS builder
WORKDIR /opt
# Cache dependencies
COPY ./shard.yml ./shard.lock /opt/
RUN shards install -v
# Build a binary
COPY . /opt/
RUN crystal build --static --release ./src/server.cr
# ===============
# Result image with one layer
FROM alpine:latest
WORKDIR /
COPY --from=builder /opt/server .
COPY --from=builder /opt/apple-app-site-association .
COPY --from=builder /opt/assetlinks.json .
ENTRYPOINT ["./server"]
