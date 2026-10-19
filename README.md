[![forthebadge](https://forthebadge.com/images/badges/made-with-crayons.svg)](https://forthebadge.com)
[![forthebadge](https://forthebadge.com/images/badges/designed-in-etch-a-sketch.svg)](https://forthebadge.com)
[![forthebadge](https://forthebadge.com/images/badges/you-didnt-ask-for-this.svg)](https://forthebadge.com)

# fortune

go implementation of fortune (I was bored).

Fortune files obtained from [fortunes.cat-v.org](http://fortunes.cat-v.org/) and [fortune-mod](https://github.com/shlomif/fortune-mod)

## Running fortune-server

```sh
go run ./cmd/fortune-server   # listens on :3108, or $PORT
curl localhost:3108/
```

Endpoints: `/` returns a random fortune, `/healthz` returns `ok`.

## Container image and Kubernetes

Releases publish a multi-arch (linux/amd64, linux/arm64) image built with
[ko](https://ko.build): `ghcr.io/jvzantvoort/fortune-server:<version>`. It is
distroless, runs as non-root and carries an SPDX SBOM.

To build from source and deploy to the current Kubernetes context:

```sh
KO_DOCKER_REPO=ghcr.io/<you> ko apply --bare -f deploy/kubernetes/
```
