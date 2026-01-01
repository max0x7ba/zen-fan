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

Empirical average CPU time of one iteration is under 27 milliseconds, resident size is under 4MB.

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

## Examine service status

```
systemctl --no-pager status zen-fan
```

```
● zen-fan.service - zen-fan fan control service
     Loaded: loaded (/etc/systemd/system/zen-fan.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2023-05-30 01:06:51 BST; 8min ago
   Main PID: 8327 (zen-fan)
      Tasks: 2 (limit: 134671)
     Memory: 972.0K
        CPU: 27ms
     CGroup: /system.slice/zen-fan.service
             ├─8327 /bin/bash /etc/systemd/system/zen-fan.service.d/zen-fan
             └─8330 /bin/bash /etc/systemd/system/zen-fan.service.d/zen-fan

May 30 01:06:51 supernova zen-fan[8327]: k10temp is /sys/class/hwmon/hwmon3.
May 30 01:06:51 supernova zen-fan[8327]: corsaircpro is /sys/class/hwmon/hwmon4.
May 30 01:06:51 supernova zen-fan[8327]: CPU temperature sensor is k10temp hwmon3/temp1.
May 30 01:06:51 supernova zen-fan[8327]: GPU temperature sensor is corsaircpro hwmon4/temp3.
May 30 01:06:51 supernova zen-fan[8327]: Fans front corsaircpro hwmon4/fan1 hwmon4/fan2 hwmon4/fan3.
May 30 01:06:51 supernova zen-fan[8327]: Fans back corsaircpro hwmon4/fan4 hwmon4/fan5.
May 30 01:06:51 supernova zen-fan[8327]: CPU 46°C, GPU 45°C, hwmon4/fan1 599rpm, hwmon4/fan2 601rpm, hwmon4/fan3 600rpm, hwmon4/fan4 301r…an5 300rpm.
May 30 01:06:51 supernova zen-fan[8327]: CPU 46°C, GPU 45°C, front fans target 600rpm+, back fans target 300rpm+.
May 30 01:06:51 supernova zen-fan[8327]: Fan control loop started. Adjust fans every 7 seconds for -1 iterations.
```

The second pid is a `bash` coprocess used for sleeping on with 0-CPU-cycle cost. It is spawned once at start, and all it does is block in `read` syscall until termination.

As opposed to invoking `sleep` command, spawning a new sub-process for every sleep, which is a relatively astronomical cost to pay for sleeping. The cost aggravates with triggering `sar` system activity accounting to record this otherwise unnecessary sub-process creation noise; `auditd` and `apparmor` checks; keeps incrementing the kernel pid counter, causing assignment of ever larger/longer pids to new processes, making them harder read and wonder about the causes of the ever higher pids. Spawning sub-processes burns a lot of CPU cycles heating up the CPU, defeating the purpose of zen-fan.


## Examine service log
```
journalctl --no-pager -u zen-fan -n 3
```

Example output:
```
May 30 01:06:51 supernova zen-fan[8327]: CPU 46°C, GPU 45°C, hwmon4/fan1 599rpm, hwmon4/fan2 601rpm, hwmon4/fan3 600rpm, hwmon4/fan4 301rpm, hwmon4/fan5 300rpm.
May 30 01:06:51 supernova zen-fan[8327]: CPU 46°C, GPU 45°C, front fans target 600rpm+, back fans target 300rpm+.
May 30 01:06:51 supernova zen-fan[8327]: Fan control loop started. Adjust fans every 7 seconds for -1 iterations.
```

## Log current temperatures and fan speeds
```
sudo pkill -HUP zen-fan
```

Example output:
```
May 30 01:24:35 supernova zen-fan[8327]: CPU 43°C, GPU 44°C, hwmon4/fan1 600rpm, hwmon4/fan2 600rpm, hwmon4/fan3 601rpm, hwmon4/fan4 301rpm, hwmon4/fan5 300rpm.
```

## Increase log verbosity
```
sudo pkill -USR1 zen-fan
```

## Decrease log verbosity
```
sudo pkill -USR2 zen-fan
```

---

Copyright (c) 2023 Maxim Egorushkin. MIT License. See the full licence in file LICENSE.


[1]: https://github.com/lm-sensors/lm-sensors/blob/master/doc/fancontrol.txt
[2]: https://docs.kernel.org/hwmon/sysfs-interface.html
