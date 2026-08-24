# SchoolsAI K3s GitOps

This repository is the desired-state source for the SchoolsAI K3s cluster.
Argo CD applies reviewed changes from Git; public APIs must not apply arbitrary
objects directly to Kubernetes.

## Layout

- `bootstrap/`: Argo CD projects and root applications.
- `platform/`: shared platform components such as ExternalDNS.
- `apps/`: application manifests generated from approved service blueprints.
- `docs/`: operator and API usage documentation.

Start with [`docs/OPERATIONS.md`](docs/OPERATIONS.md) and
[`docs/API_EXAMPLE.md`](docs/API_EXAMPLE.md).

## Deployment workflow

1. Validate a versioned service blueprint.
2. Render Kubernetes resources.
3. Review image provenance, secrets, resources, hostname and rollback plan.
4. Commit the approved manifests to `apps/<service>/`.
5. Argo CD synchronizes the commit and records its revision.
6. Verify rollout and health; revert the Git commit to roll back.

Secrets are never committed. Create them through a secret manager or a
restricted bootstrap operation, and reference them by name from workloads.
