# Calyptia Core Standalone Applicane helm chart

## Usage

A helm chart is provided to install Calyptia Cloud on-premise.
It requires either pull secrets in place, called `regcreds` by default, or pass the configuration to create a namespace-level secret:

```shell
helm repo add calyptia https://helm.calyptia.com
helm repo update
helm upgrade --install \
    --create-namespace --namespace calyptia \
    --set imageCredentials.secretName="<registry url, e.g. ghcr.io>" \
    --set imageCredentials.registry=ghcr.io \
    --set imageCredentials.username="<username for authentication, e.g. Github username>" \
    --set imageCredentials.password="<password or token for authentication>" \
    --set imageCredentials.email="<email associated with user>"
    --wait --debug \
    calyptia-cloud calyptia/calyptia-standalone
```

We provide a package containing all images and this helm chart.
The consumer is responsible for loading images and setting up a K8S cluster with any relevant pull secrets.

To set up a pull secret follow the official documentation here: <https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#create-a-secret-by-providing-credentials-on-the-command-line>.

```shell
kubectl create ns calyptia
kubectl -n calyptia create secret docker-registry "regcreds" \
    --docker-server="<registry url, e.g. ghcr.io>" \
    --docker-username="<username for authentication, e.g. Github username>" \
    --docker-password="<password or token for authentication>" \
    --docker-email="<email associated with user>"
```

To use a pre-created secret:

```shell
helm repo add calyptia https://helm.calyptia.com
helm repo update
helm upgrade --install \
    --create-namespace --namespace calyptia \
    --set global.imagePullSecrets[0]="regcreds" \
    --wait --debug \
    calyptia-cloud calyptia/calyptia-standalone
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

### Postgres configuration

Calyptia Cloud uses Postgres to maintain all the configuration information.
The chart provides a default deployment of Postgres in-cluster but this is not recommended for production.
A separate Postgres deployment (hosted or otherwise) should be used with high availability support.

To switch to an externally (i.e. not by this chart) provided Postgres, modify the following options:

```yaml
cloudApi:
  postgres:
    enabled: false # Set to false to prevent deployment of the default in-cluster version
    # Set this if providing separately
    connectionString: # e.g. postgresql://postgres@postgres:5432?sslmode=disable for in-cluster
```

Ensure to provide the `connectionString` as required to use the Postgres along with any authentication or other requirements in the cluster.
Calyptia Cloud will use the provided string directly to connect to the Postgres instance.

### InfluxDB configuration

Calyptia Cloud uses InfluxDB to capture metrics on the various workloads deployed.

The chart provides a default deployment of InfluxDB in-cluster but this is not recommended for production.
A separate InfluxDB deployment (hosted or otherwise) should be used with high availability support.

To switch to an externally (i.e. not by this chart) provided InfluxDB, modify the following options:

```yaml
cloudApi:
  influxdb:
    enabled: false # Set to false to prevent deployment of the default in-cluster version
    # Set this if providing separately
    server: # e.g. http://influxdb:8086
```

Ensure the `server` URL is routable from the cluster.
Calyptia Cloud will use the provided string directly to connect to the InfluxDB instance.

### Workload configuration

The chart automatically deploys the Calyptia Core operator into the same namespace to manage workloads too.
To disable this, modify the following options:

```yaml
operator:
  enabled: true
```

Once the operator is deployed, the [`core-instance`](https://github.com/calyptia/charts/tree/master/charts/core-instance) chart can be used to add workloads to the cluster.
Alternatively the legacy [`core`](https://github.com/calyptia/charts/tree/master/charts/core) chart can also be used without operator support.

## Troubleshooting

### Calyptia Fluent Bit LTS

We provide a Calyptia Fluent Bit LTS daemonset to send all logs and metrics to configurable end points.
By default this sends to the in-cluster Vivo and Grafana stack (if present) but it can be configured to forward to other destinations as well.

The Fluent Bit daemonset can be disabled by setting `monitoring.fluent-bit: false` in the configuration.

### Grafana stack

We provide an optional Prometheus-Loki-Grafana stack (PLG) monitoring stack that can be deployed by the helm chart:

```shell
helm ...  --set monitoring.grafana=true ...
```

This uses the Grafana Loki-Stack helm chart to deploy everything so can be configured via all the options available in the stack.

By default we set up the PLG stack in the same namespace along with a Fluent Bit daemonset sending it logs and metrics.

To access Grafana (the helm chart will give you the details as well post installation):

The admin login is in the 'calyptia-cloud-grafana' secret:

```shell
kubectl get secret -n {{ .Release.Namespace }} calyptia-cloud-grafana -o jsonpath='{.data.admin-password}'| base64 --decode
```

To access it, port-forward the 'calyptia-cloud-grafana' service on port 80, e.g. for <http://localhost:3000>

```shell
kubectl port-forward -n {{ .Release.Namespace }} svc/calyptia-cloud-grafana 3000:80
```

From Grafana you can access logs and metrics for everything supported.

### Shell script

From the Calyptia package, we also provide a [`support.sh`](../support.sh) script locally to scrape all relevant information from the cluster and automatically create an archive to upload to [our support portal](https://support.zendesk.com).

```shell
$ ./support.sh
Running support script: 2023-08-16T14:47:19Z
Output stored here: /tmp/tmp.76NbwCR3Od
Cluster info dumped to /tmp/tmp.76NbwCR3Od/cluster
Creating tarball: /tmp/calyptia-support-calyptia-laptop-2023-08-16T14-47-19Z.tgz
Support script complete: /tmp/calyptia-support-calyptia-laptop-2023-08-16T14-47-19Z.tgz
```
