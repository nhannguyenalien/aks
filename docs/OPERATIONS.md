# SchoolsAI K3s Operations Guide

## Public naming convention

Every generated public service uses exactly:

```text
<service-name>-vps.schoolsai.work
```

Cloudflare has one wildcard published application:

```text
*.schoolsai.work -> http://traefik.kube-system.svc.cluster.local:80
```

Existing exact DNS records take precedence over the wildcard. Kubernetes
Ingress selects the backend from the original HTTP Host header. Cloudflare
provides public HTTPS; services communicate with Traefik over the private
cluster network.

## Service deployment API

Documentation: `https://api-vps.schoolsai.work/docs`

Deployment requires both headers:

```http
Authorization: Bearer <API_KEY>
X-Deploy-Key: <DEPLOY_KEY>
```

Required invariants:

- `name`: Kubernetes DNS label.
- `namespace`: exactly `schoolsai-<name>`.
- `hostname`: exactly `<name>-vps.schoolsai.work`.
- `image`: version tag or digest; `latest` is rejected.
- `health_path`: HTTP endpoint used for readiness and liveness.
- private images only reference `registry_secret_name`; credentials never go
  in a blueprint or Git.

The API clones Git, writes `apps/<name>/`, commits and pushes. Argo CD then
reconciles the commit. A successful HTTP 202 means the commit was accepted,
not that rollout health is already complete.

## GitOps and rollback

Repository: `git@github.com:nhannguyenalien/aks.git`, branch `main`.

Argo applications:

- `schoolsai-apps`: generated application workloads.
- `schoolsai-monitoring`: Prometheus/Grafana/Alertmanager.

Rollback is performed by reverting the deployment commit and pushing `main`.
Argo CD self-heal is enabled; manual cluster edits will be reverted.

## Monitoring

- Grafana: `https://grafana-vps.schoolsai.work`
- Prometheus retention: 7 days / 12 GB maximum.
- Prometheus PVC: 15 GiB on `k3s-pve`.
- Grafana PVC: 5 GiB on `k3s-promox`.
- Alertmanager PVC: 2 GiB on `k3s-pve`.

Monitoring data uses node-local volumes. It survives pod restarts but not loss
of the Proxmox node or its storage.

## Secret policy

- Never commit API, deploy, registry, Cloudflare or Git private keys.
- Use read-only registry tokens for pull secrets.
- Rotate a key immediately if it appears in source control or public logs.
- Kubernetes Secrets are base64 encoded, not encrypted at rest by default.

## Backup scope

Required backup assets:

1. GitHub repository (desired state and revision history).
2. K3s server datastore and `/var/lib/rancher/k3s/server/token`.
3. Namespace Secrets created outside Git.
4. Application persistent volumes.

A local datastore backup is not an off-site backup. Copy backups to storage
outside `k3s-promox` and test restore regularly.
