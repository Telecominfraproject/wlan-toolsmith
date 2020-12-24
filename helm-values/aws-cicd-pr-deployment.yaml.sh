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
      alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:us-east-2:289708231103:certificate/bfa89c7a-5b64-4a8a-bcfe-ffec655b5285"
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_302"}}'

global:
  # Change to an unused port prefix range to prevent port conflicts
  # with other instances running within the same k8s cluster
  nodePortPrefix: 3$PR_NUMBER
  nodePortPrefixExt: 4$PR_NUMBER
  nsPrefix: tip-pr-$PR_NUMBER
  # image pull policy
  pullPolicy: Always
  repository: tip-tip-wlan-cloud-docker-repo.jfrog.io
  # override default mount path root directory
  # referenced by persistent volumes and log files
  persistence:
  # flag to enable debugging - application support required
  debugEnabled: true
# Annotations for namespace
annotations: {
    "helm.sh/resource-policy": keep
}
dockerRegistrySecret: ewoJImF1dGhzIjogewoJCSJ0aXAtdGlwLXdsYW4tY2xvdWQtZG9ja2VyLXJlcG8uamZyb2cuaW8iOiB7CgkJCSJhdXRoIjogImRHbHdMWEpsWVdRNmRHbHdMWEpsWVdRPSIKCQl9Cgl9LAoJIkh0dHBIZWFkZXJzIjogewoJCSJVc2VyLUFnZW50IjogIkRvY2tlci1DbGllbnQvMTkuMDMuOCAobGludXgpIgoJfQp9
opensync-gw-static:
  enabled: false
common:
  efs-provisioner:
    enabled: false
    provisioner:
      efsFileSystemId: fs-49a5104c
      awsRegion: us-west-2
      efsDnsName: fs-49a5104c.efs.us-west-2.amazonaws.com
      storageClass: aws-efs
opensync-gw-cloud:
  service:
    type: LoadBalancer
    annotations:
      external-dns.alpha.kubernetes.io/hostname: wlan-filestore-pr-$PR_NUMBER.cicd.lab.wlan.tip.build,opensync-controller-pr-$PR_NUMBER.cicd.lab.wlan.tip.build,opensync-redirector-pr-$PR_NUMBER.cicd.lab.wlan.tip.build
  enabled: true
  externalhost:
    address:
      ovsdb: opensync-controller-pr-$PR_NUMBER.cicd.lab.wlan.tip.build
      mqtt: opensync-mqtt-broker-pr-$PR_NUMBER.cicd.lab.wlan.tip.build
  persistence:
    enabled: false
  filestore:
    url: "https://wlan-filestore-pr-$PR_NUMBER.cicd.lab.wlan.tip.build"
  image:
    name: opensync-gateway-cloud
opensync-mqtt-broker:
  service:
    type: LoadBalancer
    annotations:
      external-dns.alpha.kubernetes.io/hostname: "opensync-mqtt-broker-pr-$PR_NUMBER.cicd.lab.wlan.tip.build"
  enabled: true
  replicaCount: 1
  persistence:
    enabled: true
    storageClass: "gp2"
wlan-cloud-graphql-gw:
  enabled: true
  ingress:
    annotations:
      <<: *srv-https-annotations
    enabled: true
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
  service:
    type: NodePort
    nodePort_static: false
  enabled: true
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
  creds:
    enabled: true
    db:
      postgresUser:
        password: postgres
      tipUser:
        password: tip_password
    schema_repo:
      username: tip-read
      password: tip-read
    postgres:
      singleDataSourceUsername: tip_user
      singleDataSourcePassword: tip_password
      singleDataSourceSslKeyPassword: mypassword
wlan-ssc-service:
  enabled: true
  creds:
    sslKeyPassword: mypassword
    sslKeystorePassword: mypassword
    sslTruststorePassword: mypassword
    cassandra:
      tip_user: tip_user
      tip_password: tip_password 
    schema_repo:
      username: tip-read
      password: tip-read
wlan-spc-service:
  enabled: true
  creds:
    sslKeyPassword: mypassword
    sslKeystorePassword: mypassword
    sslTruststorePassword: mypassword
wlan-port-forwarding-gateway-service:
  enabled: true
  creds:
    websocketSessionTokenEncKey: MyToKeN0MyToKeN1
  externallyVisible:
    host: api.wlan-pr-$PR_NUMBER.cicd.lab.wlan.tip.build
    port: 30501
  debugPorts: []
zookeeper:
  enabled: true
  replicaCount: 1
  persistence:
    enabled: true
    storageClass: "gp2"
kafka:
  enabled: true
  replicaCount: 1
  persistence:
    enabled: true
    storageClass: "gp2"
  creds:
    sslKeystorePassword: mypassword
    sslTruststorePassword: mypassword
    sslKeyPassword: mypassword
cassandra:
  enabled: true
  cluster:
    replicaCount: 1
    seedCount: 1
  persistence:
    enabled: true
    storageClass: "gp2"
  resources:
    requests:
      cpu: 500m
      memory: 3800Mi
    limits:
      cpu: 1000m
      memory: 3800Mi
  creds:
    sslKeystorePassword: mypassword
    sslTruststorePassword: mypassword
postgresql:
  enabled: true
  postgresqlPassword: postgres
## NOTE: If we are using glusterfs as Storage class, we don't really need 
## replication turned on, since the data is anyway replicated on glusterfs nodes
## Replication is useful: 
## a. When we use HostPath as storage mechanism
## b. If master goes down and one of the slave is promoted as master
  replication:
    enabled: true
    slaveReplicas: 1
  persistence:
    enabled: true
    storageClass: "gp2"
EOF
