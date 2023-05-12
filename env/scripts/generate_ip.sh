#!/bin/bash -ex

# see https://stackoverflow.com/questions/47596369/how-to-pass-argument-in-packer-provision-script
cat > $IP_FILE_DESTINATION << EOF
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
EOF