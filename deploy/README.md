# Ocuspot deployment

Project: Ocuspot Deploy Demo

The carrier receives an already built container image from CI. Rathole client
configuration is generated per project and bound to the selected gateway to
avoid mixing unrelated gateways and carriers.

GitLab CI deploy is the preferred path for real deployments. Configure these
masked/protected CI variables before enabling deploy on the default branch:

- OCUSPOT_SSH_PRIVATE_KEY: private key allowed to SSH into the selected carrier and gateway.
- OCUSPOT_CARRIER_SSH_PASSWORD / OCUSPOT_GATEWAY_SSH_PASSWORD: optional password-based bootstrap fallback when no SSH key is available.
- RATHOLE_BIN: optional local path in the CI job to a rathole binary that should be uploaded to both hosts.

The repository contains no Ocuspot executable. The local "ocuspot create"
command generated deploy/deploy.sh from the private control registry. GitLab CI
substitutes the immutable image built for the current commit and executes that
script only after tests and image build have succeeded.
