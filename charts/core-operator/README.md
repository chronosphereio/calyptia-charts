# Core Operator

`core-operator` packages the Chronosphere Telemetry Pipeline operator.

## Parameters

### Global Image

Configures image parameters for all images.

| Name                      | Description                                                                                         | Value          |
| ------------------------- | --------------------------------------------------------------------------------------------------- | -------------- |
| `global.imageRegistry`    | Image registry to use for all images. This overrides the `registry` for all images.                 | `""`           |
| `global.imagePullSecrets` | Image pull secret names to use for all images. This is joined with the `pullSecrets` for all image. | `["regcreds"]` |
| `global.pullPolicy`       | Image pull policy to use for all images. This overrides the `pullPolicy` for all images.            | `""`           |

### Deployment

Configures the operator deployment.

| Name                          | Description                                                              | Value                    |
| ----------------------------- | ------------------------------------------------------------------------ | ------------------------ |
| `enabled`                     | Enables this chart                                                       | `true`                   |
| `images.operator.registry`    | Image registry. This can be overridden by `global.imageRegistry`.        | `ghcr.io`                |
| `images.operator.repository`  | Image repository.                                                        | `calyptia/core-operator` |
| `images.operator.tag`         | Image tag.                                                               | `3.57.0`                 |
| `images.operator.pullSecrets` | Image pull secret names. This is joined with `global.image.pullSecrets`. | `[]`                     |
| `images.operator.pullPolicy`  | Pull policy. This can be overridden by `global.image.pullPolicy`.        | `IfNotPresent`           |
| `commonAnnotations`           | Annotations added to all resources, except the operator pod.             | `{}`                     |
| `podAnnotations`              | Annotations added only to the operator pod.                              | `{}`                     |
| `namespaceOverride`           | Namespace to use instead of `.Release.Namespace`.                        | `""`                     |
| `calyptiaTolerations`         | Tolerations added to the operator pod.                                   | `""`                     |
| `restartPolicy`               | The restart policy for the pod.                                          | `Always`                 |

### Resources

Resources for the operator deployment.

| Name                        | Description     | Value   |
| --------------------------- | --------------- | ------- |
| `resources.limits.cpu`      | CPU limit.      | `500m`  |
| `resources.limits.memory`   | Memory limit.   | `512Mi` |
| `resources.requests.cpu`    | CPU request.    | `10m`   |
| `resources.requests.memory` | Memory request. | `64Mi`  |

### Probes

Probes to check the health of the operator deployment.

| Name                                 | Description                                       | Value      |
| ------------------------------------ | ------------------------------------------------- | ---------- |
| `readinessProbe.httpGet.path`        | Readiness http path.                              | `/readyz`  |
| `readinessProbe.httpGet.port`        | Readiness http port.                              | `8081`     |
| `readinessProbe.initialDelaySeconds` | Initial delay for the readiness probe in seconds. | `5`        |
| `readinessProbe.periodSeconds`       | How often to run the readiness probe in seconds.  | `10`       |
| `livenessProbe.httpGet.path`         | Liveness http path.                               | `/healthz` |
| `livenessProbe.httpGet.port`         | Liveness http port.                               | `8081`     |
| `livenessProbe.initialDelaySeconds`  | Initial delay for the livenss probe in seconds.   | `15`       |
| `livenessProbe.periodSeconds`        | How often to run the liveness probe in seconds.   | `20`       |

### RBAC

Configure the RBAC for the operator deployment.

| Name                         | Description                                                                           | Value  |
| ---------------------------- | ------------------------------------------------------------------------------------- | ------ |
| `rbac.create`                | Specifies whether RBAC resources should be created                                    | `true` |
| `serviceAccount.create`      | If the ServiceAccount is created for the operator.                                    | `true` |
| `serviceAccount.name`        | The name of the Service Account.                                                      | `""`   |
| `serviceAccount.annotations` | Additional annotations added to the Service Account. Merged with `commonAnnotations`. | `{}`   |
| `fullnameOverride`           | Sets `serviceAccount.name` to `fullnameOverride-calyptia-core-operator` if not set.   | `""`   |
| `nameOverride`               | Sets `fullnameOverride` to `.Release.Name-nameOverride` if not set.                   | `""`   |

### Pull Secret

Configures a secret to pull images.

| Name                          | Description                                                                 | Value |
| ----------------------------- | --------------------------------------------------------------------------- | ----- |
| `imageCredentials.secretName` | Secret name. This must be included as a `pullSecret` for images to be used. |       |
| `imageCredentials.registry`   | The image registry. This must be match the `registry` for images.           |       |
| `imageCredentials.username`   | Username for login to the registry.                                         |       |
| `imageCredentials.password`   | Password for login to the registry.                                         |       |
| `imageCredentials.email`      | Email for login to the registry.                                            |       |
| `statefulSetDeletionTimeout`  | Timeout duration for StatefulSet deletion during resize operations          | `1m`  |

### Security Context

Configures the security context for the operator deployment.

| Name              | Description                                                                                                                           | Value |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| `securityContext` | Security context for the operator pod. If not specified, defaults to not allowing privilege escalation and dropping all capabilities. | `nil` |
