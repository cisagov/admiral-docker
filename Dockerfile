ARG PYTHON_IMAGE_VERSION=3.11.2-alpine
ARG VERSION=2.2.0

# Official Docker images are in the form library/<app> while non-official
# images are in the form <user>/<app>.
FROM docker.io/library/python:${PYTHON_IMAGE_VERSION} AS compile-stage

###
# Unprivileged user variables
###
ARG CISA_USER="cisa"
ENV CISA_HOME="/home/${CISA_USER}"
ENV VIRTUAL_ENV="${CISA_HOME}/.venv"

# Versions of the Python packages installed directly
ENV PYTHON_PIP_VERSION=22.3.1
ENV PYTHON_PIPENV_VERSION=2025.0.4
ENV PYTHON_SETUPTOOLS_VERSION=70.3.0
ENV PYTHON_WHEEL_VERSION=0.38.4

###
# Install the specified versions of pip, setuptools, and wheel;
# install the specified version of pipenv; create the image dependency
# venv; and install the specified versions of pip, setuptools, and
# wheel into the dependency venv.
#
# Note that we use the --no-cache-dir flag to avoid writing to a local
# cache.  This results in a smaller final image, at the cost of
# slightly longer install times.
###
RUN python3 -m pip install --no-cache-dir --upgrade \
        pip==${PYTHON_PIP_VERSION} \
        setuptools==${PYTHON_SETUPTOOLS_VERSION} \
        wheel==${PYTHON_WHEEL_VERSION} \
    && python3 -m pip install --no-cache-dir --upgrade \
        pipenv==${PYTHON_PIPENV_VERSION} \
    # Manually create the virtual environment
    && python3 -m venv ${VIRTUAL_ENV} \
    # Ensure the core Python packages are installed in the virtual environment
    && ${VIRTUAL_ENV}/bin/python3 -m pip install --no-cache-dir --upgrade \
        pip==${PYTHON_PIP_VERSION} \
        setuptools==${PYTHON_SETUPTOOLS_VERSION} \
        wheel==${PYTHON_WHEEL_VERSION}

###
# Install the Python dependencies into the virtual environment.
#
# Note that pipenv will install into a virtual environment if the VIRTUAL_ENV
# environment variable is set.
###
WORKDIR /tmp
COPY src/Pipfile src/Pipfile.lock ./
RUN pipenv install --clear --deploy --extra-pip-args "--no-cache-dir" --verbose

# Official Docker images are in the form library/<app> while non-official
# images are in the form <user>/<app>.
FROM docker.io/tonistiigi/xx AS xx

FROM docker.io/library/python:${PYTHON_IMAGE_VERSION} AS build-stage

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
ENV VIRTUAL_ENV="${CISA_HOME}/.venv"

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
ENV DEPS="ca-certificates make openssl py-pip"
ARG TARGET_PLATFORM
RUN xx-apk --no-cache --quiet add ${DEPS}

# Copy in the Python virtual environment created in compile-stage, symlink the
# Python binary in the venv to the system-wide Python, and add the venv to the PATH.
#
# Note that we symlink the Python binary in the venv to the system-wide Python so that
# any calls to `python3` will use our virtual environment. We are using short flags
# because the ln binary in Alpine Linux does not support long flags. The -f instructs
# ln to remove the existing file and the -s instructs ln to create a symbolic link.
###
COPY --from=compile-stage --chown=${CISA_USER}:${CISA_GROUP} ${VIRTUAL_ENV} ${VIRTUAL_ENV}
RUN ln -fs "$(command -v python3)" "${VIRTUAL_ENV}"/bin/python3
ENV PATH="${VIRTUAL_ENV}/bin:$PATH"

###
# Prepare to run
###
WORKDIR ${CISA_HOME}
USER ${CISA_USER}:${CISA_GROUP}
ENTRYPOINT ["admiral"]
