# PostgreSQL Benchmark Helm Chart

This Helm chart deploys a Kubernetes Job that runs pgbench benchmarks against a CloudNativePG (CNPG) cluster.

## Prerequisites

- Kubernetes cluster with CNPG operator installed
- A CNPG cluster deployed in a specific namespace
- Helm 3.x installed
- Helmfile for easier deployment

## Configuration

### PostgreSQL Connection

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgres.host` | PostgreSQL host (CNPG service) | `cluster-rw.tchap-pgbench.svc.cluster.local` |
| `postgres.port` | PostgreSQL port | `5432` |
| `postgres.database` | Database name | `app` |
| `postgres.username` | Database user | `app` |
| `postgres.existingSecret` | Existing secret with password | `""` |
| `postgres.password` | Password (if not using existingSecret) | `""` |

### Benchmark Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `benchmark.scaleFactor` | pgbench scale factor (100 = ~1.5GB) | `100` |
| `benchmark.testDuration` | Duration of each test in seconds | `60` |

### Job Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `job.restartPolicy` | Job restart policy | `Never` |
| `job.backoffLimit` | Number of retries | `2` |
| `job.ttlSecondsAfterFinished` | TTL for cleanup | `3600` |

### Resource Limits

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.limits.cpu` | CPU limit | `2000m` |
| `resources.limits.memory` | Memory limit | `2Gi` |
| `resources.requests.cpu` | CPU request | `1000m` |
| `resources.requests.memory` | Memory request | `1Gi` |

### Results Persistence

| Parameter | Description | Default |
|-----------|-------------|---------|
| `results.enabled` | Enable PVC for results | `true` |
| `results.storageClass` | Storage class | `""` (default) |
| `results.size` | PVC size | `5Gi` |
| `results.accessMode` | Access mode | `ReadWriteOnce` |

## Viewing Results

### Watch Job Progress

```bash
kubectl logs -f -n tchap-pgbench job/pgbench-job-<timestamp>
```

### Access Results

If persistence is enabled, results are stored in a PVC. To access them:

```bash
# Create a debug pod to access the PVC
kubectl run -it --rm debug \
  --image=busybox \
  --namespace=tchap-pgbench \
  --restart=Never \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "debug",
      "image": "busybox",
      "stdin": true,
      "tty": true,
      "volumeMounts": [{
        "name": "results",
        "mountPath": "/results"
      }]
    }],
    "volumes": [{
      "name": "results",
      "persistentVolumeClaim": {
        "claimName": "pgbench-job-results"
      }
    }]
  }
}' \
  -- sh

# Inside the pod, view results
ls -la /results/
cat /results/*_summary.txt
```

## Benchmark Tests

The benchmark runs the following tests:

1. **Read-Only Workload** - SELECT-only queries
2. **Simple Write Workload** - TPC-B like transactions
3. **Read-Write Mixed** - Mixed workload
4. **Low Concurrency** - 1 client
5. **Medium Concurrency** - 16 clients
6. **High Concurrency** - 32 clients
7. **Very High Concurrency** - 64 clients
8. **Prepared Statements** - Using prepared statements
9. **Extended Protocol** - Using extended protocol

## Customizing Tests

You can customize individual test parameters in `values.yaml`:

```yaml
benchmark:
  tests:
    readonly:
      clients: 16  # Increase clients
      threads: 4   # Increase threads
    # ... other tests
```

## CNPG Integration

The chart is designed to work with CloudNativePG clusters. CNPG automatically creates:

- Service: `<cluster-name>-rw` (read-write)
- Service: `<cluster-name>-ro` (read-only)
- Secret: `<cluster-name>-app` (contains app user password)

Update the `postgres.host` and `postgres.existingSecret` values to match your cluster name.

## Cleanup

### Using Helmfile
```bash
helmfile destroy
```

### Using Helm
```bash
helm uninstall pgbench-job --namespace tchap-pgbench
```

The Job will auto-delete after `ttlSecondsAfterFinished` (default: 1 hour).

## Troubleshooting

### Job Failed
```bash
kubectl describe job -n tchap-pgbench pgbench-job-<timestamp>
kubectl logs -n tchap-pgbench job/pgbench-job-<timestamp>
```

### Connection Issues
Verify CNPG cluster service:
```bash
kubectl get svc -n tchap-pgbench
kubectl get secrets -n tchap-pgbench
```

### Permission Issues
Ensure the database user has necessary permissions:
```sql
GRANT ALL ON DATABASE app TO app;
```
