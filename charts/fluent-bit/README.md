# AWS Marketplace Calyptia Fluent Bit

A helm chart intended to be used with the [AWS marketplace version of Calyptia Fluent Bit](https://aws.amazon.com/marketplace/pp/prodview-z2en74bwhkfug).

## Usage

Ensure a service account is set up with the `arn:aws:iam::aws:policy/AWSMarketplaceMeteringRegisterUsage` policy to register usage correctly.

```shell
eksctl create cluster

eksctl utils associate-iam-oidc-provider --cluster=<clusterName> --approve

eksctl create iamserviceaccount --cluster=<clusterName> --name=eks-calyptia-fluentbit --namespace=<serviceAccountNamespace> --attach-policy-arn=arn:aws:iam::aws:policy/AWSMarketplaceMeteringRegisterUsage --approve
```

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

```shell
helm repo add calyptia https://helm.calyptia.com
```

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
<alias>` to see the charts.

To install the calyptia-fluentbit chart:

```shell
helm install calyptia-fluentbit calyptia/fluent-bit
```

To uninstall the chart:

```shell
helm delete calyptia-fluentbit
```
