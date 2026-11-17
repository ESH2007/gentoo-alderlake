#!/bin/sh
# Copia los archivos de sistema de este repositorio a /etc. Ejecutar como root.
# Hace copia de seguridad (*.orig) de lo que ya exista.
set -eu
REPO="${REPO:-/opt/gentoo-alderlake}"

put() { # put <origen> <destino>
	mkdir -p "$(dirname "$2")"
	[ -e "$2" ] && [ ! -e "$2.orig" ] && cp -a "$2" "$2.orig"
	cp -v "$1" "$2"
}

S="$REPO/system"
put "$S/sysctl.d/90-esh.conf"            /etc/sysctl.d/90-esh.conf
put "$S/systemd/zram-generator.conf"     /etc/systemd/zram-generator.conf
put "$S/journald.conf.d/size.conf"       /etc/systemd/journald.conf.d/size.conf
put "$S/iwd/main.conf"                   /etc/iwd/main.conf
put "$S/greetd/config.toml"              /etc/greetd/config.toml
put "$S/modprobe.d/esh.conf"             /etc/modprobe.d/esh.conf
put "$S/tlp.d/90-esh.conf"               /etc/tlp.d/90-esh.conf
put "$S/kernel/install.conf"             /etc/kernel/install.conf
install -Dm755 "$S/esh-session" /usr/local/bin/esh-session
[ -e /etc/kernel/cmdline ] || put "$S/kernel/cmdline" /etc/kernel/cmdline

grep -q CAMBIA-ESTO /etc/kernel/cmdline && \
	echo "AVISO: edita /etc/kernel/cmdline y pon el PARTUUID de tu raíz (blkid)." || true
