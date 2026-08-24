# Required secret

Do not commit the Cloudflare token. Create it out-of-band:

```sh
kubectl -n external-dns create secret generic cloudflare-api-token \
  --from-literal=api-token='<TOKEN>'
```

The token must be limited to zone `schoolsai.work` with `Zone:Read` and
`DNS:Edit`. The tunnel connector token is not a DNS API token.
