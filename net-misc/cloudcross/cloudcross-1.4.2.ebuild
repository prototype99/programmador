# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit git-r3 qmake-utils

DESCRIPTION="Multi-cloud client for OneDrive, Yandex disk, Google Drive, Dropbox and Mail.ru"
HOMEPAGE="http://cloudcross.mastersoft24.ru"
SRC_URI=""

EGIT_COMMIT=v${PV}
EGIT_REPO_URI="https://github.com/MasterSoft24/${PN}"
RDEPEND="
		dev-qt/qtcore:5
		dev-qt/qtnetwork:5
		net-misc/curl
		"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~hppa ~ppc ~ppc64 ~s390 ~sh ~x86"
IUSE=""

DEPEND="${RDEPEND}
		"

src_compile() {
	mkdir build
	cd build
	eqmake5 ../CloudCross.pro
	emake
}

src_install() {
	dobin build/ccross-app/ccross
	dobin build/ccross-curl-executor/ccross-curl
}
