# Ocuspot deployment

Project: Ocuspot Deploy Demo

The carrier receives an already built container image from CI. Rathole client
configuration is generated per project and bound to the selected gateway to
avoid mixing unrelated gateways and carriers.

GitLab CI deploy is the preferred path for real deployments. Configure these
masked/protected CI variables before enabling deploy on the default branch:

- OCUSPOT_CONTROL_REPO_URL: HTTPS clone URL for the private ocuspot control repo.
- OCUSPOT_GITLAB_TOKEN: masked token allowed to clone the private control repo.
- OCUSPOT_SSH_PRIVATE_KEY: private key allowed to SSH into the selected carrier and gateway.
- OCUSPOT_CARRIER_SSH_PASSWORD / OCUSPOT_GATEWAY_SSH_PASSWORD: optional password-based bootstrap fallback when no SSH key is available.
- OCUSPOT_CLI: optional path to the ocuspot binary in the project image/worktree (defaults to ./ocuspot).
- RATHOLE_BIN: optional local path in the CI job to a rathole binary that should be uploaded to both hosts.

The deploy job clones the control repo, runs ocuspot deploy bundle --apply,
then executes the generated deploy.sh from GitLab CI after tests and image
build have succeeded.
