# ================================
# Build image
# ================================
FROM swiftlang/swift:nightly-6.0-jammy as build

RUN apt-get update && apt-get install -y libjemalloc-dev

WORKDIR /build

COPY ./Package.* ./
RUN swift package resolve --force-resolved-versions

COPY . .
RUN swift build -c release \
                --static-swift-stdlib \
                -Xlinker -ljemalloc

# ================================
# Run image
# ================================
FROM ubuntu:jammy

RUN apt-get update && apt-get install -y libjemalloc2 ca-certificates tzdata libcurl4 libxml2 && rm -r /var/lib/apt/lists/*

RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

WORKDIR /app

COPY --from=build --chown=vapor:vapor /build/.build/release/App /app

USER vapor:vapor

EXPOSE 8080

ENTRYPOINT ["./App"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
