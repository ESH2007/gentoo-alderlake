# Guía de instalación paso a paso

Equipo objetivo: portátil HP con Intel Core i3 de 12.ª generación (Alder Lake),
8 GB de RAM, SSD NVMe de 512 GB, arranque UEFI.

Resultado: Gentoo con systemd, kernel propio sin initramfs arrancado por
systemd-boot, escritorio Sway y la mayoría de paquetes pesados descargados
ya compilados del binhost oficial. Tiempo aproximado: 2–4 horas (casi todo es
descarga y la compilación del kernel).

> Todo lo que va en bloques de código se ejecuta como **root** salvo que se diga
> lo contrario. Sustituye `nvme0n1` si tu disco tiene otro nombre (`lsblk`).
> Esta guía **borra el disco completo**.

---

## 0. Antes de empezar (BIOS de HP)

1. Enciende y pulsa **F10** para entrar en la BIOS.
2. **Secure Boot: desactivado** (el kernel propio no está firmado).
3. Modo de arranque: **UEFI nativo** (sin CSM/Legacy).
4. Si existe, cambia "SATA/Storage mode" de RAID/Intel RST a **AHCI**: con RST
   activado Linux no ve el NVMe.
5. Arranca desde un USB con la ISO **Gentoo LiveGUI** o **minimal**
   (https://www.gentoo.org/downloads/). Pulsa **F9** para el menú de arranque.

## 1. Red y hora

```sh
# Wi‑Fi (en la ISO minimal):
net-setup wlan0          # asistente; o usa iwctl si está disponible
ping -c 3 gentoo.org
chronyd -q 'server pool.ntp.org iburst' 2>/dev/null || ntpd -q -g
```

**Importante:** guarda ahora la lista de módulos que usa *este* portátil.
La usaremos para construir un kernel que solo incluya lo necesario:

```sh
lsmod > /root/lsmod.txt
```

## 2. Particiones y sistemas de archivos

| Partición       | Tamaño | Tipo         | Montaje |
|-----------------|--------|--------------|---------|
| /dev/nvme0n1p1  | 1 GiB  | EFI (FAT32)  | /efi    |
| /dev/nvme0n1p2  | resto  | Linux (ext4) | /       |

Sin partición swap: usamos **zram** (swap comprimida en RAM), que es mucho más
rápida en un equipo de 8 GB. (Contrapartida: no hay hibernación, sí suspensión.)

```sh
sgdisk --zap-all /dev/nvme0n1
sgdisk -n1:0:+1G -t1:ef00 -c1:EFI  /dev/nvme0n1
sgdisk -n2:0:0   -t2:8304 -c2:root /dev/nvme0n1
mkfs.vfat -F 32 -n EFI /dev/nvme0n1p1
mkfs.ext4 -L gentoo /dev/nvme0n1p2

mkdir -p /mnt/gentoo
mount -o noatime /dev/nvme0n1p2 /mnt/gentoo
mkdir -p /mnt/gentoo/efi
mount /dev/nvme0n1p1 /mnt/gentoo/efi
```

## 3. Stage3 (desktop + systemd)

```sh
cd /mnt/gentoo
BASE=https://distfiles.gentoo.org/releases/amd64/autobuilds
F=$(wget -qO- $BASE/latest-stage3-amd64-desktop-systemd.txt | awk '/stage3.*tar/{print $1; exit}')
wget "$BASE/$F" "$BASE/$F.asc"
gpg --import /usr/share/openpgp-keys/gentoo-release.asc
gpg --verify "$(basename "$F").asc"           # debe decir "Good signature"
tar xpf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
rm stage3-*.tar.xz*
```

## 4. Traer este repositorio

```sh
mkdir -p /mnt/gentoo/opt/gentoo-alderlake
wget -qO- https://github.com/ESH2007/gentoo-alderlake/archive/refs/heads/main.tar.gz \
  | tar xz --strip-components=1 -C /mnt/gentoo/opt/gentoo-alderlake
cp /root/lsmod.txt /mnt/gentoo/root/
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
```

## 5. Entrar en el nuevo sistema

```sh
arch-chroot /mnt/gentoo        # monta /proc, /sys, /dev, efivars por ti
source /etc/profile
export PS1="(chroot) $PS1"
export REPO=/opt/gentoo-alderlake
```

## 6. Portage: make.conf, binhost y perfil

```sh
sh $REPO/portage/install-portage.sh          # copia make.conf, package.*, binhost, overlay
mkdir -p /var/tmp/portage
mount -t tmpfs -o size=5G,mode=775,uid=250,gid=250,noatime tmpfs /var/tmp/portage

emerge-webrsync
eselect profile list | grep 'desktop/systemd'
eselect profile set default/linux/amd64/23.0/desktop/systemd

getuto                                       # claves para verificar los binarios
emerge -1q app-portage/cpuid2cpuflags
cpuid2cpuflags                               # compara con CPU_FLAGS_X86 en make.conf
```

Si `cpuid2cpuflags` muestra algo distinto, edita `/etc/portage/make.conf` y
copia su salida a `CPU_FLAGS_X86`.

Actualiza todo el sistema (casi todo llega precompilado; los paquetes que se
compilan son los que tienen USE distintas a las del binhost):

```sh
emerge -avuDN @world
```

## 7. Zona horaria, idioma y teclado

```sh
ln -sf ../usr/share/zoneinfo/America/Bogota /etc/localtime   # usa tu ciudad
cat > /etc/locale.gen <<'L'
es_ES.UTF-8 UTF-8
en_US.UTF-8 UTF-8
L
locale-gen
eselect locale set es_ES.utf8
echo 'KEYMAP=es' > /etc/vconsole.conf        # o la-latin1 para teclado latinoamericano
env-update && source /etc/profile && export PS1="(chroot) $PS1"
```

## 8. Firmware y kernel

```sh
emerge -av sys-kernel/linux-firmware sys-firmware/sof-firmware sys-firmware/intel-microcode
emerge -av sys-kernel/installkernel sys-kernel/gentoo-sources
eselect kernel set 1
```

Configuración del arranque **antes** de compilar el kernel (installkernel la usa):

```sh
systemd-machine-id-setup
sh $REPO/system/install-system.sh            # sysctl, zram, iwd, TLP, greetd, /etc/kernel/*
blkid -s PARTUUID -o value /dev/nvme0n1p2    # copia el valor…
nano /etc/kernel/cmdline                     # …y sustitúyelo en root=PARTUUID=CAMBIA-ESTO
bootctl install                              # instala systemd-boot en /efi
```

Compila el kernel (≈ 15–25 min con localmodconfig). Detalles en [KERNEL.md](KERNEL.md):

```sh
cd /usr/src/linux
$REPO/kernel/build.sh /root/lsmod.txt
bootctl list                                 # debe aparecer la entrada de Gentoo
```

Menú de arranque instantáneo:

```sh
printf 'timeout 0\nconsole-mode keep\neditor no\n' > /efi/loader/loader.conf
```

(Mantén pulsada la barra espaciadora al encender para ver el menú.)

## 9. fstab

```sh
cat > /etc/fstab <<'F'
# <fs>                   <montaje>          <tipo> <opciones>                                       <dump> <pass>
LABEL=gentoo             /                  ext4   noatime,commit=60                                0 1
LABEL=EFI                /efi               vfat   umask=0077,noatime                               0 2
tmpfs                    /var/tmp/portage   tmpfs  size=5G,mode=775,uid=250,gid=250,noatime,nofail 0 0
tmpfs                    /tmp               tmpfs  size=2G,mode=1777,noatime                        0 0
F
```

`/var/tmp/portage` en RAM acelera la compilación y evita escrituras al SSD.
Los paquetes enormes compilan en disco (`/etc/portage/package.env/big`).

> **Ojo con la línea de `/var/tmp/portage`.** Usa `uid=250,gid=250` (el número
> del usuario `portage`) y no `uid=portage`: en el arranque el nombre puede no
> resolverse y la línea falla. `nofail` hace que, si aun así falla, el sistema
> arranque igual (Portage compilará en disco) en lugar de caer en *emergency
> mode*. Si ya estás en emergency mode: escribe la contraseña de root, ejecuta
> `nano /etc/fstab`, pon `#` delante de esa línea y `reboot`.
>
> Para comprobarlo después del primer arranque: `findmnt /var/tmp/portage`
> debe mostrar `tmpfs`.

## 10. Usuarios y sudo

```sh
echo hp-gentoo > /etc/hostname
passwd                                       # contraseña de root
emerge -av app-admin/sudo dev-vcs/git
useradd -m -G wheel,video,audio,input,users -s /bin/bash emilio
passwd emilio
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel
```

Sustituye el repositorio descargado por un clon de git (para poder actualizarlo):

```sh
rm -rf $REPO && git clone https://github.com/ESH2007/gentoo-alderlake.git $REPO
```

## 11. Escritorio

```sh
emerge -av @esh                               # Sway, Waybar, Wofi, Mako, Alacritty, TLP…
```

Todo el escritorio está en el repositorio oficial `::gentoo` y es estable: **no
hace falta GURU** ni ningún otro overlay aparte de `esh`. (Hyprland salió de
`::gentoo` en 2026; por eso este repositorio usa Sway.) Si emerge pide alguna
palabra clave (`~amd64`), añádela a `/etc/portage/package.accept_keywords/esh`
(o usa `emerge -av --autounmask-write @esh` y luego `dispatch-conf`).

Servicios mínimos y dotfiles para tu usuario:

```sh
sh $REPO/system/services.sh
su - emilio -c "$REPO/dotfiles/install.sh glaciar"
```

## 12. Reiniciar

```sh
exit                      # sal del chroot
umount -R /mnt/gentoo
reboot
```

Inicia sesión en la pantalla de texto (tuigreet) y entrarás en Sway.
Conéctate a la Wi‑Fi con `SUPER+ALT+Espacio → Herramientas → Wi‑Fi` o:

```sh
iwctl station wlan0 connect "NombreDeTuRed"
```

## 13. Comprobaciones

```sh
systemd-analyze                                   # objetivo: < 5 s hasta el escritorio
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
sudo tlp-stat -s -p | head -40                    # modo AC/BAT y EPP
zramctl                                           # /dev/zram0 de ~4 GB con zstd
vainfo | grep -i driver                           # "Intel iHD driver"
sudo powertop                                     # en reposo con batería: ~3–6 W
```

Después del primer arranque, opcional pero recomendable:

- **Firmware mínimo:** `dmesg | grep -i firmware` muestra lo que carga tu equipo.
  Edita `/etc/portage/savedconfig/sys-kernel/linux-firmware-*`, deja solo esas
  líneas (i915/adlp_*, tgl_guc/huc, iwlwifi o rtw89…, intel/sof*) y
  `emerge -1 linux-firmware`. Ocupa ~20 MB en lugar de ~1 GB.
- **Limpieza:** `emerge -a --depclean`.

## Mantenimiento

```sh
git -C /opt/gentoo-alderlake pull                 # actualiza configuración y overlay
sudo emerge --sync && sudo emerge -avuDN @world   # o SUPER+ALT+Espacio → Herramientas
```

Al actualizar `gentoo-sources`: `eselect kernel set <nuevo>`,
`cp /usr/src/linux-<viejo>/.config /usr/src/linux/` y `$REPO/kernel/build.sh`.
