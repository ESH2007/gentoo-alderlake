#!/bin/sh
# Instala los dotfiles ESH en tu usuario (NO como root).
#   ./install.sh [tema]     (por defecto: glaciar)
# Copia las configuraciones a ~/.config (guardando *.bak de lo que exista),
# enlaza los scripts en ~/.local/bin y los temas en ~/.local/share/esh.
set -eu
[ "$(id -u)" -eq 0 ] && { echo "Ejecuta esto con tu usuario, no como root." >&2; exit 1; }

here=$(cd "$(dirname "$0")" && pwd)
repo=$(dirname "$here")
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}/esh"
BIN="$HOME/.local/bin"

mkdir -p "$CONF" "$DATA" "$BIN"

for app in sway waybar alacritty wofi; do
	for f in "$here/config/$app"/*; do
		dst="$CONF/$app/$(basename "$f")"
		mkdir -p "$CONF/$app"
		# local.conf es tuyo: no se sobrescribe nunca
		[ "$(basename "$f")" = local.conf ] && [ -e "$dst" ] && continue
		[ -e "$dst" ] && [ ! -L "$dst" ] && ! cmp -s "$f" "$dst" && cp "$dst" "$dst.bak"
		cp "$f" "$dst"
	done
done

ln -sfn "$repo/themes" "$DATA/themes"
ln -sfn "$here/templates" "$DATA/templates"
for s in "$here"/bin/esh-*; do ln -sf "$s" "$BIN/$(basename "$s")"; done

case ":$PATH:" in *":$BIN:"*) ;; *)
	echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
	export PATH="$BIN:$PATH"
	echo "Añadido ~/.local/bin al PATH en ~/.profile" ;;
esac

xdg-user-dirs-update 2>/dev/null || true
"$BIN/esh-theme" "${1:-glaciar}"
echo "Listo. Cierra sesión y entra en Sway. SUPER+K muestra los atajos."
