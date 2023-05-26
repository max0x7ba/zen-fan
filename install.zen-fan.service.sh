#!/bin/bash -x

cd "$(dirname "$0")"

systemctl stop zen-fan.service

[[ -d /etc/systemd/system/zen-fan.service.d ]] || mkdir /etc/systemd/system/zen-fan.service.d
cp zen-fan.sh /etc/systemd/system/zen-fan.service.d/zen-fan
cp zen-fan.service /etc/systemd/system/
cp -r zen-fan.d /etc

systemctl daemon-reload
systemctl enable zen-fan.service
systemctl start zen-fan.service
systemctl status zen-fan.service