# Calyptia Core Standalone application helm chart

## Usage

A helm chart is provided to install Calyptia Cloud on-premise.
It requires either pull secrets in place, called `regcreds` by default, or pass the configuration to create a namespace-level secret:

```shell
helm repo add calyptia https://helm.calyptia.com
helm repo update
helm upgrade --install \
    --create-namespace --namespace calyptia \
    --set imageCredentials.secretName=regcreds \
    --set imageCredentials.registry="<registry url, e.g. ghcr.io>" \
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

## Upgrade

To upgrade the chart without service interruption, the two main things to ensure are:

1. The Postgres database state does not change.
1. The CRDs for the operator (if deployed with this chart) are not removed.

The chart includes a Postgres database default deployment in-cluster but this is not recommended for production and provides no guarantees.
An external database (external to this chart, it could be in-cluster) with high availability should be provided.
See the section below on Postgres configuration for this.

If the Postgres state changes (e.g. if the pod is re-deployed) then all authentication and configuration details are lost.
Postgres volumes can be set up using the `cloudApi.postgres.extraVolumes` and `cloudApi.postgres.extraVolumesMounts` settings.

The chart auto-deploys the Calyptia Core operator and CRD charts by default.
This includes CRD configuration but note Helm has caveats on managing existing CRDs.
Any upgrade should first ensure the correct CRDs are installed via `kubectl replace -f crd.yaml`.
The CRD YAML files are available on the specific release being installed here: <https://github.com/chronosphereio/calyptia-core-operator-releases/>

If CRDs are removed then all workloads associated with them will also be destroyed (but will be recreated when the CRD is added again if the config is in the database).

CRD removal can be prevented with the following annotation:

```shell
kubectl annotate crd pipelines.core.calyptia.com helm.sh/resource-policy=keep --overwrite
kubectl annotate crd ingestchecks.core.calyptia.com helm.sh/resource-policy=keep --overwrite
```

To upgrade from 1.x series chart to 2.x, also add these annotations to prevent replacement of the CRD:

```shell
kubectl annotate crd pipelines.core.calyptia.com meta.helm.sh/release-name=calyptia-cloud --overwrite
kubectl annotate crd pipelines.core.calyptia.com meta.helm.sh/release-namespace="$CALYPTIA_NAMESPACE" --overwrite
kubectl label crd pipelines.core.calyptia.com app.kubernetes.io/managed-by=Helm --overwrite
```

The recommendation would be to deploy the Core Operator separately and disable it in this chart to maintain full control over lifecycle.

## Production deployment

The default configuration for this chart is intended to provide a simple in-cluster working deployment and as such is not recommended for production.
Specifically, for a production deployment the recommendations are:

* Deploy Postgres (and Influx) separately and manage with high availability.
* Deploy the Core Operator separately and manage the data plane independently of the control plane.

```yaml
operator:
  enabled: false
cloudApi:
  postgres:
    enabled: false
    connectionString: <Postgres DNS provided here>
  influxdb:
    enabled: false
    server: <URL for InfluxDB server>
```

## Services

The helm chart provides the following services:

* cloud-api: API, defaults to port 5000
* core: UI, defaults to port 3000

These match up with the hosted names, e.g. cloud-api.calyptia.com and core.calyptia.com.

In addition, a [Vivo](https://github.com/chronosphereio/calyptia-vivo) service is also provided on port 3000.

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

Every Calyptia component has a common set of configuration, e.g. for the `cloud-api` component we can control whether it is deployed and what type of service to use:

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

An example using in-cluster Bitnami chart is shown below.

First of all, deploy the Postgres chart with fixed configuration in this case for credentials (not recommended):

```shell
helm upgrade --install \
  --create-namespace --namespace "external" \
  --set auth.postgresPassword='adminpassword' \
  --set primary.persistence.enabled=false \
  external-postgres oci://registry-1.docker.io/bitnamicharts/postgresql --version 14.2.2
```

Now we can deploy the chart using the separate Postgres configuration:

```shell
helm upgrade --install \
  ...
  --set cloudApi.postgres.enabled=false \
  --set cloudApi.postgres.connectionString='postgresql://postgres:adminpassword@external-postgres-postgresql.external:5432?sslmode=disable' \
  ...
```

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

Once the operator is deployed, the [`core-instance`](https://github.com/chronosphereio/calyptia-charts/tree/master/charts/core-instance) chart can be used to add workloads to the cluster.
Alternatively the legacy [`core`](https://github.com/chronosphereio/calyptia-charts/tree/master/charts/core) chart can also be used without operator support.

### Autoscaling

Each of the main services can be set up to use [Horizontal Pod Autoscaling (HPA)](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/), however this is disabled by default.

To enable, set the `autoscaling.enabled=true` property in the appropriate sections below:

```yaml
cloudApi:
  autoscaling:
    enabled: false
    minReplicas: 1
    maxReplicas: 5
    targetMemoryUtilizationPercentage: 50
    targetCPUUtilizationPercentage: 50
frontend:
  autoscaling:
    enabled: false
    minReplicas: 1
    maxReplicas: 5
    targetMemoryUtilizationPercentage: 50
    targetCPUUtilizationPercentage: 50
  luaSandbox:
    autoscaling:
      enabled: false
      minReplicas: 1
      maxReplicas: 5
      targetMemoryUtilizationPercentage: 50
      targetCPUUtilizationPercentage: 50
```

Remember HPA requires a controller (as well as a metrics server and any other supporting infrastructure) in the cluster to actually implement and manage scaling.
Ensure this is deployed as well in an appropriate fashion.

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
