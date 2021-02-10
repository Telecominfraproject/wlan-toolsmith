#!/bin/sh

set -e

if [ -z "$1" ];
then
  echo "PR number has not been set";
  exit 1
fi

PR_NUMBER=$1

cat <<EOF
shared:
  service:
    srv-https-annotations: &srv-https-annotations
      kubernetes.io/ingress.class: alb
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/group.name: wlan-cicd-pr-$PR_NUMBER
      alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-2:289708231103:certificate/bfa89c7a-5b64-4a8a-bcfe-ffec655b5285
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_302"}}'

global:
  debugEnabled: true

opensync-gw-static:
  enabled: false

common:
  efs-provisioner:
    enabled: false

opensync-gw-cloud:
  enabled: true
  service:
    type: LoadBalancer
    annotations:
      external-dns.alpha.kubernetes.io/hostname: wlan-filestore-pr-$PR_NUMBER.cicd.lab.wlan.tip.build,opensync-controller-pr-$PR_NUMBER.cicd.lab.wlan.tip.build,opensync-redirector-pr-$PR_NUMBER.cicd.lab.wlan.tip.build
  externalhost:
    address:
      ovsdb: opensync-controller-pr-$PR_NUMBER.cicd.lab.wlan.tip.build
      mqtt: opensync-mqtt-broker-pr-$PR_NUMBER.cicd.lab.wlan.tip.build
  persistence:
    enabled: false
  filestore:
    url: https://wlan-filestore-pr-$PR_NUMBER.cicd.lab.wlan.tip.build

opensync-mqtt-broker:
  enabled: true
  service:
    type: LoadBalancer
    annotations:
      external-dns.alpha.kubernetes.io/hostname: opensync-mqtt-broker-pr-$PR_NUMBER.cicd.lab.wlan.tip.build
  persistence:
    enabled: true
    storageClass: gp2

wlan-cloud-graphql-gw:
  enabled: true
  service:
    nodePortStatic: false
  ingress:
    enabled: true
    annotations:
      <<: *srv-https-annotations
    alb_https_redirect: true
    hosts:
    - host: wlan-graphql-pr-$PR_NUMBER.cicd.lab.wlan.tip.build
      paths: [
        /*
        ]
  env:
    portalsvc: wlan-portal-svc-pr-$PR_NUMBER.cicd.lab.wlan.tip.build

wlan-cloud-static-portal:
  enabled: true
  env:
    graphql: https://wlan-graphql-pr-$PR_NUMBER.cicd.lab.wlan.tip.build
  service:
    type: NodePort
  ingress:
    annotations:
      <<: *srv-https-annotations
    alb_https_redirect: true
    hosts:
      - host: wlan-ui-pr-$PR_NUMBER.cicd.lab.wlan.tip.build
        paths: [
           /*
          ]

wlan-portal-service:
  enabled: true
  service:
    type: NodePort
    nodePortStatic: false
  persistence:
    enabled: true
    storageClass: gp2
    accessMode: ReadWriteOnce
    filestoreSize: 10Gi
  tsp:
    host: wlan-portal-svc-pr-$PR_NUMBER.cicd.lab.wlan.tip.build
  ingress:
    enabled: true
    alb_https_redirect: true
    tls: []
    annotations:
      <<: *srv-https-annotations
      alb.ingress.kubernetes.io/backend-protocol: HTTPS
      alb.ingress.kubernetes.io/healthcheck-protocol: HTTPS
      alb.ingress.kubernetes.io/healthcheck-port: traffic-port
      alb.ingress.kubernetes.io/healthcheck-path: /ping
    hosts:
      - host: wlan-portal-svc-pr-$PR_NUMBER.cicd.lab.wlan.tip.build
        paths: [
           /*
          ]

wlan-prov-service:
  enabled: true

wlan-ssc-service:
  enabled: true

wlan-spc-service:
  enabled: true

wlan-port-forwarding-gateway-service:
  enabled: true
  service:
    nodePortStatic: false
  creds:
    websocketSessionTokenEncKey: MyToKeN0MyToKeN1
  externallyVisible:
    host: api.wlan-pr-$PR_NUMBER.cicd.lab.wlan.tip.build
    port: 30501
  accessPointDebugPortRange:
    length: 0

kafka:
  enabled: true
  persistence:
    storageClass: gp2

cassandra:
  enabled: true
  persistence:
    storageClass: gp2

postgresql:
  enabled: true
  persistence:
    storageClass: gp2
EOF
