# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
PYTHON_COMPAT=( python2_7 python3_{4,5,6} )
inherit eutils versionator python-any-r1 check-reqs

DESCRIPTION="Cross-platform application development framework"
HOMEPAGE="https://www.qt.io/"
SRC_URI=""

android_archlist=()

LICENSE="|| ( GPL-2 GPL-3 LGPL-3 ) FDL-1.3"
SLOT=5/$(get_version_component_range 1-2)
KEYWORDS="~x86 ~amd64"

IUSE="
	android-arch_armeabi
	+android-arch_armeabi-v7a
	+android-arch_arm64-v8a
	+android-arch_x86
	+android-arch_x86_64
"
REQUIRED_USE="|| (
	android-arch_armeabi
	android-arch_armeabi-v7a
	android-arch_arm64-v8a
	android-arch_x86
	android-arch_x86_64
)"

RDEPEND="
	${PYTHON_DEPS}
	virtual/opengl
	>=dev-db/sqlite-3.8.10.2:3
	sys-libs/zlib
	dev-libs/libxml2:2
	dev-libs/libxslt
	virtual/rubygems
	media-libs/fontconfig:1.0
	dev-util/android-sdk-update-manager
	=dev-util/android-ndk-13*
"
DEPEND="
	${RDEPEND}
	dev-util/gperf
	dev-lang/ruby
	sys-apps/sed
"

case ${PV} in
	5.9999)
		# git dev branch
		QT5_BUILD_TYPE="live"
		EGIT_BRANCH="dev"
		;;
	5.?.9999|5.??.9999|5.???.9999)
		# git stable branch
		QT5_BUILD_TYPE="live"
		EGIT_BRANCH=${PV%.9999}
		;;
	*_alpha*|*_beta*|*_rc*)
		# development release
		MY_P=qt-everywhere-src-${PV/_/-}
		SRC_URI="https://download.qt.io/development_releases/qt/${PV%.*}/${PV/_/-}/single/${MY_P}.tar.xz"
		S=${WORKDIR}/${MY_P}
		;;
	*)
		# official stable release
		MY_P=qt-everywhere-src-${PV/_/-}
		SRC_URI="https://download.qt.io/official_releases/qt/${PV%.*}/${PV}/single/${MY_P}.tar.xz"
		S=${WORKDIR}/${MY_P}
		;;
esac
EGIT_REPO_URI="https://github.com/qt/qt5.git"

get_last() {
	ls $1 | sort -V | tail -n 1
}

pkg_pretend()
{
	# For building at least one architecture
	CHECKREQS_DISK_BUILD="3700M"
	check-reqs_pkg_pretend
}

pkg_setup() {
	S_ORIG=${S}
	pkg_setup_archlist
	pkg_setup_disk_space_checks
}

pkg_setup_archlist() {
	use android-arch_armeabi && android_archlist+=("armeabi")
	use android-arch_armeabi-v7a && android_archlist+=("armeabi-v7a")
	use android-arch_arm64-v8a && android_archlist+=("arm64-v8a")
	use android-arch_x86 && android_archlist+=("x86")
	use android-arch_x86_64 && android_archlist+=("x86_64")
}

pkg_setup_disk_space_checks() {
	local SPACE=2000
	for android_arch in "${android_archlist[@]}"
	do
		SPACE=$((SPACE + 1700))
	done
	CHECKREQS_DISK_BUILD="${SPACE}M"
	check-reqs_pkg_setup
}

setup_vars_for_arch() {
	android_arch=$1

	S="${S_ORIG}-${android_arch}"

	case "$android_arch" in
		arm64-v8a|x86_64)
			ANDROID_MINIMUM_PLATFORM=21
			;;
		*)
			ANDROID_MINIMUM_PLATFORM=16
			;;
	esac

	ANDROID_SDK_ROOT="/opt/android-sdk-update-manager"
	ANDROID_NDK_ROOT="/opt/android-ndk"
	ANDROID_BUILD_TOOLS_REVISION=$(get_last ${ANDROID_SDK_ROOT}/build-tools)
	ANDROID_API_VERSION=android-$ANDROID_MINIMUM_PLATFORM
	ANDROID_NDK_PLATFORM=android-$ANDROID_MINIMUM_PLATFORM
	ANDROID_QT_INSTALL=/opt/qt-android/$(get_version_component_range 1-2)/${android_arch}
	ANDROID_QT_PREFIX=${EPREFIX}${ANDROID_QT_INSTALL}

	NDKHOST="linux-$(uname -m)"

	DESTSUBDIR=${D%/}${ANDROID_QT_INSTALL}
}

src_unpack() {
	unpack ${A}
	for android_arch in "${android_archlist[@]}"
	do
		cp -r "${S}" "${S}-${android_arch}"
	done
	#rm -r ${S} # do not delete because ebuild will fail at src prepare.
	# Looks like there is a check for dir existence in ebuild system  itself
}

foreach_arch_subdir() {
	for android_arch in "${android_archlist[@]}"
	do
		setup_vars_for_arch $android_arch
		cd "${S}"
		local msg="Running $* in ${S} dir"
		einfo "${msg}"
		"$@" || die -n "${msg} failed" || return $?
	done
}

src_prepare() {
	foreach_arch_subdir src_prepare_arch
	default
}

src_prepare_arch() {
	# preventing target libraries install to host's /libs directory
	# see https://bugreports.qt.io/browse/QTBUG-39300
	epatch "${FILESDIR}/qt-android-5.7.1-notargetlibs.patch"

	# Todo fix bug:
	# Platform-specific patching will fail.
	# Pathes are token from Arch and seems like they
	# couldn't be applied on Gentoo.
	# Actually gentoo has same patching in it's upstream QT
	# so it may be used instead probably.

	# Platform specific patches.
	case "$android_arch" in
		armeabi)
			epatch "${FILESDIR}/qt-android-5.10-nomapboxglnative.patch"
			epatch "${FILESDIR}/qt-android-5.7.1-nojavascriptcorejit.patch"
			;;
		*)
			;;
	esac
}

src_configure() {
	foreach_arch_subdir src_configure_arch
}

src_configure_arch() {
	# Todo determine whether these unsets are doyng anything at all in Gentoo
	unset CC
	unset CXX
	unset CFLAGS
	unset CXXFLAGS
	unset LDFLAGS
	unset CHOST
	unset QMAKESPEC
	unset QTDIR
	unset CARCH

	configure_opts="
		-confirm-license
		-opensource
		-silent
		-prefix ${ANDROID_QT_PREFIX}
		-docdir ${ANDROID_QT_PREFIX}/doc
		-plugindir ${ANDROID_QT_PREFIX}/plugins
		-libdir ${ANDROID_QT_PREFIX}/lib
		-libexecdir ${ANDROID_QT_PREFIX}/libexec
		-no-rpath
		-nomake tests
		-nomake examples
		-android-ndk ${ANDROID_NDK_ROOT}
		-android-sdk ${ANDROID_SDK_ROOT}
		-android-ndk-host ${NDKHOST}
		-skip qttranslations
		-skip qtserialport
		-no-warnings-are-errors
		-no-pkg-config
		-qt-zlib
		-qt-freetype
		-android-arch ${android_arch}
		-android-ndk-platform ${ANDROID_NDK_PLATFORM}
		-no-optimized-tools
		-release
		-xplatform android-g++
		-android-toolchain-version 4.9"

	if [ "$ANDROID_MINIMUM_PLATFORM" -lt 18 ]; then
		configure_opts+="
			-skip qtconnectivity"
	fi

	# Platform specific patches
	case "$android_arch" in
		armeabi)
			 configure_opts+="
				 -skip qtwebglplugin"
			;;
		x86*)
			 configure_opts+="
				 -no-sql-mysql
				 -no-sql-psql"
			;;
		*)
			;;
	esac

	"${S}"/configure ${configure_opts}
}

src_compile() {
	foreach_arch_subdir src_compile_arch
}

src_compile_arch() {
	if [ -f Makefile ] || [ -f GNUmakefile ] || [ -f makefile ]; then
		emake || die "emake failed"
	fi
}

src_install() {
	foreach_arch_subdir src_install_arch
}

src_install_arch() {
	emake INSTALL_ROOT="${D}" install

	case "$android_arch" in
		arm64-v8a)
			toolchain=aarch64-linux-android-4.9
			stripFolder=aarch64-linux-android
			;;
		armeabi*)
			toolchain=arm-linux-androideabi-4.9
			stripFolder=arm-linux-androideabi
			;;
		x86)
			toolchain=x86-4.9
			stripFolder=i686-linux-android
			;;
		x86_64)
			toolchain=x86_64-4.9
			stripFolder=x86_64-linux-android
			;;
	esac

	STRIP=${ANDROID_NDK_ROOT}/toolchains/${toolchain}/prebuilt/${NDKHOST}/${stripFolder}/bin/strip
	find "${DESTSUBDIR}"/lib -name 'lib*.so' -exec "${STRIP}" {} \;
	find "${DESTSUBDIR}"/lib \( -name 'lib*.a' ! -name 'libQt5Bootstrap.a' ! -name 'libQt5QmlDevTools.a' \) -exec "${STRIP}" {} \;
	find "${DESTSUBDIR}"/plugins -name 'lib*.so' -exec "${STRIP}" {} \;
}

pkg_postinst() {
	elog "In Qt Creator you should do some things in Tools -> Options:"
	elog "1. -> Devices -> Android. Specify all locations properly"
	elog "\tand enable \"automatically create kits\" option"
	elog "2. -> Build & Run -> Qt Versions. Add qmake from"
	elog "\t${ANDROID_QT_INSTALL}/bin"
	elog "3. -> Build & Run -> Kits. Now at least one new autodetected"
	elog "\tAndroid/GCC kit should appear here."
	elog "\tSome of arches are built with Clang toolkit from Android NDK"
	elog "\tinstead of GCC. Those kits will actually build apps with"
	elog "\tClang though it has GCC from NDK selected as a compiler"
	elog "\thttps://bugreports.qt.io/browse/QTCREATORBUG-11846"
	elog
	elog "Please refer to QT documentation - it should give more"
	elog "recent and detailed info: http://doc.qt.io/"
	elog
	elog "Also see possible android related issues:"
	elog "https://wiki.qt.io/Qt_for_Android_known_issues"
}