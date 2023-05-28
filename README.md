# zen-fan
Minimalist Linux fan control designed to be simple and powerful.

## Design objectives
Linux hardware monitoring [`hwmon`][2] exposes temperature measurements and fan controls as files in `sysfs`. An ideal fan control application would:

1. Obtain temperature measurements by reading from the sensor files.
2. Control fan speeds by writing into fan speed control files.
3. Minimize its own CPU and RAM resource usage. One process with one thread is the ideal.
4. Be robust against hardware changes. Plugging in a USB device must not break the fan control application.
5. Be as simple as possible.

## Implementation notes
To achieve its design objectives `zen-fan`:

* Is written in plain `bash` using version 4 features. No compilation is required.
* Doesn't invoke any other executables and doesn't depend on any other software.
* Doesn't spawn any processes/threads on each iteration.

`zen-fan` was inspired by [`fancontrol`][1]. Unlike `fancontrol`,`zen-fan`:
* Doesn't fail to start when hardware changes, a USB device is plugged-in/out.
* Doesn't crash when fans have been adjusted by another application.
* Doesn't spawn new processes on each iteration.

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
May 27 00:58:42 supernova systemd[1]: Started zen-fan fan control service.
May 27 00:58:42 supernova zen-fan[117178]: Config is /etc/zen-fan.d/host.supernova.cfg.
May 27 00:58:42 supernova zen-fan[117178]: k10temp is /sys/class/hwmon/hwmon4.
May 27 00:58:42 supernova zen-fan[117178]: corsaircpro is /sys/class/hwmon/hwmon5.
May 27 00:58:42 supernova zen-fan[117178]: CPU temperature sensor is k10temp hwmon4/temp1.
May 27 00:58:42 supernova zen-fan[117178]: GPU temperature sensor is corsaircpro hwmon5/temp3.
May 27 00:58:42 supernova zen-fan[117178]: Fans front corsaircpro hwmon5/fan1 hwmon5/fan2 hwmon5/fan3.
May 27 00:58:42 supernova zen-fan[117178]: Fans back corsaircpro hwmon5/fan4 hwmon5/fan5.
May 27 00:58:42 supernova zen-fan[117178]: CPU 48°C, GPU 46°C, front fans 600rpm+, back fans 300rpm+.
May 27 00:58:43 supernova zen-fan[117178]: Fan control loop started. Adjust fans every 7 seconds for -1 iterations.
May 27 00:58:50 supernova zen-fan[117178]: CPU 46°C, GPU 47°C, front fans 600rpm, back fans 300rpm.
May 27 00:58:57 supernova zen-fan[117178]: CPU 66°C, GPU 47°C, front fans 1100rpm+, back fans 300rpm.
May 27 00:59:04 supernova zen-fan[117178]: CPU 53°C, GPU 47°C, front fans 650rpm-, back fans 300rpm.
May 27 00:59:12 supernova zen-fan[117178]: CPU 47°C, GPU 47°C, front fans 600rpm-, back fans 300rpm.
May 27 00:59:19 supernova zen-fan[117178]: CPU 46°C, GPU 47°C, front fans 600rpm, back fans 300rpm.
May 27 00:59:26 supernova zen-fan[117178]: CPU 46°C, GPU 47°C, front fans 600rpm, back fans 300rpm.
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


[1]: https://github.com/lm-sensors/lm-sensors/blob/master/doc/fancontrol.txt
[2]: https://docs.kernel.org/hwmon/sysfs-interface.html
