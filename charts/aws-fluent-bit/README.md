# AWS Marketplace Calyptia Fluent Bit

A Helm chart intended to be used with the [AWS marketplace version of Calyptia Fluent Bit](https://aws.amazon.com/marketplace/pp/prodview-z2en74bwhkfug).

This requires an EKS cluster set up with a service account using the `arn:aws:iam::aws:policy/AWSMarketplaceMeteringRegisterUsage` policy.

## Usage

Ensure a service account is set up with the `arn:aws:iam::aws:policy/AWSMarketplaceMeteringRegisterUsage` policy to register usage correctly.

```shell
eksctl create cluster --name <clustername> --version 1.2x --region <region-code>
```

By default, EKS has an OpenID Connect(OIDC) issuer URL to provide federated access.
AWS IAM supports IDP's that are compatible with OpenIDConnect to establish trust relationships to access the AWS account.

### Adding the [IdP](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html) with the AWS IAM service

```shell
eksctl utils associate-iam-oidc-provider --cluster=<clusterName> --approve
```

You can check if the IdP has been added by going to the AWS IAM console in Identity providers under Access management.

### Creating the IAM role and the Kubernetes Service Account

The below command will create the role and the kubernetes service account in the respective namespace.

```shell
eksctl create iamserviceaccount \
 --name sa-calyptia-fluentbit \
 --namespace calyptia-fluentbit \
 --cluster <clusterName> \
 --role-name "" \ #This would be the role name that would get created as part of this command.
 --attach-policy-arn arn:aws:iam::aws:policy/AWSMarketplaceMeteringRegisterUsage \
 --approve \
 --override-existing-serviceaccounts
```

Verify if the trust relationship is configured correctly by running the below command:

```shell
$ aws iam get-role --role-name <enterthenameoftherole> --query Role.AssumeRolePolicyDocument
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::123456789:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/048D292E8F7E6BECFFE042FE903F529D"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.us-east-1.amazonaws.com/id/048F292E8F7E6BRCFFE042FE903F529D:aud": "sts.amazonaws.com",
                    "oidc.eks.us-east-1.amazonaws.com/id/048F292E8F7E6BRCFFE042FE903F529D:sub": "system:serviceaccount:calyptia-fluentbit:svc-calyptia-fluentbit"
                }
            }
        }
    ]
}
```

verify that you attached to your role is attached as expected:

```shell
$ aws iam list-attached-role-policies --role-name aws-marketplace-access-role --output text
...
ATTACHEDPOLICIES        arn:aws:iam::aws:policy/AWSMarketplaceMeteringRegisterUsage     AWSMarketplaceMeteringRegisterUsage
...
```

confirm if the kubernetes service account that got created is annotated with the role:

```shell
kubectl describe serviceaccount <enterthenameoftheserviceaccount> -n calyptia-fluentbit
```

### Helm chart install

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

```shell
helm repo add calyptia https://helm.calyptia.com
```

If you had already added this repo earlier, run `helm repo update` to retrieve the latest versions of the packages.
You can then run `helm search repo <alias>` to see the charts.

To install the calyptia-fluentbit chart:

```shell
helm install calyptia-fluentbit calyptia/fluent-bit
```

To uninstall the chart:

```shell
helm delete calyptia-fluentbit
```
