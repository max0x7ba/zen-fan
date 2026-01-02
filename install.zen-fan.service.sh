#!/bin/bash -xe

# Copyright (c) 2023 Maxim Egorushkin. MIT License. See the full licence in file LICENSE.

cd "$(dirname "$0")"

systemctl disable --now zen-fan.service || :

[[ -d /etc/systemd/system/zen-fan.service.d ]] || mkdir /etc/systemd/system/zen-fan.service.d
cp zen-fan.sh /etc/systemd/system/zen-fan.service.d/zen-fan
cp zen-fan.service /etc/systemd/system/
cp -r zen-fan.d /etc

systemctl daemon-reload
systemctl enable --now zen-fan.service
systemctl status zen-fan.service
