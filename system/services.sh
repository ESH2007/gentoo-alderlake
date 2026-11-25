#!/bin/sh
# Activa SOLO los servicios necesarios. Ejecutar como root tras instalar @esh.
set -eu

# Red: iwd (Wi‑Fi + DHCP) y resolved (DNS). Nada de NetworkManager.
systemctl enable iwd.service systemd-resolved.service
# Dentro de arch-chroot /etc/resolv.conf está ocupado (lo usa la USB): en ese
# caso, crea el enlace desde fuera tras `exit`, antes de desmontar:
#   ln -sf ../run/systemd/resolve/stub-resolv.conf /mnt/gentoo/etc/resolv.conf
ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf 2>/dev/null || \
	echo "AVISO: no pude enlazar /etc/resolv.conf (normal en chroot). Hazlo tras salir del chroot."

# Energía: TLP (incluye su servicio de suspensión) y thermald (térmica Intel)
systemctl enable tlp.service thermald.service
# TLP y power-profiles-daemon no deben convivir
systemctl mask power-profiles-daemon.service 2>/dev/null || true
# TLP gestiona el radio; evita que rfkill de systemd pelee con él
systemctl mask systemd-rfkill.service systemd-rfkill.socket

# SSD: TRIM semanal
systemctl enable fstrim.timer

# Reloj por NTP sin daemon pesado
systemctl enable systemd-timesyncd.service

# Inicio de sesión
systemctl enable greetd.service

# Swap comprimido en RAM (lo crea zram-generator automáticamente al arrancar)
systemctl daemon-reload

# Cosas que retrasan el arranque y no hacen falta
systemctl disable systemd-networkd-wait-online.service 2>/dev/null || true
systemctl mask systemd-networkd-wait-online.service 2>/dev/null || true

# Servicios de usuario (PipeWire) se activan solos por socket; para todos los usuarios:
systemctl --global enable pipewire.socket pipewire-pulse.socket wireplumber.service

echo "Servicios configurados. Arranque crítico: systemd-analyze critical-chain"
