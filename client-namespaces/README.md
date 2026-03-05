# client-namespaces

This is a `Helm` chart to deploy namespaces that will be dedicated to 'clients'.  
In order to be considered 'client'-ready, a namespace also needs additional Kubernetes resources, including:

- additional `ServiceAccount`
- RBAC (`RoleBinding` ...) setup associated to the `ServiceAccont`
- `ResourceQuota` & `LimitRange`
- `NetworkPolicies` to filter inbound & oubound traffic to/from the namespace
