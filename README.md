# admiral-docker 💀🐳 #

[![GitHub Build Status](https://github.com/cisagov/admiral-docker/workflows/build/badge.svg)](https://github.com/cisagov/admiral-docker/actions/workflows/build.yml)
[![CodeQL](https://github.com/cisagov/admiral-docker/workflows/CodeQL/badge.svg)](https://github.com/cisagov/admiral-docker/actions/workflows/codeql-analysis.yml)
[![Known Vulnerabilities](https://snyk.io/test/github/cisagov/admiral-docker/badge.svg)](https://snyk.io/test/github/cisagov/admiral-docker)

## Docker Image ##

[![Docker Pulls](https://img.shields.io/docker/pulls/cisagov/admiral)](https://hub.docker.com/r/cisagov/admiral)
[![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/cisagov/admiral)](https://hub.docker.com/r/cisagov/admiral)
[![Platforms](https://img.shields.io/badge/platforms-amd64%20%7C%20arm%2Fv6%20%7C%20arm%2Fv7%20%7C%20arm64%20%7C%20ppc64le%20%7C%20s390x-blue)](https://hub.docker.com/r/cisagov/admiral-docker/tags)

This Docker project serves as the vessel for certificate transparency
scanning performed by the [admiral Python library](https://github.com/cisagov/admiral).

## Running ##

### Running with Docker Compose ###

1. Change the credentials in `secrets`
1. Choose configuration options for `admiral.yml`
1. Start the container and detach:

    ```console
    docker compose up --detach
    ```

## Monitoring ##

The following web services are started for monitoring the underlying components:

- Celery Flower: [http://localhost:5555](http://localhost:5555)
- Mongo Express: [http://localhost:8083](http://localhost:8083)
- Redis Commander: [http://localhost:8082](http://localhost:8082)

## Using secrets ##

This composistion passes credentials and configuration options via [Docker
secrets](https://docs.docker.com/engine/swarm/secrets/). You need to modify
the files listed in the [secrets](#secrets) section below. To prevent yourself
from inadvertently committing sensitive values to the repository, run
`git update-index --assume-unchanged src/secrets/*`.

## Updating your container ##

### Docker Compose ###

1. Pull the new image from Docker Hub:

    ```console
    docker compose pull
    ```

1. Recreate the running container by following the [previous instructions](#running-with-docker-compose):

    ```console
    docker compose up --detach
    ```

## Image tags ##

The images of this container are tagged with [semantic
versions](https://semver.org) of the [admiral](https://github.com/cisagov/admiral)
Python library that they containerize.  It is recommended that most users
use a version tag (e.g. `:1.4.0`).

| Image:tag | Description |
|-----------|-------------|
|`cisagov/admiral:1.4.0`| An exact release version. |
|`cisagov/admiral:1.3`| The most recent release matching the major and minor version numbers. |
|`cisagov/admiral:1`| The most recent release matching the major version number. |
|`cisagov/admiral:edge` | The most recent image built from a merge into the `develop` branch of this repository. |
|`cisagov/admiral:nightly` | A nightly build of the `develop` branch of this repository. |
|`cisagov/admiral:latest`| The most recent release image pushed to a container registry.  Pulling an image using the `:latest` tag [should be avoided.](https://vsupalov.com/docker-latest-tag/) |

See the [tags tab](https://hub.docker.com/r/cisagov/admiral/tags) on Docker
Hub for a list of all the supported tags.

## Volumes ##

| Mount point | Purpose        |
|-------------|----------------|
| `mongo-init.js`  |  Stores the initialization script for MongoDB   |

## Ports ##

The following ports are exposed by this container:

| Port | Purpose        |
|------|----------------|
| 5555 | Celery Flower |
| 6379 | Redis |
| 8081 | Redis Commander |
| 8083 | Mongo Express |

## Environment variables ##

### Required ###

There are no required environment variables.

<!--
| Name  | Purpose | Default |
|-------|---------|---------|
| `REQUIRED_VARIABLE` | Describe its purpose. | `null` |
-->

### Optional ###

| Name  | Purpose | Default |
|-------|---------|---------|
| `ADMIRAL_CONFIG_FILE` | Celery configuration | `admiral.yml` |
| `ADMIRAL_CONFIG_SECTION` | Configuration section to use  | `dev-mode` |
| `ADMIRAL_WORKER_NAME` | Worker names | `dev` |
| `CISA_HOME` | Home folder | `/home/cisa` |
| `CISA_GROUP` | Group identifier | `cisa` |

## Secrets ##

| Filename     | Purpose |
|--------------|---------|
| `admiral.yml` | Celery configuration |
| `mongo.yml` | MongoDB configuration |
| `mongo-root-passwd.txt` | MongoDB root password |
| `redis.conf` | Redis configuration |
| `sslmate-api-key.txt` | API key for SSLMate's Certificate Transparency Search API |

## Building from source ##

Build the image locally using this git repository as the [build context](https://docs.docker.com/engine/reference/commandline/build/#git-repositories):

```console
docker build \
  --build-arg VERSION=0.0.1 \
  --tag cisagov/admiral:1.4.0 \
  https://github.com/cisagov/admiral-docker.git#develop
```

## Cross-platform builds ##

To create images that are compatible with other platforms, you can use the
[`buildx`](https://docs.docker.com/buildx/working-with-buildx/) feature of
Docker:

1. Copy the project to your machine using the `Code` button above
   or the command line:

    ```console
    git clone https://github.com/cisagov/admiral-docker.git
    cd example
    ```

1. Create the `Dockerfile-x` file with `buildx` platform support:

    ```console
    ./buildx-dockerfile.sh
    ```

1. Build the image using `buildx`:

    ```console
    docker buildx build \
      --file Dockerfile-x \
      --platform linux/amd64 \
      --build-arg VERSION=0.0.1 \
      --output type=docker \
      --tag cisagov/admiral:1.4.0 .
    ```

## Contributing ##

We welcome contributions!  Please see [`CONTRIBUTING.md`](CONTRIBUTING.md) for
details.

## License ##

This project is in the worldwide [public domain](LICENSE).

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain
dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.
