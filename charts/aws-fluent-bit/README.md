# AWS Marketplace Calyptia Fluent Bit

A helm chart intended to be used with the [AWS marketplace version of Calyptia Fluent Bit](https://aws.amazon.com/marketplace/pp/prodview-z2en74bwhkfug).

## Usage

Ensure a service account is set up with the `arn:aws:iam::aws:policy/AWSMarketplaceMeteringRegisterUsage` policy to register usage correctly.

```shell
eksctl create cluster --name <clustername> --version 1.2x --region <region-code>
```

By default, EKS has an OpenID Connect(OIDC) issuer URL to provide federated access. AWS IAM supports IDP's that are compatible with OpenIDConnect to establish trust relationships to access the AWS account.


### Adding the [IdP](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html) with the AWS IAM service

```
eksctl utils associate-iam-oidc-provider --cluster=<clusterName> --approve
```

You could check if the IdP has been added by going to the AWS IAM console in Identity providers under Access management

### Creating the IAM role and the Kubernetes Service Account
The below command will create the role and the kubernetes service account in the respective namespace. 

```
eksctl create iamserviceaccount \
 --name <enterthenameoftheserviceaccount> \
 --namespace <serviceaccount'snamespace> \
 --cluster <clusterName> \
 --role-name "<enterthenameoftherole>" \
 --attach-policy-arn arn:aws:iam::aws:policy/AWSMarketplaceMeteringRegisterUsage \
 --approve \
 --override-existing-serviceaccounts
```

verify if the trust relationship is configured correctly by running the below command:
```
aws iam get-role --role-name <enterthenameoftherole> --query Role.AssumeRolePolicyDocument
```

verify that you attached to your role is attached as expected:
```
aws iam list-attached-role-policies --role-name aws-marketplace-access-role --output text
```

confirm if the kubernetes service account that got created is annotated with the role:
```
kubectl describe serviceaccount <enterthenameoftheserviceaccount> -n default
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
