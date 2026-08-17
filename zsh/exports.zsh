export FZF_DEPTH=3
# Derived from TMPDIR — the per-machine /var/folders ID differs on every host
export DOCKER_HOST="unix://${TMPDIR}podman/podman-machine-api.sock"
