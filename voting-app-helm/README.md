# Voting app Helm chart (local development)

Designed for the existing GHCR images produced by GitHub Actions.

## Requirements
- Kubernetes cluster and Helm 3
- Images must be publicly pullable, or configure imagePullSecrets
- Create a database Secret in the SAME namespace before installing:

```bash
kubectl create namespace voting --dry-run=client -o yaml | kubectl apply -f -
kubectl -n voting create secret generic voting-db-credentials --from-literal=password='CHOOSE_A_LOCAL_PASSWORD'
```

**Important:** Confirm the application actually reads the same database credentials. The original worker may hard-code `postgres` / `postgres` instead of reading env vars. If so, adapt worker code and rebuild before deployment. The vote and result applications may likewise have hardcoded service hostnames; confirm these match `redis` and `db`.

Install with the full SHA from the successful `main` workflow:

```bash
helm lint ./voting-app-helm
helm template voting ./voting-app-helm --namespace voting --set global.imageTag=FULL_COMMIT_SHA
helm upgrade --install voting ./voting-app-helm -n voting --set global.imageTag=FULL_COMMIT_SHA --wait --timeout 5m
kubectl -n voting get pods,svc
```

For rollback demonstration, install a deliberately invalid tag, inspect failure, then `helm rollback voting <GOOD_REVISION> -n voting`. To record a failed upgrade revision, avoid `--atomic` / `--cleanup-on-fail` and inspect `helm history voting -n voting`.

Caveats: PostgreSQL uses emptyDir, so data disappears if its pod is replaced; for persistent environments replace it with a PVC. Redis/Postgres images use mutable tags and need digest pinning. The GHCR images must be accessible to your cluster. This chart has not yet been cluster-tested.
