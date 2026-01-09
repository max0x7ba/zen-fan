# zen-fan
Minimalist Linux fan control designed to be simple, efficient, robust and flexible.

## Design objectives
Zen principle «do more with less» is the key design pattern.

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
* Has built-in benchmark.

Average CPU time of one iteration of the fan control loop with minimal configuration (one sensor and one fan) is below 1 millisecond, resident size is under 4MM.

`zen-fan` was inspired by [`fancontrol`][1]. Unlike `fancontrol`,`zen-fan`:
* Doesn't fail to start when hardware changes, devices get different identifiers on reboot, or a USB device is plugged-in/out.
* Doesn't crash when fans have been adjusted by another application.
* Doesn't spawn new processes on each iteration.

# Usage

## Configuration
Configuration is stored in `zen-fan.d` directory. The hostname in configuration file name enables keeping any number of host-specific configuration files in the same directory / git repository.

Use [host.supernova.cfg](zen-fan.d/host.supernova.cfg) as an example. Copy and modify an existing configuration file to suit your machine sensors and fan controllers and test it. E.g.:

```
cd zen-fan
cp zen-fan.d/host.supernova.cfg zen-fan.d/host.$HOSTNAME.cfg # Modify zen-fan.d/host.$HOSTNAME.cfg to suit your machine
sudo -E ./zen-fan.sh # Loads zen-fan.d/host.$HOSTNAME.cfg
```

## Run from the source directory
Once the configuration is ready, you can keep running `zen-fan` from the source directory as is:
```
cd zen-fan
sudo -E ./zen-fan.sh
```

## Benchmark
The built-in benchmark runs the fan control loop for a number of iterations and reports the average time of one iteration. This time depends on the particular configuration, software and hardware.

Benchmark command:

```
cd zen-fan
V=0 BENCHMARK=10000 sudo -E /bin/time -v ./zen-fan.sh
```

Example output:
```
2026-01-09 07:04:12 Config is /home/max/src/zen-fan/zen-fan.d/host.supernova2.cfg.
2026-01-09 07:04:12 set_verbose 2
2026-01-09 07:04:12 set_sleep_sec 2
2026-01-09 07:04:12 k10temp is /sys/class/hwmon/hwmon4.
2026-01-09 07:04:12 dell_smm is /sys/class/hwmon/hwmon5.
2026-01-09 07:04:12 CPU temperature sensor is k10temp hwmon4/temp1.
2026-01-09 07:04:12 Fans front dell_smm hwmon5/fan1.
2026-01-09 07:04:12 set_verbose 0
2026-01-09 07:04:12 CPU 58.6°C, hwmon5/fan1 4435rpm, front fans target 4600rpm+.
2026-01-09 07:04:12 Benchmark 10,000 iterations.
2026-01-09 07:04:13 Benchmark 10,000 iterations took 0.895617 seconds, 0.000090 seconds/iteration.
	Command being timed: "./zen-fan.sh"
	User time (seconds): 0.86
	System time (seconds): 0.06
	Percent of CPU this job got: 98%
	Elapsed (wall clock) time (h:mm:ss or m:ss): 0:00.94
	Average shared text size (kbytes): 0
	Average unshared data size (kbytes): 0
	Average stack size (kbytes): 0
	Average total size (kbytes): 0
	Maximum resident set size (kbytes): 3712
	Average resident set size (kbytes): 0
	Major (requiring I/O) page faults: 0
	Minor (reclaiming a frame) page faults: 277
	Voluntary context switches: 1
	Involuntary context switches: 247
	Swaps: 0
	File system inputs: 0
	File system outputs: 0
	Socket messages sent: 0
	Socket messages received: 0
	Signals delivered: 0
	Page size (bytes): 4096
	Exit status: 0
```

# Install systemd service
For automatic start on boot, you may like to install `zen-fan` as a system-wide systemd service. The service runs with FIFO 20 real-time priority to be robust against high-priority CPU hogs blocking spinning up the fans.

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

### The second pid
The second pid is a `bash` coprocess used for sleeping on with 0-CPU-cycle cost. It is spawned once at start, and all it does is block in `read` syscall until termination. The main pid sleeps by blocking on `read` from the coprocess' stdout with a timeout, and this is as cheap a `sleep` as it gets.

As opposed to invoking `sleep` command, spawning a new sub-process for every sleep, which is a relatively astronomical cost to pay for sleeping. The cost aggravates with triggering `sar` system activity accounting to record this otherwise unnecessary sub-process creation noise; `auditd` and `apparmor` checks; keeps incrementing the kernel pid counter, causing assignment of ever larger/longer pids to new processes, making them harder read and wonder about the causes of the ever higher pids. Spawning sub-processes burns a lot of CPU cycles heating up the CPU, which would defeat the purpose of zen-fan.


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
