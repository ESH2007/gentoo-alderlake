# Interfaz: Hyprland + temas ESH

Un escritorio de mosaico con teclado primero, inspirado en la experiencia de
Omarchy (Hyprland, Waybar, lanzador, notificaciones, temas que cambian todo a la
vez), pero con configuración, temas, fondos y scripts **propios**.

| Pieza | Programa |
|-------|----------|
| Compositor | Hyprland |
| Barra | Waybar |
| Lanzador y menús | Wofi |
| Notificaciones | Mako |
| Terminal | Alacritty |
| Bloqueo / inactividad | hyprlock / hypridle |
| Fondo | swaybg |
| Capturas | grim + slurp + wl-clipboard |

## Temas

| Tema | Estilo |
|------|--------|
| `brasa` | oscuro cálido, acento naranja |
| `glaciar` | oscuro frío, acento cian (por defecto) |
| `musgo` | claro tipo papel, acento verde |

Cambiar: `SUPER+CTRL+T` o `esh-theme <nombre>`. Se recargan al momento
Hyprland, Waybar, Mako, Wofi, Alacritty, hyprlock y el fondo.

### Crear tu propio tema

```sh
cp -r ~/.local/share/esh/themes/glaciar ~/.local/share/esh/themes/mitema
```

Edita `theme.env` (colores en hexadecimal) y, si quieres, sustituye
`wallpaper.png`. `themes/make-wallpapers.py` genera fondos de curvas de nivel a
partir de los colores del tema (requiere Pillow). Las plantillas que usan esos
colores están en `dotfiles/templates/` (`{{ACCENT}}` → `#5cc8ff`,
`{{ACCENT_RAW}}` → `5cc8ff`).

## Atajos de teclado

`SUPER+K` los muestra todos en una lista con buscador.

| Atajo | Acción |
|-------|--------|
| `SUPER+Enter` | Terminal |
| `SUPER+Espacio` | Lanzador de aplicaciones |
| `SUPER+ALT+Espacio` | Menú ESH (temas, energía, herramientas, sistema) |
| `SUPER+Escape` | Bloquear / suspender / reiniciar / apagar |
| `SUPER+B` / `SUPER+N` | Navegador / Neovim |
| `SUPER+W` | Cerrar ventana |
| `SUPER+F` / `SUPER+M` | Pantalla completa / maximizar |
| `SUPER+T` | Ventana flotante |
| `SUPER+J` | Cambiar dirección de la división |
| `SUPER+flechas` | Mover el foco |
| `SUPER+SHIFT+flechas` | Mover la ventana |
| `SUPER+1…9` | Ir al escritorio |
| `SUPER+SHIFT+1…9` | Enviar ventana al escritorio |
| `SUPER+Tab` | Escritorio siguiente |
| `SUPER+S` | Escritorio temporal (scratchpad) |
| `SUPER+CTRL+T` | Cambiar tema |
| `SUPER+CTRL+P` | Modo de energía |
| `SUPER+CTRL+B` | Activar/desactivar blur y sombras |
| `SUPER+CTRL+L` | Bloquear pantalla |
| `SUPER+CTRL+N` | No molestar |
| `Impr` / `SHIFT+Impr` / `SUPER+Impr` | Captura de zona / pantalla / ventana |
| 3 dedos en el touchpad | Cambiar de escritorio |

Tus ajustes personales van en `~/.config/hypr/local.conf` (no se sobrescribe).
