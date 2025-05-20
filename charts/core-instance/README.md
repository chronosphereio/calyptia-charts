# Core Instance

`core-instance` packages the Chronosphere Telemetry Pipeline core-instance, which syncs Telemetry Pipelines between a
k8s cluster and the Chronosphere cloud.

## Parameters

### Global Image

Configures image parameters for all images.

| Name                      | Description                                                                                         | Value          |
| ------------------------- | --------------------------------------------------------------------------------------------------- | -------------- |
| `global.imageRegistry`    | Image registry to use for all images. This overrides the `registry` for all images.                 | `""`           |
| `global.imagePullSecrets` | Image pull secret names to use for all images. This is joined with the `pullSecrets` for all image. | `["regcreds"]` |
| `global.pullPolicy`       | Image pull policy to use for all images. This overrides the `pullPolicy` for all images.            | `""`           |

### Deployment

Configures the core-instance deployment.

| Name                            | Description                                                                                                                    | Value                                    |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------- |
| `enabled`                       | Enables this chart                                                                                                             | `true`                                   |
| `coreInstance`                  | Name of the core-instance                                                                                                      | `""`                                     |
| `cloudToken`                    | API Token in plaintext. Only used if `cloudTokenSec` not set.                                                                  | `""`                                     |
| `cloudTokenSec.name`            | API Token secret name.                                                                                                         | `nil`                                    |
| `cloudTokenSec.key`             | API Token secret key.                                                                                                          | `nil`                                    |
| `cloudUrl`                      | Cloud URL endpoint.                                                                                                            | `https://cloud-api.calyptia.com`         |
| `images.fromCloud.registry`     | Image registry. This can be overridden by `global.imageRegistry`.                                                              | `ghcr.io`                                |
| `images.fromCloud.repository`   | Image repository.                                                                                                              | `calyptia/core-operator/sync-from-cloud` |
| `images.fromCloud.tag`          | Image tag.                                                                                                                     | `3.46.0`                                 |
| `images.fromCloud.pullSecrets`  | Image pull secret names. This is joined with `global.image.pullSecrets`.                                                       | `[]`                                     |
| `images.fromCloud.pullPolicy`   | Pull policy. This can be overridden by `global.image.pullPolicy`.                                                              | `IfNotPresent`                           |
| `images.toCloud.registry`       | Image registry. This can be overridden by `global.imageRegistry`.                                                              | `ghcr.io`                                |
| `images.toCloud.repository`     | Image repository.                                                                                                              | `calyptia/core-operator/sync-to-cloud`   |
| `images.toCloud.tag`            | Image tag.                                                                                                                     | `3.46.0`                                 |
| `images.toCloud.pullSecrets`    | Image pull secret names. This is joined with `global.image.pullSecrets`.                                                       | `[]`                                     |
| `images.toCloud.pullPolicy`     | Pull policy. This can be overridden by `global.image.pullPolicy`.                                                              | `IfNotPresent`                           |
| `images.hotReload.registry`     | Image registry. This can be overridden by `global.imageRegistry`.                                                              | `ghcr.io`                                |
| `images.hotReload.repository`   | Image repository.                                                                                                              | `calyptia/configmap-reload`              |
| `images.hotReload.tag`          | Image tag.                                                                                                                     | `0.11.1`                                 |
| `images.ingestCheck.registry`   | Image registry. This can be overridden by `global.imageRegistry`.                                                              | `ghcr.io`                                |
| `images.ingestCheck.repository` | Image repository.                                                                                                              | `calyptia/core/ingest-check`             |
| `images.ingestCheck.tag`        | Image tag.                                                                                                                     | `0.0.7`                                  |
| `interval`                      | How often to sync data to/from the cloud.                                                                                      | `15s`                                    |
| `probeIntervalSec`              | How often to run liveness and readiness probes. If 0, probes are disabled.                                                     | `5`                                      |
| `commonAnnotations`             | Annotations added to the resources created by this chart. These annotations are not added to the Pipeline resources created by | `{}`                                     |
| `namespaceOverride`             | Namespace to use instead of `.Release.Namespace`.                                                                              | `""`                                     |
| `fromCloud.debugPort`           | The debug port for the fromCloud container.                                                                                    | `5334`                                   |
| `fromCloud.resources`           | The resources for the fromCloud container.                                                                                     | `{}`                                     |
| `toCloud.debugPort`             | The debug port for the toCloud container.                                                                                      | `15334`                                  |
| `toCloud.resources`             | The resources for the toCloud container.                                                                                       | `{}`                                     |
| `cloudTimeout`                  | HTTP timeout for requests to the cloud. 0 disables the timeout.                                                                | `0`                                      |

### Pipeline

Configures the Pipelines installed by the core-instance.

| Name                             | Description                                                                                                                                                                                                                                                                            | Value          |
| -------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
| `clusterLogging`                 | Enables Cluster Logging.                                                                                                                                                                                                                                                               | `false`        |
| `calyptiaAnnotations`            | Annotations added to pipeline resources created in the cluster. Format is key1=value1,key2=value.                                                                                                                                                                                      | `""`           |
| `calyptiaTolerations`            | Tolerations added to pipeline pods. Only used if Tolerations are not configured for a Pipeline. Format is key=operator:value:effect:seconds,key=operator:value:effect:seconds. Optional parts are represented with an empty string, e.g =Exists:: is a Toleration matching all taints. | `""`           |
| `enableHealthCheckPipeline`      | Enables a health check pipeline.                                                                                                                                                                                                                                                       | `false`        |
| `healthCheckPipelinePort`        | Port for the health check pipeline.                                                                                                                                                                                                                                                    | `2020`         |
| `healthCheckPipelineServiceType` | Service type for the health check pipeline.                                                                                                                                                                                                                                            | `LoadBalancer` |
| `skipServiceCreation`            | Skip creating services for pipeline ports.                                                                                                                                                                                                                                             | `false`        |
| `notls`                          | If true, disables TLS verify for the pipeline config.                                                                                                                                                                                                                                  | `true`         |
| `httpProxy`                      | Sets the HTTP_PROXY env variable for pipeline containers.                                                                                                                                                                                                                              | `""`           |
| `httpsProxy`                     | Sets the HTTPS_PROXY env variable for pipeline containers.                                                                                                                                                                                                                             | `""`           |
| `noProxy`                        | Sets the NO_PROXY env variable for pipeline containers.                                                                                                                                                                                                                                | `""`           |
| `cloudProxy`                     | Sets the http proxy to use when connecting to the cloud.                                                                                                                                                                                                                               | `""`           |

### RBAC

Configures the RBAC for the core-instance deployment.

| Name                         | Description                                                                            | Value  |
| ---------------------------- | -------------------------------------------------------------------------------------- | ------ |
| `rbac.create`                | Specifies whether RBAC resources should be created.                                    | `true` |
| `serviceAccount.create`      | If the ServiceAccount is created..                                                     | `true` |
| `serviceAccount.name`        | The name of the Service Account.                                                       | `""`   |
| `serviceAccount.annotations` | Additional annotations added to the Service Account. Merged with `commonAnnotations`.  | `{}`   |
| `fullnameOverride`           | Sets `serviceAccount.name` to `calyptia-core-instance-fullnameOverride-sa` if not set. | `""`   |
| `nameOverride`               | Sets `fullnameOverride` to `.Release.Name-nameOverride` if not set.                    | `""`   |

### Pull Secret

Configures a secret to pull images.

| Name                          | Description                                                                 | Value |
| ----------------------------- | --------------------------------------------------------------------------- | ----- |
| `imageCredentials.secretName` | Secret name. This must be included as a `pullSecret` for images to be used. |       |
| `imageCredentials.registry`   | The image registry. This must be match the `registry` for images.           |       |
| `imageCredentials.username`   | Username for login to the registry.                                         |       |
| `imageCredentials.password`   | Password for login to the registry.                                         |       |
| `imageCredentials.email`      | Email for login to the registry.                                            |       |
