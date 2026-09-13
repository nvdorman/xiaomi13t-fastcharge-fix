#!/system/bin/sh
MODDIR=bash

# Early bind mount before mi_thermald initialization
if [ -f "$MODDIR/vendor/etc/thermald-devices.conf" ]; then
    mount --bind "$MODDIR/vendor/etc/thermald-devices.conf" /vendor/etc/thermald-devices.conf
fi
