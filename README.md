# zen-fan
Minimalist Linux fan control designed to be simple and powerful.

## Design objectives
Linux hardware monitoring `hwmon` exposes temperature measurements and fan controls as files in `sysfs`. An ideal fan control application would:

1. Obtain temperature measurements by reading from the sensor files.
2. Control fan speeds by writing into fan speed control files.
3. Minimize its own CPU and RAM resource usage. One process with one thread is the ideal.
4. Be robust against hardware changes. Plugging in a USB device must not break the fan control application.

## Implementation notes
To achieve its design objectives `zen-fan`:

* Is written in plain `bash` using version 4 features. No compilation is required.
* Doesn't invoke any other executables and doesn't depend on any other software.
* Doesn't spawn any processes/threads on each iteration.

`zen-fan` was inspired by `fancontrol` script. `zen-fan` learns from `fancontrol` mistakes and:
* Doesn't fail to start when hardware changes, a USB device is plugged-in/out.
* Doesn't crash when fans have been adjusted by another application.
* Doesn't spawn new processes on each iteration.
* Uses plain RPM units for fan control in the configuration to avoid having to calibrate human-unfriendly PWM units.

# Usage

## Configuration
Configuration is stored in `zen-fan.d` directory. Use [host.supernova.cfg](zen-fan.d/host.supernova.cfg) as an example.

Copy and modify an existing configuration file to suit your machine and test it. E.g.:

```
cd zen-fan
cp zen-fan.d/host.supernova.cfg zen-fan.d/host.$HOSTNAME.cfg # Modify zen-fan.d/host.$HOSTNAME.cfg to suit your machine
sudo -E ./zen-fan.sh # Loads zen-fan.d/host.$HOSTNAME.cfg
```

## Run from the source directory
Once your configuration is ready, you can run `zen-fan` from the source directory as is:
```
cd zen-fan
sudo -E ./zen-fan.sh
```

## Install systemd service
Once your configuration is ready, you may like to install `zen-fan` as systemd service:

```
cd zen-fan
sudo ./install.zen-fan.service.sh
```

### Examine service status

```
systemctl status zen-fan
```

### Examine service log
```
journalctl -u zen-fan
```

Example output:
```
May 26 06:07:56 supernova systemd[1]: Started zen-fan fan control service.
May 26 06:07:56 supernova zen-fan[102403]: Host config is /etc/zen-fan.d/host.supernova.cfg.
May 26 06:07:56 supernova zen-fan[102403]: k10temp is /sys/class/hwmon/hwmon4.
May 26 06:07:56 supernova zen-fan[102403]: corsaircpro is /sys/class/hwmon/hwmon5.
May 26 06:07:56 supernova zen-fan[102403]: CPU temperature sensor is k10temp hwmon4/temp1.
May 26 06:07:56 supernova zen-fan[102403]: GPU temperature sensor is corsaircpro hwmon5/temp3.
May 26 06:07:56 supernova zen-fan[102403]: Fans front corsaircpro hwmon5/fan1 hwmon5/fan2 hwmon5/fan3.
May 26 06:07:56 supernova zen-fan[102403]: Fans back corsaircpro hwmon5/fan4 hwmon5/fan5.
May 26 06:07:56 supernova zen-fan[102403]: CPU 90°C, GPU 47°C, +fans front 1800rpm, +fans back 300rpm.
May 26 06:07:57 supernova zen-fan[102403]: Fan control loop started. Adjust fans every 7 seconds for -1 iterations.
May 26 06:08:04 supernova zen-fan[102403]: CPU 90°C, GPU 47°C, fans front 1800rpm, fans back 300rpm.
May 26 06:08:11 supernova zen-fan[102403]: CPU 90°C, GPU 47°C, fans front 1800rpm, fans back 300rpm.
...
May 26 11:47:28 supernova zen-fan[102403]: CPU 90°C, GPU 47°C, fans front 1800rpm, fans back 300rpm.
May 26 11:47:35 supernova zen-fan[102403]: CPU 86°C, GPU 48°C, fans front 1800rpm, fans back 300rpm.
May 26 11:47:42 supernova zen-fan[102403]: CPU 83°C, GPU 48°C, -fans front 1700rpm, fans back 300rpm.
May 26 11:47:50 supernova zen-fan[102403]: CPU 81°C, GPU 48°C, -fans front 1650rpm, fans back 300rpm.
May 26 11:47:57 supernova zen-fan[102403]: CPU 80°C, GPU 48°C, -fans front 1600rpm, fans back 300rpm.
May 26 11:48:05 supernova zen-fan[102403]: CPU 78°C, GPU 48°C, -fans front 1550rpm, fans back 300rpm.
May 26 11:48:12 supernova zen-fan[102403]: CPU 77°C, GPU 48°C, -fans front 1500rpm, fans back 300rpm.
May 26 11:48:20 supernova zen-fan[102403]: CPU 77°C, GPU 48°C, fans front 1500rpm, fans back 300rpm.
May 26 11:48:27 supernova zen-fan[102403]: CPU 77°C, GPU 48°C, fans front 1500rpm, fans back 300rpm.
May 26 11:48:34 supernova zen-fan[102403]: CPU 76°C, GPU 48°C, -fans front 1450rpm, fans back 300rpm.
May 26 11:48:41 supernova zen-fan[102403]: CPU 74°C, GPU 48°C, -fans front 1400rpm, fans back 300rpm.
May 26 11:48:49 supernova zen-fan[102403]: CPU 73°C, GPU 48°C, -fans front 1350rpm, fans back 300rpm.
May 26 11:48:56 supernova zen-fan[102403]: CPU 72°C, GPU 47°C, -fans front 1300rpm, fans back 300rpm.
May 26 11:49:03 supernova zen-fan[102403]: CPU 67°C, GPU 47°C, -fans front 1150rpm, fans back 300rpm.
May 26 11:49:11 supernova zen-fan[102403]: CPU 55°C, GPU 47°C, -fans front 750rpm, fans back 300rpm.
May 26 11:49:18 supernova zen-fan[102403]: CPU 50°C, GPU 47°C, -fans front 600rpm, fans back 300rpm.
May 26 11:49:26 supernova zen-fan[102403]: CPU 49°C, GPU 47°C, fans front 600rpm, fans back 300rpm.
May 26 11:49:33 supernova zen-fan[102403]: CPU 47°C, GPU 47°C, fans front 600rpm, fans back 300rpm.
May 26 11:49:40 supernova zen-fan[102403]: CPU 47°C, GPU 47°C, fans front 600rpm, fans back 300rpm.
May 26 11:49:47 supernova zen-fan[102403]: CPU 47°C, GPU 47°C, fans front 600rpm, fans back 300rpm.
```

### Increase log verbosity
```
sudo pkill -USR1 zen-fan
```

### Decrease log verbosity
```
sudo pkill -USR2 zen-fan
```

---

Copyright (c) 2023 Maxim Egorushkin. MIT License. See the full licence in file LICENSE.
