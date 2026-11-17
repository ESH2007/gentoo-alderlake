#!/bin/sh
# Compila e instala el kernel con localmodconfig + el fragmento Alder Lake.
# Uso (como root, dentro de /usr/src/linux):
#   /opt/gentoo-alderlake/kernel/build.sh [/root/lsmod.txt]
set -eu

REPO="${REPO:-/opt/gentoo-alderlake}"
LSMOD_FILE="${1:-}"
cd /usr/src/linux

if [ ! -f .config ]; then
	# Partimos de la configuración del kernel que está corriendo (live USB)
	if [ -r /proc/config.gz ]; then
		zcat /proc/config.gz > .config
	else
		make defconfig
	fi
	# Solo los módulos que se están usando (cargados en el live USB, en ESTE portátil)
	if [ -n "$LSMOD_FILE" ]; then
		make LSMOD="$LSMOD_FILE" localmodconfig
	else
		yes '' | make localmodconfig
	fi
fi

scripts/kconfig/merge_config.sh -m .config "$REPO/kernel/alderlake.config"

# Microcódigo Intel dentro del kernel (no usamos initramfs).
# Alder Lake móvil = familia 6, modelo 0x9a; el archivo depende del stepping.
fam=$(awk '/^cpu family/{print $4; exit}' /proc/cpuinfo)
mod=$(awk '/^model[[:space:]]*:/{print $3; exit}' /proc/cpuinfo)
step=$(awk '/^stepping/{print $3; exit}' /proc/cpuinfo)
ucode=$(printf 'intel-ucode/%02x-%02x-%02x' "$fam" "$mod" "$step")
if [ -f "/lib/firmware/$ucode" ]; then
	scripts/config --set-str EXTRA_FIRMWARE "$ucode" \
		--set-str EXTRA_FIRMWARE_DIR /lib/firmware \
		--enable MICROCODE
	echo "Microcódigo integrado: $ucode"
else
	echo "AVISO: no existe /lib/firmware/$ucode (emerge sys-firmware/intel-microcode)" >&2
fi

make olddefconfig

# Optimiza el propio kernel para Alder Lake
make -j"$(nproc)" KCFLAGS="-march=alderlake -O2"
make modules_install
# installkernel[systemd-boot] → kernel-install → /efi/<machine-id>/<versión>/
make install

echo "Kernel instalado. Comprueba la entrada con: bootctl list"
