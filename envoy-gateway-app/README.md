# envoy-gateway-policies

Helm chart for deploying [Envoy Gateway](https://gateway.envoyproxy.io) policy
resources to Kubernetes. Covers the full policy surface of the **Gateway API**
and **Envoy Gateway** extensions.

## Supported Resources

| Kind | API Group | Description |
|------|-----------|-------------|
| `SecurityPolicy` | `gateway.envoyproxy.io/v1alpha1` | JWT, OIDC, BasicAuth, API Key, CORS, Authorization, ExtAuth |
| `BackendTLSPolicy` | `gateway.networking.k8s.io/v1alpha3` | Upstream TLS / mTLS validation |
| `BackendLBPolicy` | `gateway.envoyproxy.io/v1alpha1` | Load balancing & session persistence |
| `ClientTrafficPolicy` | `gateway.envoyproxy.io/v1alpha1` | Listener TLS, HTTP/2, connection limits, timeouts |
| `BackendTrafficPolicy` | `gateway.envoyproxy.io/v1alpha1` | Retry, timeout, circuit breaker, rate limit, health check |
| `EnvoyPatchPolicy` | `gateway.envoyproxy.io/v1alpha1` | Low-level xDS JSON patches |
| `EnvoyExtensionPolicy` | `gateway.envoyproxy.io/v1alpha1` | Wasm filters & External Process |

## Prerequisites

- Kubernetes ≥ 1.26
- Envoy Gateway ≥ 1.2 installed (`helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.2.0 -n envoy-gateway-system --create-namespace`)
- Gateway API CRDs installed (bundled with Envoy Gateway)

## Installation

```bash
# Dry-run with your values
helm template my-policies ./envoy-gateway-policies \
  -f examples/production-api.yaml

# Install
helm install my-policies ./envoy-gateway-policies \
  -n my-namespace --create-namespace \
  -f examples/production-api.yaml

# Upgrade
helm upgrade my-policies ./envoy-gateway-policies \
  -n my-namespace \
  -f my-values.yaml
```

## Configuration

All resources are disabled by default (empty lists). Enable and configure each
policy type in your `values.yaml`.

### Global Settings

```yaml
global:
  namespace: ""        # override for all resources (defaults to Release.Namespace)
  labels: {}           # merged into every resource
  annotations: {}      # merged into every resource
```

### SecurityPolicy

Configure on a `Gateway` or `HTTPRoute`. Supports multiple auth strategies.

```yaml
securityPolicies:
  - name: my-policy
    targetRef:
      kind: Gateway
      name: my-gateway
    jwt:
      providers:
        - name: my-idp
          issuer: "https://idp.example.com"
          remoteJWKS:
            uri: "https://idp.example.com/.well-known/jwks.json"
    cors:
      allowOrigins:
        - "https://app.example.com"
      allowMethods: [GET, POST]
```

See [values.yaml](values.yaml) for the full reference with all options commented.

### BackendTrafficPolicy

Controls retry, timeout, circuit breaker and rate limiting toward backends.

```yaml
backendTrafficPolicies:
  - name: my-btp
    targetRef:
      kind: HTTPRoute
      name: my-route
    retry:
      numRetries: 3
      retryOn:
        triggers: [connect-failure, gateway-error]
    circuitBreaker:
      maxConnections: 1024
```

### BackendTLSPolicy

Force TLS or mTLS on connections to a backend `Service`.

```yaml
backendTLSPolicies:
  - name: my-tls
    targetRef:
      kind: Service
      name: my-service
      sectionName: "443"
    validation:
      hostname: my-service.default.svc.cluster.local
      caCertificateRefs:
        - kind: ConfigMap
          name: ca-bundle
```

## Examples

| File | Description |
|------|-------------|
| [`examples/production-api.yaml`](examples/production-api.yaml) | JWT auth, mTLS, retries, rate limiting, TLS hardening |
| [`examples/oidc-extauth-wasm.yaml`](examples/oidc-extauth-wasm.yaml) | OIDC SSO, OPA ExtAuth, Wasm + ExtProc filters |

## Policy Targeting

All policies follow the Gateway API attachment model:

- **Gateway-level**: applies to all routes handled by the gateway
- **HTTPRoute-level**: applies to a specific route (higher priority)
- **Service-level**: applies to backend TLS/LB settings (`BackendTLSPolicy`, `BackendLBPolicy`)

When both gateway-level and route-level policies exist, the **route-level
policy takes precedence** (merge or override depending on the field).

## Useful Commands

```bash
# Check if policies were accepted
kubectl get securitypolicy,backendtrafficpolicy,clienttrafficpolicy -A

# Describe a policy to see status conditions
kubectl describe securitypolicy my-policy -n my-namespace

# Dump Envoy config for debugging
kubectl exec -n envoy-gateway-system \
  $(kubectl get pod -n envoy-gateway-system -l app=envoy -o name | head -1) \
  -- curl -s localhost:19000/config_dump | jq .
```

## Links

- [Envoy Gateway Docs](https://gateway.envoyproxy.io/docs/)
- [Gateway API Spec](https://gateway-api.sigs.k8s.io/)
- [Security Policy Reference](https://gateway.envoyproxy.io/docs/api/extension_types/#securitypolicy)
- [Traffic Policy Reference](https://gateway.envoyproxy.io/docs/api/extension_types/#backendtrafficpolicy)
