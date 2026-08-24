# Deployment API example

```sh
curl -X POST https://api-vps.schoolsai.work/api/v1/deployments \
  -H 'Authorization: Bearer <API_KEY>' \
  -H 'X-Deploy-Key: <DEPLOY_KEY>' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "student-api",
    "namespace": "schoolsai-student-api",
    "image": "ghcr.io/schoolsai/student-api:1.4.2",
    "container_port": 8000,
    "replicas": 2,
    "hostname": "student-api-vps.schoolsai.work",
    "health_path": "/health",
    "public": true
  }'
```

Expected response status is HTTP 202. Track the returned `git_revision` in
GitHub and Argo CD. Repeating an identical blueprint returns `unchanged`.
