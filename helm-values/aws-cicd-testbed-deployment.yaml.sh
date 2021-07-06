#!/bin/sh

set -e

if [ -z "$1" ];
then
  echo "testbed number has not been set"
  exit 1
fi
TESTBED_NUMBER=$1

if [ -z "$2" ];
then
  # using todays date
  TODAY=1.0.0-SNAPSHOT-$(date -d "yesterday" +"%Y-%m-%d")
else
  # using provided tag
  TODAY=$2
fi


cat <<EOF
shared:
  service:
    srv-https-annotations: &srv-https-annotations
      kubernetes.io/ingress.class: alb
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/group.name: wlan-cicd
      alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-2:289708231103:certificate/bfa89c7a-5b64-4a8a-bcfe-ffec655b5285
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_302"}}'

global:
  pullPolicy: IfNotPresent
  monitoring:
    enableJmxPrometheusMetrics: true
    enablePrometheusPodMonitors: true

opensync-gw-static:
  enabled: false

common:
  efs-provisioner:
    enabled: false

opensync-gw-cloud:
  enabled: true
  image:
    tag: $TODAY
  service:
    type: LoadBalancer
    nodePortStatic: false
    annotations:
      external-dns.alpha.kubernetes.io/hostname: wlan-filestore-nola-$TESTBED_NUMBER.cicd.lab.wlan.tip.build,opensync-controller-nola-$TESTBED_NUMBER.cicd.lab.wlan.tip.build,opensync-redirector-nola-$TESTBED_NUMBER.cicd.lab.wlan.tip.build
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb-ip"
      service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
  externalhost:
    address:
      ovsdb: opensync-controller-nola-$TESTBED_NUMBER.cicd.lab.wlan.tip.build
      mqtt: opensync-mqtt-broker-nola-$TESTBED_NUMBER.cicd.lab.wlan.tip.build
  persistence:
    enabled: false
  filestore:
    url: https://wlan-filestore-nola-$TESTBED_NUMBER.cicd.lab.wlan.tip.build

opensync-mqtt-broker:
  enabled: true
  service:
    type: LoadBalancer
    nodePortStatic: false
    annotations:
      external-dns.alpha.kubernetes.io/hostname: opensync-mqtt-broker-nola-$TESTBED_NUMBER.cicd.lab.wlan.tip.build
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb-ip"
      service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
  persistence:
    enabled: true
    storageClass: gp2

wlan-cloud-graphql-gw:
  enabled: true
  image:
    tag: $TODAY
  service:
    nodePortStatic: false
  ingress:
    annotations:
      <<: *srv-https-annotations
    enabled: true
    alb_https_redirect: true
    hosts:
    - host: wlan-graphql-nola-$TESTBED_NUMBER.cicd.lab.wlan.tip.build
      paths: [
        /*
      ]
  env:
    portalsvc: wlan-portal-svc-nola-$TESTBED_NUMBER.cicd.lab.wlan.tip.build

wlan-cloud-static-portal:
  enabled: true
  image:
    tag: $TODAY
  env:
    graphql: https://wlan-graphql-nola-$TESTBED_NUMBER.cicd.lab.wlan.tip.build
  service:
    type: NodePort
  ingress:
    annotations:
      <<: *srv-https-annotations
    alb_https_redirect: true
    hosts:
      - host: wlan-ui-nola-$TESTBED_NUMBER.cicd.lab.wlan.tip.build
        paths: [
          /*
        ]

wlan-portal-service:
  enabled: true
  image:
    tag: $TODAY
  service:
    type: NodePort
    nodePortStatic: false
  persistence:
    enabled: true
    storageClass: gp2
    accessMode: ReadWriteOnce
    filestoreSize: 10Gi
  tsp:
    host: wlan-portal-svc-nola-$TESTBED_NUMBER.cicd.lab.wlan.tip.build
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
      - host: wlan-portal-svc-nola-$TESTBED_NUMBER.cicd.lab.wlan.tip.build
        paths: [
          /*
        ]

wlan-prov-service:
  enabled: true
  image:
    tag: $TODAY
  service:
    nodePortStatic: false

wlan-ssc-service:
  enabled: true
  image:
    tag: $TODAY
  service:
    nodePortStatic: false

wlan-spc-service:
  enabled: true
  image:
    tag: $TODAY
  service:
    nodePortStatic: false

wlan-port-forwarding-gateway-service:
  enabled: true
  image:
    tag: $TODAY
  service:
    nodePortStatic: false
  creds:
    websocketSessionTokenEncKey: MyToKeN0MyToKeN1
  externallyVisible:
    host: api.wlan-nola-$TESTBED_NUMBER.cicd.lab.wlan.tip.build
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
