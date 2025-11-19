# Core CRD

`core-crd` packages the Custom Resource Definitions (CRDs) used by `core-operator`.

## Parameters

### Common

Configures common parameters.

| Name                  | Description                                                           | Value          |
| --------------------- | --------------------------------------------------------------------- | -------------- |
| `enabled`             | Enables this chart                                                    | `true`         |
| `pipelineServiceType` | The default service type to use for a Pipeline if not explicitly set. | `LoadBalancer` |

### Images

Configures the default images used for Pipelines and Ingest Checks when not explicitly set at creation time.

| Name                            | Description       | Value                               |
| ------------------------------- | ----------------- | ----------------------------------- |
| `images.hotReload.registry`     | Image registry.   | `ghcr.io`                           |
| `images.hotReload.repository`   | Image repository. | `chronosphereio/configmap-reload`   |
| `images.hotReload.tag`          | Image tag.        | `v1.0.2`                            |
| `images.fluentBit.registry`     | Image registry.   | `ghcr.io`                           |
| `images.fluentBit.repository`   | Image registry.   | `calyptia/core/calyptia-fluent-bit` |
| `images.fluentBit.tag`          | Image tag.        | `25.11.2`                           |
| `images.ingestCheck.registry`   | Image registry.   | `ghcr.io`                           |
| `images.ingestCheck.repository` | Image repository. | `calyptia/core/ingest-check`        |
| `images.ingestCheck.tag`        | Image tag.        | `0.0.7`                             |
