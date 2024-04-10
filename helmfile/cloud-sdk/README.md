# Helmfile

This directory contains all things required for TIP EKS infrastructure setup. It uses [Helmfile](https://github.com/roboll/helmfile) for one-command installation

## Requirements

Following tools are required to be installed on your local machine to fully utilize this Helmfile:

1. [Helmfile](https://github.com/roboll/helmfile)
2. [Helm 3](https://helm.sh/docs/intro/install/)
3. [Helm diff](https://github.com/databus23/helm-diff) - used during deployments by default for a better changes transparency
4. [Helm secrets](https://github.com/jkroepke/helm-secrets)
5. [sops](https://github.com/mozilla/sops)

### Helm secrets

**Helm secrets** is a tool that may be used to store secrets in Git repository in ecrypted form. **sops** is a tool that Helm secrets uses for encryption/decryption operations.

Currently all secrets are stored in [secrets](./secrets) directory, where you can find all encrypted files and `.sops.yaml` file that defines that all new secrets should be encrypted with AWS KMS key.

To work with secret, you need to have your AWS credentials set with administrator role in wifi account, then you would be able to make operations with files (for example to edit secret use `helm secrets edit $SECRET_FILE`).

If you need to encrypt new file, you simply need to write it in plaintext, then run `helm secrets encrypt $PLAINTEXT_SECRET_FILE` - helm secrets will automatically use encryption key defined in `.sops.yaml`

You can use secrets in Helmfile the same way as values:

1. Add secrets in environment
2. Use `{{ .Environment.Values... }}` where you need it in releases definition

For example, if we have secret `secrets/example.yaml`

```
example:
  secretKey: "topSecret"
```

usage of it will look like this:

```
environments:
  example:
    secrets:
      - secrets/example.yaml

releases:
- name: example
  values:
  - secretKey: {{ .Environment.Values.example.secretKey }}
```

### K8S Dashboard Login

To replace or set the users that may login to the dashboard (via basic auth):

```
htpasswd -c auth qa
```
Then copy base64 version of this file into: data.auth in charts/k8s-dashboard-roles/templates/basic-auth.yaml.
The current password is encoded in secrets/dashboard.yaml.


## Usage

1. Set credentials that are required to connect to Kubernetes cluster
2. (optional) If you are going to use environment with secrets, make sure that you also have credentials required for access to AWS KMS key
3. Run `./predeploy.sh` to install pre-requisites.
4. Run `helmfile --environment $ENVIRONMENT diff` to see changes that would be applied
5. If everything is correct, run `helmfile --environment $ENVIRONMENT apply` to see changes that would be applied

If you would like to limit release that you would like to affect, you may use labels. For example, if you want to see changes that would be done only to **influxdb** release in **amazon-cicd** environment, you may run `helmfile --environment amazon-cicd --selector app=influxdb diff`

### First install

Upon first install there is usually a back and forth with dependencies, so it helps to install
things in a certain order. This is the suggested order:

```
./predeploy.sh
helmfile --environment $ENVIRONMENT -l app=aws-load-balancer-controller apply
helmfile --environment $ENVIRONMENT --skip-deps -l app=metrics-server apply
helmfile --environment $ENVIRONMENT --skip-deps -l app=node-termination-handler apply
helmfile --environment $ENVIRONMENT --skip-deps -l app=cert-manager apply
helmfile --environment $ENVIRONMENT --skip-deps -l app=external-dns apply
helmfile --environment $ENVIRONMENT --skip-deps -l crd=prometheus-operator-crd apply
helmfile --environment $ENVIRONMENT --skip-deps -l app=prometheus-operator apply
helmfile --environment $ENVIRONMENT --skip-deps -l app=ingress apply
# anything not covered previously
helmfile --environment $ENVIRONMENT --skip-deps apply
```

## First time - post installation activities

```
kubectl edit sc gp2
# add at root level: allowVolumeExpansion: true
kubectl edit ingressclass alb
# add under: metadata.annotations:
#   ingressclass.kubernetes.io/is-default-class: "true"
```
