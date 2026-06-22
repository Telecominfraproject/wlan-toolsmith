#!/bin/bash
set -x
# only run on a clean initially created cluster for CRDs
kubectl apply -k \
    "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"

# https://github.com/cert-manager/cert-manager/releases/download/v1.20.2/cert-manager.crds.yaml
kubectl apply --server-side -f \
    crds/cert-manager-crds-v1.20.2.yaml
# https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/experimental-install.yaml
kubectl apply --server-side -f \
    crds/gateway-api-crd-v1.5.0-experimental.yaml

# Set gp2 as the default StorageClass
kubectl patch storageclass gp2 -p \
    '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}},"allowVolumeExpansion":true}'

# TODO: hopefully no longer needed
#helm install calico projectcalico/tigera-operator \
#    --namespace tigera-operator \
#    --create-namespace \
#    --version v3.26.1 \
#    -f charts/tigera-operator/values.json
