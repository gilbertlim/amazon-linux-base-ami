#!/bin/bash -ex
perl -pi -e 's/^#?Port 22$/Port 5299/' /etc/ssh/sshd_config
service sshd restart || service ssh restart
