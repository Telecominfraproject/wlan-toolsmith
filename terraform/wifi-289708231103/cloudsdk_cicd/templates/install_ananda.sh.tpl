#!/bin/sh
set -e

curl -s https://packagecloud.io/install/repositories/Ananda/release/script.deb.sh | bash
apt-get update && apt-get install -y ananda-core
/opt/ananda/core/ananda-cli --login ${aws_vpc_gateway_token}
