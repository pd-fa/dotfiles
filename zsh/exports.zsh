export FZF_DEPTH=3
# Derived from TMPDIR — the per-machine /var/folders ID differs on every host.
# podman names the socket after the machine, so "podman-machine-default" here is
# the machine name and not a generic suffix: rename the machine and this points
# at a socket that never appears, with no error from anything that reads it.
export DOCKER_HOST="unix://${TMPDIR}podman/podman-machine-default-api.sock"
