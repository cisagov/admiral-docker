ARG PYTHON_IMAGE_VERSION=3.10.4-alpine
ARG VERSION=1.3.0

FROM tonistiigi/xx AS xx

FROM python:${PYTHON_IMAGE_VERSION} as build-stage

ARG VERSION

###
# For a list of pre-defined annotation keys and value types see:
# https://github.com/opencontainers/image-spec/blob/master/annotations.md
#
# Note: Additional labels are added by the build workflow.
###
LABEL org.opencontainers.image.authors="alexander.king@cisa.dhs.gov"
LABEL org.opencontainers.image.vendor="Cybersecurity and Infrastructure Security Agency"
LABEL org.opencontainers.image.version=${VERSION}

###
# Unprivileged user setup variables
###
ARG CISA_UID=421
ARG CISA_GID=${CISA_UID}
ARG CISA_USER="cisa"
ENV CISA_GROUP=${CISA_USER}
ENV CISA_HOME="/home/${CISA_USER}"

###
# Admiral configuration variables
###
ENV ADMIRAL_CONFIG_FILE="/run/secrets/admiral.yml"
ENV ADMIRAL_CONFIG_SECTION="dev-mode"
ENV ADMIRAL_WORKER_NAME="dev"

###
# Upgrade the system
#
# Note that we use apk --no-cache to avoid writing to a local cache.
# This results in a smaller final image, at the cost of slightly
# longer install times.
###
COPY --from=xx / /
RUN apk --update --no-cache --quiet upgrade
ARG TARGET_PLATFORM
RUN xx-apk add --no-cache xx-c-essentials \
    && xx-apk add libffi-dev

###
# Create unprivileged user
###
RUN addgroup --system --gid ${CISA_GID} ${CISA_GROUP} \
    && adduser --system --uid ${CISA_UID} --ingroup ${CISA_GROUP} ${CISA_USER}

###
# Dependencies
#
# Note that we use apk --no-cache to avoid writing to a local cache.
# This results in a smaller final image, at the cost of slightly
# longer install times.
###
ENV DEPS \
    ca-certificates \
    make \
    openssl \
    py-pip
ARG TARGET_PLATFORM
RUN xx-apk --no-cache --quiet add ${DEPS}

###
# Make sure pip, setuptools, and wheel are the latest versions
#
# Note that we use pip3 --no-cache-dir to avoid writing to a local
# cache.  This results in a smaller final image, at the cost of
# slightly longer install times.
###
RUN pip3 install --no-cache-dir --upgrade \
    pip \
    setuptools \
    wheel

WORKDIR ${CISA_HOME}

###
# Install Python dependencies
#
# Note that we use pip3 --no-cache-dir to avoid writing to a local
# cache.  This results in a smaller final image, at the cost of
# slightly longer install times.
###
RUN wget --output-document sourcecode.tgz \
    https://github.com/cisagov/admiral/archive/v${VERSION}.tar.gz \
    && tar --extract --gzip --file sourcecode.tgz --strip-components=1 \
    && pip3 install --no-cache-dir --requirement requirements.txt

###
# Prepare to run
###
USER ${CISA_USER}:${CISA_GROUP}
ENTRYPOINT ["admiral"]
