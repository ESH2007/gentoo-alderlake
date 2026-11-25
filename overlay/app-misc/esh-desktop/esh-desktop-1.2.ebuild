# Copyright 2026 Emilio
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Metapaquete: escritorio Sway ligero para portátiles Intel Alder Lake"
HOMEPAGE="https://github.com/ESH2007/gentoo-alderlake"
S="${WORKDIR}"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+browser +fonts +remote stream"

RDEPEND="
	gui-wm/sway
	gui-apps/swayidle
	gui-apps/swaylock
	gnome-extra/polkit-gnome
	gui-libs/xdg-desktop-portal-wlr
	sys-apps/xdg-desktop-portal-gtk
	gui-apps/waybar
	gui-apps/wofi
	gui-apps/mako
	gui-apps/swaybg
	gui-apps/grim
	gui-apps/slurp
	gui-apps/wl-clipboard
	gui-apps/tuigreet
	gui-libs/greetd
	x11-terms/alacritty
	dev-libs/light
	x11-libs/libnotify
	media-sound/playerctl
	media-sound/pulsemixer

	media-video/pipewire
	media-video/wireplumber
	media-libs/libva-intel-media-driver
	media-video/libva-utils
	media-libs/mesa
	media-libs/vulkan-loader
	sys-firmware/sof-firmware

	net-wireless/iwd
	sys-power/tlp
	sys-power/thermald
	sys-power/powertop
	sys-apps/zram-generator
	sys-apps/xdg-desktop-portal
	x11-misc/xdg-user-dirs
	x11-themes/adwaita-icon-theme

	app-misc/jq
	sys-apps/ripgrep
	sys-apps/fd
	app-shells/fzf
	app-editors/neovim
	app-misc/fastfetch
	sys-process/btop

	browser? ( www-client/firefox-bin )
	remote? (
		net-misc/openssh
		net-misc/mosh
		app-misc/tmux
		net-fs/sshfs
		net-misc/remmina
	)
	stream? ( net-misc/moonlight )
	fonts? (
		media-fonts/jetbrains-mono
		media-fonts/noto
		media-fonts/noto-emoji
		media-fonts/fontawesome
	)
"
