#!/bin/bash
set -x
# only run on a clean initially created cluster for CRDs
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
#helm install calico projectcalico/tigera-operator \
#    --namespace tigera-operator \
#    --create-namespace \
#    --version v3.26.1 \
#    -f charts/tigera-operator/values.json
