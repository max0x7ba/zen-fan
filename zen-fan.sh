#!/bin/bash
set -eu

host_cfg=$PWD/zen-fan.d/host.$HOSTNAME.cfg

function log {
    printf '%(%F %T)T %s\n' -1 "$1"
}

function raise {
    log "Error: $1" >&2
    exit 1
}

function find_hwmon {
    local hwmon_name=$1
    local -n path=$1
    for hwmon in hwmon*; do
        read <$hwmon/name
        if [[ "$hwmon_name" == "$REPLY" ]]; then
            path=$hwmon
            log "$hwmon_name is $PWD/$path."
            return
        fi
    done
    raise "$hwmon_name not found in $PWD."
}

function read_temp_sensor {
    local -n temp=temp_$1
    local -n file=sensor_file_${1}
    read temp <${file}_input
    temp=$((temp / 1000))
}

readonly action_names=('-' '' '+')
function format_action {
    local -n new_rpm=rpm_fan_$1
    local -n old_rpm=prev_rpm_fan_$1
    local -i a=$(((new_rpm > old_rpm) - (new_rpm < old_rpm) + 1))
    declare -g action_fan_$1="${action_names[$a]}fans $1 ${new_rpm}rpm"
}

function calculate_rpm {
    local -n temp=temp_$1
    local -i temp_min=$3
    local -i temp_max=$4
    local -i rpm_min=$5
    local -i rpm_max=$6
    local -i rpm_step=$7
    local -i temp_pct=$(( ((temp < temp_min ? temp_min : (temp > temp_max ? temp_max : temp)) - temp_min) * 100 / (temp_max - temp_min) ))
    declare -g rpm_fan_$2=$(( rpm_min + ((rpm_max - rpm_min) * temp_pct / 100) / rpm_step * rpm_step ))
    if((verbose>=1)); then
        format_action $2
    fi
}

function adjust_fans {
    local -n new_rpm=rpm_fan_$1
    local -n old_rpm=prev_rpm_fan_$1
    if((old_rpm != new_rpm)); then
        old_rpm=$new_rpm
        local -n fans=fans_$1
        for fan in ${fans[@]}; do
            if((verbose>=2)); then
                read <${fan}_input
                echo "$fan $REPLY -> $new_rpm."
            fi
            echo $new_rpm >${fan}_target
        done
    fi
}

fan_groups=()
function create_fan_group {
    local name=$1
    fan_groups+=($1)
    declare -g -i rpm_fan_$1
    declare -g -i prev_rpm_fan_$1=0
    declare -g action_fan_$1
    local -n fans=fans_$1
    local hwmon_name=$2
    local -n path=$2
    shift 2
    fans=(${@/#/$path/})
    log "Fans ${name} $hwmon_name ${fans[*]}."
}

temp_sensors=()
function create_temp_sensor {
    local name=$1
    temp_sensors+=($1)
    declare -g temp_$1
    local -n file=sensor_file_$1
    local hwmon_name=$2
    local -n path=$2
    file=$path/$3
    log "${name^^} temperature sensor is $hwmon_name $file."
}

sensors_to_fan_groups=()
function map_temp_to_rpm {
    sensors_to_fan_groups+=("$*")
}

function log_status {
    local s f line=""
    for s in ${temp_sensors[@]}; do
        local -n temp=temp_$s
        line+="${s^^} $temp°C, "
    done
    for f in ${fan_groups[@]}; do
        format_action $f
        local -n action_fan=action_fan_$f
        line+="$action_fan, "
    done
    log "${line:0:-2}."
}

function map {
    local -n args=$2
    local a
    for a in "${args[@]}"; do
        $1 $a
    done
}

function update_fan_speeds {
    map read_temp_sensor temp_sensors
    map calculate_rpm sensors_to_fan_groups
    v1off || log_status
    map adjust_fans fan_groups
}

declare -i verbose
function v1off ((verbose<1))
function v2off ((verbose<2))
function v3off ((verbose<3))
function set_verbose {
    verbose=$(($1 < 0 ? 0 : $1 > 3 ? 3 : $1))
    v3off && set +x || set -x
}
set_verbose ${V:-1}

function on_sigusr {
    set_verbose $((verbose + $1))
    log "$2 verbose=$verbose."
}

# Temperature sensors and fan controls files get re-opened on each read or write because bash cannot rewind open file descriptors.
# Keep hwmon directory open and resolved to speed up re-opening the files using relative paths.
cd /sys/class/hwmon

log "Host config is $host_cfg."
source $host_cfg

function create_sleep2 {
    coproc read
    declare -r -g sleep2_fd=${COPROC[0]}
    function sleep2 { read -t$1 -u$sleep2_fd || (($?>128)); }
}

trap "" SIGUSR1 SIGUSR2

# cd ~/src/zen-fan/; TEST=1 sudo -E ./zen-fan.sh
if((${TEST:-0})); then
    function test_signals {
        set +e -x
        create_sleep2
        local pid=$1
        for((i=4;i--;)); do
            sleep2 2
            kill -USR1 $pid
        done
        for((i=4;i--;)); do
            sleep2 2
            kill -USR2 $pid
        done
        sleep2 2
        kill -USR1 $pid
    }

    SLEEP=0.5
    N=40
    test_signals $$ &
fi

update_fan_speeds

declare -i N=${N:--1}
if((N)); then
    create_sleep2
    trap 'on_sigusr +1 SIGUSR1' SIGUSR1
    trap 'on_sigusr -1 SIGUSR2' SIGUSR2

    readonly sleep_sec=${SLEEP:-7}
    trap 'log "Fan control loop terminated."' EXIT
    log "Fan control loop started. Adjust fans every $sleep_sec seconds for $N iterations."
    while((N -= N > 0)); do
        sleep2 $sleep_sec
        update_fan_speeds
    done
    :
fi
