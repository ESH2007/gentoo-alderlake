#!/bin/sh
# Copia la configuración de Portage de este repositorio a /etc/portage.
set -eu
REPO="${REPO:-/opt/gentoo-alderlake}"
P="$REPO/portage"
E="${ETC_PORTAGE:-/etc/portage}"

[ -e "$E/make.conf" ] && [ ! -e "$E/make.conf.orig" ] && cp -a "$E/make.conf" "$E/make.conf.orig"
cp -v "$P/make.conf" "$E/make.conf"
for d in package.use package.accept_keywords package.env env binrepos.conf repos.conf sets; do
	mkdir -p "$E/$d"
	cp -v "$P/$d/"* "$E/$d/"
done
mkdir -p /var/tmp/notmpfs
echo "Listo. Ahora: getuto && emerge --sync"
