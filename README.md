# Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

```shell
helm repo add calyptia https://helm.calyptia.com/
```
  
If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
calyptia` to see the charts.

To install the `chart-name` chart:

```shell
helm install <chart-name> calyptia/<chart-name>
```

To uninstall the chart:

```shell
helm delete my-<chart-name>
```

## Current supported charts

### Calyptia-core

First, get a project token from [Calyptia Cloud](https://cloud.calyptia.com/)
To install a calyptia-core instance on the default namespace, run with:

```shell
helm install calyptia-core calyptia/core --set project_token=<PROJECT TOKEN>
```

YAML-only install

Calyptia Core can be installed without Helm as well using equivalent YAML.

The template YAML is auto-generated on each release for you as [`install-core.yaml.tmpl`](./install-core.yaml.tmpl).
It only requires the definition of the `PROJECT_TOKEN` variable and substitution in the YAML like so:

```shell
$ export PROJECT_TOKEN=XXX
$ curl -sSfL https://raw.githubusercontent.com/calyptia/charts/master/install-core.yaml.tmpl | envsubst '$PROJECT_TOKEN' | kubectl apply -f -
serviceaccount/calyptia-core created
clusterrole.rbac.authorization.k8s.io/calyptia-core created
clusterrolebinding.rbac.authorization.k8s.io/calyptia-core created
deployment.apps/calyptia-core created
```

**The recommendation would always be to download and verify directly without applying initially for security purposes.**

An all-in-one command to do it is therefore (replacing `XXX` with your token) on Linux or compatible platforms with `envsubst` available:

```shell
export PROJECT_TOKEN=XXX;curl -sSfL https://raw.githubusercontent.com/calyptia/charts/master/install-core.yaml.tmpl | envsubst '$PROJECT_TOKEN' | kubectl apply -f -
```

For Windows or other platforms without envsubst available the YAML template can be downloaded and the PROJECT_TOKEN substituted manually or in some other fashion.

#### Enable specific functionality on Calyptia Core

To enable the experimental cluster logging functionality:

```shell
helm install --set-string cluster_logging=true --set project_token=<PROJECT TOKEN>
```

Note that a valid project token is required.
