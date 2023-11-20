# Toolsmith repository

This repository is used for Telecom Infra Project WiFi infrastructure configuration:

- [helm-values/assembly-ucentral](./helm-values/assembly-ucentral) - contains helm values used for Cloud SDK deployments, encrypted by SOPS;
- [helmfile/cloud-sdk](./helmfile/cloud-sdk) - contains Helmfile definition for infrastructure deployed to EKS cluster;
- [terraform](./terraform) - contains Terraform manifests for AWS accounts and all resources deployed to them.
- [eksctl](./eksctl) - contains scripts to create EKS clusters using eksctl and awscli.

This repository has CI/CD pipelines for automated Helmfile and Terraform validation and deployment using Atlantis and GitHub Actions.

All changes to the repository should be done through PRs from branches in this repositories to master branch and should be approved by at least one of the repository administrators.
