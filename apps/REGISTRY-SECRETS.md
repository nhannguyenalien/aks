# Private container registries

Service blueprints reference an existing Secret by `registry_secret_name`.
They never contain registry passwords or tokens.

Create a namespace-scoped pull secret out-of-band:

```sh
kubectl -n <namespace> create secret docker-registry <secret-name> \
  --docker-server=ghcr.io \
  --docker-username='<username>' \
  --docker-password='<read-only-token>'
```

Use a read-only registry token and create the Secret in every namespace that
needs it. The rendered Deployment adds:

```yaml
imagePullSecrets:
  - name: <secret-name>
```

For production, replace manual Secrets with an external secret manager.
