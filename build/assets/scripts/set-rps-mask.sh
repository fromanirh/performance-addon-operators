#!/usr/bin/env bash

dev=$1
[ -n "${dev}" ] || { echo "The device argument is missing" >&2 ; exit 1; }

mask=$2
[ -n "${mask}" ] || { echo "The mask argument is missing" >&2 ; exit 1; }

dev_dir="/sys/class/net/${dev}"
if [ ! -d "${dev_dir}" ]; then      # the net device was renamed, find the new name
    systemd_devs=$(systemctl list-units -t device | grep sys-subsystem-net-devices | cut -d' ' -f1)

    for systemd_dev in ${systemd_devs}; do
        dev_sysfs=$(systemctl show "${systemd_dev}" -p SysFSPath --value)

        dev_orig_name="${dev_sysfs##*/}"
        if [ "${dev_orig_name}" = "${dev}" ]; then
            dev_name="${systemd_dev##*-}"
            dev_name="${dev_name%%.device}"
            echo "${dev} device was renamed to $dev_name"

            dev_dir="/sys/class/net/${dev_name}"
            break
        fi
    done
fi

[ -d "${dev_dir}" ] || { echo "${dev_dir}" directory not found >&2 ; exit 1; }

find "${dev_dir}"/queues -type f -name rps_cpus -exec sh -c "echo ${mask} | cat > {}" \;