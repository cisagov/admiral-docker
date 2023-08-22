"""pytest plugin configuration.

https://docs.pytest.org/en/latest/writing_plugins.html#conftest-py-plugins
"""
# Third-Party Libraries
import pytest
from python_on_whales import DockerClient

MAIN_SERVICE_NAME = "admiral"
VERSION_SERVICE_NAME = f"{MAIN_SERVICE_NAME}-version"


@pytest.fixture(scope="session")
def dockerc():
    """Start up the Docker composition."""
    # Create the Docker client with our project name and compose file path
    docker = DockerClient(
        compose_files=["./docker-compose.yml"], compose_project_name=MAIN_SERVICE_NAME
    )
    docker.compose.up(detach=True)
    yield docker
    docker.compose.down()


# The Admiral's Docker composition does not define a main container. This part of the configuration needs to be modified to play nicely with the worker replicas. See #6 for more details.
#  @pytest.fixture(scope="session")
#  def main_container(dockerc):
#      """Return the main container from the Docker composition."""
#      # find the container by name even if it is stopped already
#      return dockerc.compose.ps(services=[MAIN_SERVICE_NAME], all=True)[0]


@pytest.fixture(scope="session")
def version_container(dockerc):
    """Return the version container from the Docker composition.

    The version container should just output the version of its underlying contents.
    """
    # find the container by name even if it is stopped already
    return dockerc.compose.ps(services=[VERSION_SERVICE_NAME], all=True)[0]


def pytest_addoption(parser):
    """Add new commandline options to pytest."""
    parser.addoption(
        "--runslow", action="store_true", default=False, help="run slow tests"
    )


def pytest_collection_modifyitems(config, items):
    """Modify collected tests based on custom marks and commandline options."""
    if config.getoption("--runslow"):
        # --runslow given in cli: do not skip slow tests
        return
    skip_slow = pytest.mark.skip(reason="need --runslow option to run")
    for item in items:
        if "slow" in item.keywords:
            item.add_marker(skip_slow)
