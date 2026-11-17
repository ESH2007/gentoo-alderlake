# Kernel para Alder Lake

Idea: partir **solo de los módulos que usa este portátil** (`localmodconfig`)
y encima aplicar un fragmento con los ajustes de rendimiento y energía
([`kernel/alderlake.config`](../kernel/alderlake.config)). El resultado es un
kernel pequeño (≈ 10–15 MB), que compila en 15–25 minutos y arranca **sin
initramfs**: NVMe, ext4 y vfat van dentro del kernel.

## Uso

```sh
emerge -av sys-kernel/gentoo-sources
eselect kernel set 1
cd /usr/src/linux
/opt/gentoo-alderlake/kernel/build.sh /root/lsmod.txt
```

`build.sh` hace:

1. Copia `/proc/config.gz` (el kernel del USB de instalación) a `.config`.
2. `make LSMOD=/root/lsmod.txt localmodconfig`: desactiva todo módulo que no
   estuviera cargado en el live USB. **Conecta antes de `lsmod` todo lo que
   uses** (USB, auriculares Bluetooth, webcam…) para que se conserven.
3. Mezcla el fragmento con `scripts/kconfig/merge_config.sh` y `olddefconfig`.
4. Integra el microcódigo de Intel correcto para tu CPU (`EXTRA_FIRMWARE`).
5. Compila con `KCFLAGS="-march=alderlake -O2"` e instala con
   `installkernel` → `kernel-install` → entrada de systemd-boot.

## Qué cambia el fragmento

| Área | Opciones | Por qué |
|------|----------|---------|
| Planificador | `SCHED_MC`, `SCHED_CLUSTER`, `INTEL_HFI_THERMAL` | Intel Thread Director: el planificador sabe qué núcleo es P (rendimiento) o E (eficiencia) |
| Latencia | `PREEMPT`, `HZ_1000`, `NO_HZ_IDLE` | escritorio fluido; sin ticks cuando el núcleo está en reposo |
| Frecuencia | `X86_INTEL_PSTATE` + gobernador `powersave` | con HWP el hardware decide la frecuencia según el EPP que fija TLP |
| Energía PCIe | `PCIEASPM_POWER_SUPERSAVE` | estados L1.x del NVMe y Wi‑Fi (mayor ahorro en reposo) |
| Térmica | `INT340X_THERMAL`, `ACPI_PLATFORM_PROFILE`, `HP_WMI` | thermald y los perfiles de ventilador de HP |
| Memoria | `LRU_GEN` (MGLRU), `ZRAM` + zstd, THP en `madvise` | con 8 GB, menos tirones bajo presión de memoria |
| Arranque | `EFI_STUB`, NVMe/ext4/vfat integrados, `KERNEL_ZSTD` | sin initramfs, descompresión rápida |
| Gráficos | `DRM_I915=m` | como módulo carga GuC/HuC/DMC desde `/lib/firmware` |
| Portátil | `PINCTRL_ALDERLAKE`, `I2C_HID_ACPI`, `HID_MULTITOUCH` | touchpad I2C de HP |
| Audio | `SND_SOC_SOF_ALDERLAKE` | la mayoría de portátiles Alder Lake usan Sound Open Firmware |
| Depuración | `FTRACE`, `KPROBES`, `SLUB_DEBUG` fuera | menos sobrecarga |

## Línea de comandos del kernel

[`system/kernel/cmdline`](../system/kernel/cmdline) → `/etc/kernel/cmdline`:

- `quiet loglevel=3`: arranque silencioso.
- `nowatchdog nmi_watchdog=0`: menos despertares de la CPU.
- `zswap.enabled=0`: usamos zram; ambos a la vez no tienen sentido.
- `i915.enable_fbc=1 i915.enable_psr=1`: compresión del framebuffer y
  *Panel Self Refresh* (la pantalla se refresca sola cuando nada cambia).
  Si ves parpadeos, quita `i915.enable_psr=1`.
- `pcie_aspm.policy=powersupersave`: ahorro PCIe desde el arranque.

## Si algo no funciona

- **No arranca (kernel panic, VFS: unable to mount root):** revisa el PARTUUID de
  `/etc/kernel/cmdline` y que `CONFIG_BLK_DEV_NVME=y` y `CONFIG_EXT4_FS=y`.
- **Falta un dispositivo** (Wi‑Fi, webcam, lector de huellas): `make menuconfig`,
  busca con `/` el driver, actívalo como módulo y vuelve a ejecutar `build.sh`
  (reutiliza el `.config` existente).
- **Plan B:** `emerge sys-kernel/gentoo-kernel-bin` instala un kernel genérico
  precompilado (necesita `USE=dracut` en installkernel para el initramfs).
