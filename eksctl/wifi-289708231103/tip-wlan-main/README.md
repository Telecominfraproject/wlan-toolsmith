# EKSCTL Based Cluster Installation

The script and associated files should make it possible to deploy an EKS cluster and
a few nodes. It sets up the EKS cluster bsaed on provided environment variables.
The scripts should work on MacOS and Linux (as of yet untested).

## Requirements

### MacOS
- Homebrew (Mac)
- gettext for envsubst (via Homebrew v0.21.1)

### General
- eksctl (v0.157.0+)
- aws-cli (v2.13.19)

## Setup

- Prepare an environment file (see [env\_example](./env_example).
- Make sure all required utilities are installed.
- Make sure that you can run "aws --version" and "eksctl version"
- Make sure that any AWS SSO environment variables are set.

## Installation

- Run "source env\_FILE ; ./installer" (using the env file you created above)
- If the identity check succeeds the installer will create the following resources:
  - EKS cluster
  - Policy and service accounts for EBS, ALB and Route 53 access.
  - EBS addon and OIDC identity providers
- Reads cluster config into a temporary file.
- Shows some information about the created cluster.
- Shows how to run "aws eks update-kubeconfig" command to update your .kube/config file in place.

## Scaling nodegroups

Set the desiredCapacity for the nodegroup in cluster.CLUSTER_NAME.yaml and run:
```bash
source env\_FILE
eksctl scale nodegroup -f cluster.$CLUSTER_NAME.yaml
```

## Next Steps

After creating the cluster proceed to [helmfile/cloud-sdk](../../../helmfile/cloud-sdk) to install
shared services.

## Cleanup

- Run "source env\_FILE ; ./cleaner" (using the env file you created above)

Note that sometimes AWS has trouble cleaning up when things are or appear in-use. The eksctl
command to delete the cluster may thus fail requiring chasing down the noted rewsources. One of the
resources that seems to always linger are LBs. Deleting these manually and restarting cleanup,
sometimes works. Other times inspecting the CloudFormation resource for this cluster for errors
will lead to discovery of the problematic resources. After you delete these resources manually, you may retry deletion of the CloudFormation stack. That should take care of deleting any remaining resources.

