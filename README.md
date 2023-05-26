# zen-fan
Minimalist Linux fan control designed to be simple and powerful.

## Design objectives
Linux hardware monitoring (hwmon) exposes temperature measurements and fan controls as files in sysfs. An ideal fan control application would:

1. Obtain temperature measurements by reading from the sensor files.
2. Control fan speeds by writing into fan speed control files.
3. Minimize its own CPU and RAM resource usage. One process with one thread is the ideal.
4. Be robust against hardware changes. Plugging in a USB device must not break the fan control application.

`zen-fan` was inspired by `fancontrol` script, learns from `fancontrol` mistakes and doesn't break when a USB device is plugged-in; doesn't spawn new processes/threads on each iteration; uses plain RPM units for fan control in the configuration to avoid having to calibrate pwm units.

# Usage

## Configuration
Configuration is stored in `zen-fan.d` directory.

Copy and modify an existing configuration file to suit your machine and test it. E.g.:

```
cd zen-fan
cp zen-fan.d/host.supernova.cfg zen-fan.d/host.$HOSTNAME.cfg # Modify zen-fan.d/host.$HOSTNAME.cfg to suit your machine
sudo -E ./zen-fan.sh # Test zen-fan.d/host.$HOSTNAME.cfg
```

## Install systemd service
Once your configuration is ready, you may like to install `zen-fan` systemd service:

```
cd zen-fan
sudo ./install.zen-fan.service.sh
```

Examine service status:

```
systemctl status zen-fan
journalctl -u zen-fan
```

---

Copyright (c) 2023 Maxim Egorushkin. MIT License. See the full licence in file LICENSE.
