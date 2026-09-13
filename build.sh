#!/bin/sh
# Build script to generate flashable KernelSU / Magisk zip
DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_ZIP="$DIR/Xiaomi13T_67W_TurboCharge_Fix_HyperOS3.zip"
SDCARD_ZIP="/sdcard/Download/Xiaomi13T_67W_TurboCharge_Fix_HyperOS3.zip"

echo "Packaging $OUT_ZIP..."
python3 - << 'EOF'
import os, zipfile

mod_dir = os.path.dirname(os.path.abspath(__file__))
zip_out = os.path.join(mod_dir, 'Xiaomi13T_67W_TurboCharge_Fix_HyperOS3.zip')
sdcard_out = '/sdcard/Download/Xiaomi13T_67W_TurboCharge_Fix_HyperOS3.zip'

update_binary = """#!/sbin/sh
OUTFD=$2
ZIPFILE=$3

echo "****************************************"
echo "* Xiaomi 13T 67W Turbo Charge Fix      *"
echo "* HyperOS 3 / Android 16               *"
echo "* For Rakkipanda & Replacement Batt   *"
echo "* Created by Nvdorman                  *"
echo "****************************************"

MODPATH="/data/adb/modules/xiaomi13t_fastcharge_fix"
mkdir -p "$MODPATH"
unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >/dev/null

chmod 755 "$MODPATH/service.sh" 2>/dev/null
chmod 755 "$MODPATH/post-fs-data.sh" 2>/dev/null
chmod 644 "$MODPATH/module.prop" 2>/dev/null

echo "- Installation finished successfully!"
exit 0
"""

updater_script = "#MAGISK\n"

for target_zip in [zip_out, sdcard_out]:
    try:
        with zipfile.ZipFile(target_zip, 'w', zipfile.ZIP_DEFLATED) as z:
            z.writestr('META-INF/com/google/android/update-binary', update_binary)
            z.writestr('META-INF/com/google/android/updater-script', updater_script)
            for item in ['module.prop', 'service.sh', 'post-fs-data.sh']:
                if os.path.isfile(os.path.join(mod_dir, item)):
                    z.write(os.path.join(mod_dir, item), item)
            for folder in ['system', 'vendor']:
                folder_path = os.path.join(mod_dir, folder)
                if os.path.isdir(folder_path):
                    for root, dirs, files in os.walk(folder_path):
                        for file in files:
                            full_path = os.path.join(root, file)
                            rel_path = os.path.relpath(full_path, mod_dir)
                            z.write(full_path, rel_path)
        print(f"Created {target_zip}")
    except Exception as e:
        print(f"Failed to create {target_zip}: {e}")
EOF

echo "Done!"
