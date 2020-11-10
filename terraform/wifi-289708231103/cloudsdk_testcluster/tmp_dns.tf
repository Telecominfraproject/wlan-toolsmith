data "aws_lb" "main" {
  name = "k8s-wlantestcluster-2c76f622d1"
}

# 1883 9001 tip-wlan-opensync-mqtt-broker
data "aws_lb" "mqtt_broker" {
  name = "k8s-tip-tipwlano-4113985d66"
}

# 6640 tip-wlan-opensync-gw-cloud gwcontroller
# 6643 tip-wlan-opensync-gw-cloud gwredirector
# 9096 tip-wlan-opensync-gw-cloud
# 9097 tip-wlan-opensync-gw-cloud
data "aws_lb" "opensync_gw_cloud" {
  name = "k8s-tip-tipwlano-4a8628fee3"
}
