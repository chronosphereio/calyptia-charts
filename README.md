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
It requires the definition of the following environment variables:

* `PROJECT_TOKEN` - the Calyptia Core token to use.
* `CORE_INSTANCE_NAME` - the name of the Calyptia Core instance to create.
* `CORE_INSTANCE_TAGS` - a comma-separated list of tags to add to the Calyptia Core instance.

With these variables defined we can then use substitution in the YAML like so:

```shell
$ export PROJECT_TOKEN=XXX
$ export CORE_INSTANCE_TAGS=test
$ export CORE_INSTANCE_NAME=test-instance
$ curl -sSfL https://raw.githubusercontent.com/calyptia/charts/master/install-core.yaml.tmpl | envsubst '$PROJECT_TOKEN,$CORE_INSTANCE_TAGS,$CORE_INSTANCE_NAME' | kubectl apply -f -
serviceaccount/calyptia-core created
clusterrole.rbac.authorization.k8s.io/calyptia-core created
clusterrolebinding.rbac.authorization.k8s.io/calyptia-core created
deployment.apps/calyptia-core created
```

In the example above we also show how you can set the Calyptia Core instance name (if not present then it will be auto-generated) and the Calyptia Core instance tags.

**The recommendation would always be to download and verify directly without applying initially for security purposes.**

An all-in-one command to do it is therefore (replacing `XXX` with your token, and changing the name/tags as appropriate) on Linux or compatible platforms with `envsubst` available:

```shell
export PROJECT_TOKEN=XXX;export CORE_INSTANCE_TAGS=onelineinstall;export CORE_INSTANCE_NAME=$HOSTNAME;curl -sSfL https://raw.githubusercontent.com/calyptia/charts/master/install-core.yaml.tmpl | envsubst '$PROJECT_TOKEN,$CORE_INSTANCE_TAGS,$CORE_INSTANCE_NAME' | kubectl apply -f -
```

For Windows or other platforms without envsubst available the YAML template can be downloaded and the PROJECT_TOKEN substituted manually or in some other fashion.

#### Enable specific functionality on Calyptia Core

To enable the experimental cluster logging functionality:

```shell
helm install --set-string cluster_logging=true --set project_token=<PROJECT TOKEN>
```

To add tags to the calyptia-core instance:

```shell
helm install --set-string core_instance_tags='one\,two' --set project_token=<PROJECT TOKEN>
```

Note that a valid project token is required.

#### Install core-operator with core-instance

core-operator
```shell 
helm install core-operator calyptia/core-operator
```

core-instance
```shell
helm install core-inst calyptia/core-instance --set coreInstance=<your-core-instance> --set cloudToken=<your-token>
```

Token can be retrieved from the [Core UI](https://core.calyptia.com) under "Settings"
