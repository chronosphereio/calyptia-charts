# Calyptia Core Standalone Applicane helm chart

## Usage

A helm chart is provided to install Calyptia Cloud on-premise.
It requires pull secrets in place, in this case called `container-registry-creds`.

```shell
helm repo add calyptia https://helm.calyptia.com
helm repo update
helm upgrade --install \
    --create-namespace --namespace calyptia \
    --set global.imagePullSecrets[0]="container-registry-creds" \
    --wait --debug \
    calyptia-cloud calyptia/calyptia-standalone
```

We provide a package containing all images and this helm chart.
The consumer is responsible for loading images and setting up a K8S cluster with any relevant pull secrets.

To set up a pull secret follow the official documentation here: <https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#create-a-secret-by-providing-credentials-on-the-command-line>.

```shell
kubectl create ns calyptia
kubectl -n calyptia create secret docker-registry "container-registry-creds" \
    --docker-server="<registry url, e.g. ghcr.io>" \
    --docker-username="<username for authentication, e.g. Github username>" \
    --docker-password="<password or token for authentication>" \
    --docker-email="<email associated with user>"
```

### Services

The helm chart provides the following services:

* cloud-api: API, defaults to port 5000
* core: UI, defaults to port 3000

These match up with the hosted names, e.g. cloud-api.calyptia.com and core.calyptia.com.

In addition, a [Vivo](https://github.com/calyptia/vivo) service is also provided on port 3000.

All services are provided as [`LoadBalancer`](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) type by default so the external IP can be retrieved via a call to `kubectl -n <namesapce> get svc`.

## Pre-requisites

1. Kubernetes cluster
1. Container registry with images and pull secrets
1. Helm installed

## Configuration

A default Helm values file is provided, this can be configured using the usual Helm approach of `--set key=val` or specifying one or more additional values files via `--values <file>`.
Refer to Helm documentation for any specific questions on how to provide the configuration: <>

### Container configuration

To support on-premise usage, the Helm chart provides common configuration for all images.

```yaml
global:
  imageRegistry: ""
  imagePullSecrets: []
  storageClass: ""
  pullPolicy: IfNotPresent
```

A global override for all container image registries can be provided via `global.imageRegistry`.
If the container registry requires authentication then this can be provided via a (series of) pull secret(s).
This configuration can be applied per-image as well to customise each individual image as required:

```yaml
    cloud:
      registry: ghcr.io
      repository: calyptia/cloud
      tag: 1.4.1
      pullSecrets: []
```

### Service configuration

Every Calyptia component has a common set of configuration, e.g. for the `cloud-api` component we cna control whether it is deployed and what type of service to use:

```yaml
cloudApi:
  enabled: true
  service:
    type: LoadBalancer
    port: 5000
```

This is repeated for `frontend` and `vivo` components.

To switch all service to use type [`ClusterIP`](https://kubernetes.io/docs/concepts/services-networking/service/#type-clusterip), the following can be done:

```shell
helm upgrade --install \
    --create-namespace --namespace "calyptia" \
    --set cloudApi.service.type="ClusterIP" \
    --set frontend.service.type="ClusterIP" \
    --set vivo.service.type="ClusterIP" \
    --wait --debug \
    calyptia-cloud calyptia/calyptia-standalone
```

[LoadBalancer](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) services are used by default as they are exposed externally then automatically via the cloud providers and other tools like K3S.

If using `LoadBalancer` then external IP for a service can be retrieved via a call to `kubectl -n <namespace> get svc/<service>`.

If using `ClusterIP` then data needs to be ingested into the cluster somehow, a simple technique is to use port-forwarding, e.g. `kubectl -n <namespace> port-forward svc/<service> <port>:<port>`.
This will expose the port locally for use.
