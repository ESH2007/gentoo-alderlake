# Copyright 2026 Emilio
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="Temas y scripts esh-* (menú, temas, energía, capturas) para Sway"
HOMEPAGE="https://github.com/ESH2007/gentoo-alderlake"
EGIT_REPO_URI="https://github.com/ESH2007/gentoo-alderlake.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""

RDEPEND="
	app-misc/jq
	gui-apps/wofi
	gui-apps/mako
	gui-apps/swaybg
	x11-libs/libnotify
"

src_compile() { :; }

src_install() {
	dobin dotfiles/bin/esh-*
	insinto /usr/share/esh
	doins -r themes dotfiles/templates
	dodoc README.md docs/*.md
}

pkg_postinst() {
	elog "Instala los dotfiles en tu usuario con:"
	elog "  /opt/gentoo-alderlake/dotfiles/install.sh"
	elog "y elige un tema con:  esh-theme brasa | glaciar | musgo"
}
