#!/bin/bash

echo 'net.ipv4.tcp_timestamps=0' >> /etc/sysctl.conf

sysctl -w net.ipv4.tcp_timestamps=0
