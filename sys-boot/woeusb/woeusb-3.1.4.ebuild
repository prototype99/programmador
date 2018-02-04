# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit git-r3 qmake-utils autotools

DESCRIPTION="Creates windows installer on usb media from an iso image"
HOMEPAGE="https://github.com/slacka/WoeUSB"
SRC_URI=""

EGIT_COMMIT="v3.1.4"
EGIT_REPO_URI="https://github.com/slacka/WoeUSB"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}
	sys-apps/coreutils
	sys-apps/grep
	sys-apps/util-linux
	sys-block/parted
	sys-fs/ntfs3g
	sys-fs/dosfstools
	sys-boot/grub:2
	x11-libs/wxGTK:3.0
"

src_prepare() {
	eautoreconf
	default
}

src_compile() {
	eautomake || die "eautomake failed"
}

src_install() {
	emake DESTDIR="${D}" install
}
