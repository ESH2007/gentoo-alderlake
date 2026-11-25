# Batería y temperatura

Objetivo realista con un i3 de 12.ª gen y esta configuración: **3–6 W en reposo**
con el brillo al 40 % y Wi‑Fi conectada, lo que en una batería HP de 41 Wh son
unas **7–10 horas** de uso ligero (web, texto).

## Piezas

| Componente | Qué hace | Archivo |
|------------|----------|---------|
| **TLP** | Cambia EPP, perfil de plataforma, ASPM, runtime PM, Wi‑Fi y audio según cargador/batería | `system/tlp.d/90-esh.conf` |
| **thermald** | Controla la temperatura antes de que el firmware baje la frecuencia de golpe | servicio |
| **intel_pstate + EPP** | La CPU elige frecuencia; EPP le dice si priorizar rendimiento o energía | kernel + TLP |
| **zram** | Swap comprimida en RAM: nada de escrituras de swap al SSD | `system/systemd/zram-generator.conf` |
| **sysctl** | Escrituras a disco agrupadas cada 15 s, sin NMI watchdog | `system/sysctl.d/90-esh.conf` |
| **Sway** | sin blur, sombras ni animaciones: solo redibuja lo que cambia | `dotfiles/config/sway/config` |
| **VA-API** | Vídeo decodificado por la GPU (YouTube/mpv gastan mucho menos) | `intel-media-driver`, `LIBVA_DRIVER_NAME=iHD` |
| **swayidle** | Atenúa a 2,5 min, bloquea a 5, apaga pantalla a 5,5, suspende a 15 | `dotfiles/config/sway/config` (sección Arranque) |

## ¿Por qué TLP y no power-profiles-daemon?

Los dos hacen cosas parecidas y **no deben convivir**. TLP es más completo (ASPM,
USB, Wi‑Fi, audio, límites de la GPU) y se ajusta solo al enchufar o
desenchufar. El menú de energía (`SUPER+CTRL+P` o clic en la batería de Waybar)
permite forzar **Rendimiento** (`tlp ac`), **Ahorro** (`tlp bat`) o volver a
**Automático** (`tlp start`).

## Firefox con aceleración por hardware

En `about:config`: `media.ffmpeg.vaapi.enabled = true`. Compruébalo en
`about:support` → *Media* o con `intel_gpu_top` (paquete `x11-apps/igt-gpu-tools`)
mientras reproduces un vídeo.

## Medir

```sh
sudo powertop                 # pestaña "Overview": consumo y quién despierta la CPU
sudo tlp-stat -b              # estado y salud de la batería
sudo tlp-stat -p              # EPP actual, perfil de plataforma
cat /sys/class/power_supply/BAT0/power_now   # µW instantáneos
```

No ejecutes `powertop --auto-tune` como servicio: pelea con TLP.

## Umbrales de carga

Muchos HP de consumo no permiten limitar la carga al 80 % desde Linux. Si
`sudo tlp-stat -b` muestra `charge_control_end_threshold`, descomenta las líneas
`START/STOP_CHARGE_THRESH_BAT0` en `/etc/tlp.d/90-esh.conf` para alargar la vida
de la batería.
