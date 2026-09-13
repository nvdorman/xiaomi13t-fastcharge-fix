#!/system/bin/sh
MODDIR=bash

# Wait for boot completion
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

sleep 5

# 1. Force Xiaomi HyperOS Turbo Accelerate Charge property
resetprop -n persist.vendor.accelerate.charge 1
resetprop -n persist.vendor.domain.charge true

# 2. Ensure thermald-devices.conf is mounted and mi_thermald is using it
if grep -q "cooling_name:battery" /vendor/etc/thermald-devices.conf 2>/dev/null; then
    mount --bind "$MODDIR/vendor/etc/thermald-devices.conf" /vendor/etc/thermald-devices.conf
    stop mi_thermald
    sleep 1
    start mi_thermald
fi

# 3. Background guardian daemon to prevent thermal clamping
(
    while true; do
        USB_ONLINE=$(cat /sys/class/power_supply/usb/online 2>/dev/null)
        if [ "$USB_ONLINE" = "1" ]; then
            # Reset charge control limit to 0 if clamped
            CHG_LIMIT=$(cat /sys/class/power_supply/battery/charge_control_limit 2>/dev/null)
            if [ -n "$CHG_LIMIT" ] && [ "$CHG_LIMIT" != "0" ]; then
                echo 0 > /sys/class/power_supply/battery/charge_control_limit 2>/dev/null
            fi

            # Reset battery cooling device cur_state if clamped
            CDEV_CUR=$(cat /sys/class/thermal/cooling_device4/cur_state 2>/dev/null)
            if [ -n "$CDEV_CUR" ] && [ "$CDEV_CUR" != "0" ]; then
                echo 0 > /sys/class/thermal/cooling_device4/cur_state 2>/dev/null
            fi
        fi
        sleep 3
    done
) &

