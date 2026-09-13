# Xiaomi 13T 67W Turbo Charge Fix (HyperOS 3)

KernelSU / Magisk module to fix the 67W Mi Turbo Charge bug on **Xiaomi 13T (`mt6895` / `aristotle`)** running **HyperOS 3 (Android 16)**, especially after replacing the battery with third-party brands (such as Rakkipanda).

---

## 🛑 Problem Description

On Xiaomi 13T devices updated to HyperOS 3:
1. Plugging in the official 67W charger triggers the "Mi Turbo Charge 67W" animation normally.
2. However, the actual charging current immediately throttles to **~2.4A at 4.2V (around 10 Watts)**, and often drops further down to **500mA (~2 Watts)**.
3. Fast charging never exceeds 10W despite using the original 67W adapter and cable.

---

## 🔍 Root Cause Analysis (Non-Hypothetical)

Through live system debugging, reverse engineering `mi_thermald`, `hypsys_vendor`, and tracing kernel power_supply/dmesg:

1. **Aggressive Thermal Daemon Rule in HyperOS 3**:
   Xiaomi introduced a new rule in `/data/vendor/thermal/decrypt.txt`:
   ```ini
   [MONITOR-BAT]
   algo_type   monitor
   sensor      VIRTUAL-SENSOR
   device      battery
   trig        35000   36800   37200   38000   40400   45000
   target      300     1000    1101    1205    1308    1515
   ```
   The `VIRTUAL-SENSOR` triggers at an unusually low threshold: **36.8°C** (essentially human body temperature when holding the phone with screen on).

2. **Cooling Device Clamping**:
   When `VIRTUAL-SENSOR` exceeds 38°C, `mi_thermald` sets `/sys/class/thermal/cooling_device4` (`battery`) to level **12 / 13 / 15**.
   This immediately sets `/sys/class/power_supply/battery/charge_control_limit = 13`.

3. **Charge Pump Forced Bypass Mode**:
   In response to `charge_control_limit = 13`, the kernel driver:
   - Disengages the **Dual Charge Pump (Lion Semi `ln8000`)** 2:1 step-down mode.
   - Forces bypass mode (`master_cp_bypass=1, slave_cp_bypass=1`).
   - Drops VBUS from 9V down to 4.8V and limits Fast Charge Current (FCC) to 2900mA (10W max).

4. **Third-Party Battery Characteristic**:
   Replacement batteries (like Rakkipanda) route NTC lines through the external fuel gauge BMS (`nfg1000b`), leaving the PMIC's internal ADC floating (read as 60°C by `mt6375-gauge`). On HyperOS 3, this triggers the thermal clamping almost instantaneously.

---

## 💡 Solution

This module fixes the issue without sacrificing safety:
1. **Decouple Battery Cooling Device**: Overrides `/vendor/etc/thermald-devices.conf` by setting `cooling_name:dummy_battery` for `name:battery`. This stops `mi_thermald` from hijacking `cooling_device4`.
2. **HyperOS Turbo Property**: Sets `persist.vendor.accelerate.charge = 1` to enable full Turbo Charge capability.
3. **Background Guardian**: A lightweight daemon in `service.sh` ensures `charge_control_limit` and `cooling_device4` stay at 0 whenever the charger is connected.
4. **Hardware Safety Retained**: CPU/GPU thermal management remains 100% untouched. Hard-silicon JEITA protections (OVP/OCP/TSD on PMIC MT6375 & LN8000) and battery cell protection remain fully active.

---

## 📊 Live Verification Results

| Metric | Before Fix (Stock HyperOS 3) | After Fix (With Module) |
| :--- | :--- | :--- |
| `charge_control_limit` | `13` or `15` | `0` |
| USB VBUS Voltage | `4.3V – 4.8V` | **`9.1V – 9.3V`** |
| Battery Charge Current | `-1.1A to -2.4A` | **`-4.5A to -6.5A`** |
| Actual Charging Power | `~10W` (dropping to 2W) | **`20.2W – 28.9W`** *(at >70% SOC)* |
| Battery Temperature | `33°C – 37°C` | `38°C – 39°C` (Safe) |

---

## 🚀 Installation

### Via KernelSU / APatch / Magisk Manager:
1. Download `Xiaomi13T_67W_TurboCharge_Fix_HyperOS3.zip`.
2. Open **KernelSU Manager** -> **Modules** -> **Install**.
3. Select the zip file and reboot your device.

---

## 📜 License
MIT License.
