# Used by GoReleaser (dockers_v2): the binaries are prebuilt per platform and
# placed under $TARGETPLATFORM/ in the build context.
FROM gcr.io/distroless/static-debian12:nonroot

ARG TARGETPLATFORM
COPY $TARGETPLATFORM/fortune $TARGETPLATFORM/fortune-server /usr/local/bin/

EXPOSE 3108
USER nonroot:nonroot
ENTRYPOINT ["/usr/local/bin/fortune-server"]
