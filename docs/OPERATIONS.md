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

## AnythingLLM

- URL: `https://anythingllm-vps.schoolsai.work`
- Namespace: `schoolsai-anythingllm`
- Image: `mintplexlabs/anythingllm:1.16.0`
- Runtime: one replica pinned to `k3s-pve`.
- Persistent storage: 10 GiB local-path PVC mounted at
  `/app/server/storage`.
- Health endpoint: `/api/ping`.

AnythingLLM uses stateful local storage, so its deployment strategy is
`Recreate`; do not scale it horizontally without first moving its database and
storage to a multi-instance architecture. The first visitor completes the
AnythingLLM setup wizard and creates the administrator account. Provider API
keys entered in AnythingLLM are application data and must never be committed
to this repository.

The PVC is node-local on `k3s-pve`. Include its underlying local-path data in
application-volume backups; the K3s datastore backup alone does not contain
the files stored in the PVC.

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

### Installed schedule

- `k3s-promox` VM: consistent SQLite backup daily at approximately 03:15 ICT
  (`20:15 UTC` on the VM timer).
- `pve` physical host: pull to `/mnt/pve/hdd4tb/k3s-backups` at approximately
  03:35.
- Local retention: 14 days; second-host retention: 30 days.
- Every backup runs SQLite `PRAGMA integrity_check` and creates SHA-256 data.

Inspect timers and recent logs:

```sh
systemctl list-timers 'k3s-*'
journalctl -u k3s-datastore-backup.service
journalctl -u pull-k3s-backup.service
```

### Datastore restore outline

1. Provision the same K3s version and preserve the server token.
2. Stop `k3s`.
3. Preserve the failed `/var/lib/rancher/k3s/server/db` directory separately.
4. Extract the verified archive and restore `state.db` and `token` with root-only
   permissions.
5. Start `k3s`, verify nodes/workloads, then verify Argo CD reconciliation.

Perform restore testing on a disposable VM. Do not test restoration against the
live control-plane.
