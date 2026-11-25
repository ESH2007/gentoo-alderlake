# gentoo-alderlake

Configuración de una instalación **Gentoo** rápida y de bajo consumo para un
portátil HP con **Intel Core i3 de 12.ª generación (Alder Lake)**, **8 GB de RAM**
y **SSD NVMe de 512 GB**, con un escritorio **Sway** de teclado primero y
temas intercambiables.

> Empieza por la **[guía de instalación](docs/INSTALL.md)**.

## Decisiones principales

| | Elección | Motivo |
|-|----------|--------|
| Perfil | `23.0/desktop/systemd` | coincide con el binhost oficial → casi nada que compilar |
| Compilación | `-march=alderlake -O2 -pipe`, `-j4`, tmpfs de 5 GB | rápido sin agotar los 8 GB |
| Binarios | binhost oficial **x86-64-v3** (`getbinpkg`) | gcc, llvm, rust, mesa, qt… llegan compilados |
| Kernel | `gentoo-sources` + `localmodconfig` + [fragmento Alder Lake](kernel/alderlake.config) | pequeño, sin initramfs, Thread Director, MGLRU |
| Arranque | **systemd-boot** + installkernel, `timeout 0` | arranque en pocos segundos |
| Memoria | **zram** zstd (4 GB), `swappiness=180` | sin swap en el SSD |
| Batería | **TLP** + thermald + EPP + ASPM + PSR | 3–6 W en reposo |
| Red | **iwd** + systemd-resolved | sin NetworkManager |
| Escritorio | Sway, Waybar, Wofi, Mako, Alacritty, swaylock/swayidle | estable en `::gentoo`, muy ligero en la iGPU Intel |
| Temas | `brasa`, `glaciar`, `musgo` (originales) | `SUPER+CTRL+T` cambia todo a la vez |

## Estructura

```
portage/      make.conf, package.use, package.accept_keywords, package.env,
              binhost (binrepos.conf), overlay (repos.conf), set @esh
kernel/       fragmento de configuración + build.sh
system/       sysctl, zram, TLP, iwd, greetd, cmdline del kernel, servicios
overlay/      overlay "esh": app-misc/esh-desktop (metapaquete),
              x11-themes/esh-tools (scripts y temas)
dotfiles/     configuración de Sway, Waybar, Wofi, Mako, Alacritty,
              plantillas de color y scripts esh-* ; install.sh
themes/       temas: theme.env + wallpaper.png (generado por make-wallpapers.py)
docs/         INSTALL, KERNEL, BATTERY, THEMES
```

## Documentación

- [Instalación paso a paso](docs/INSTALL.md)
- [Kernel](docs/KERNEL.md)
- [Batería y temperatura](docs/BATTERY.md)
- [Interfaz, temas y atajos](docs/THEMES.md)

## Estado

Configuración escrita a partir de la documentación de Gentoo y de cada
programa, **todavía sin probar en el equipo real**. Los nombres de paquetes y la
sintaxis de los programas cambian a veces: si `emerge` o Sway se quejan de algo,
abre un issue con el mensaje exacto.

Licencia: MIT (ebuilds: GPL-2).
