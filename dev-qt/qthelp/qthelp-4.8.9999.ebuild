# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils qt4-build

DESCRIPTION="The Help module for the Qt toolkit"
SRC_URI+="
	compat? (
		ftp://ftp.qt.nokia.com/qt/source/qt-assistant-qassistantclient-library-compat-src-4.6.3.tar.gz
		http://dev.gentoo.org/~pesa/distfiles/qt-assistant-compat-headers-4.7.tar.gz
	)"

SLOT="4"
if [[ ${QT4_BUILD_TYPE} == live ]]; then
	KEYWORDS=""
else
	KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~ppc-macos ~x64-macos"
fi

IUSE="compat doc"

DEPEND="
	~dev-qt/qtcore-${PV}[aqua=,debug=]
	~dev-qt/qtgui-${PV}[aqua=,debug=]
	~dev-qt/qtsql-${PV}[aqua=,debug=,sqlite]
"
RDEPEND="${DEPEND}"

pkg_setup() {
	QT4_TARGET_DIRECTORIES="
		tools/assistant/lib
		tools/assistant/qhelpgenerator
		tools/assistant/qcollectiongenerator
		tools/assistant/qhelpconverter
		tools/qdoc3"
	QT4_EXTRACT_DIRECTORIES="
		demos
		doc
		examples
		include
		src
		tools"

	qt4-build_pkg_setup
}

src_unpack() {
	qt4-build_src_unpack

	# compat version
	# http://blog.qt.digia.com/blog/2010/06/22/qt-assistant-compat-version-available-as-extra-source-package/
	if use compat; then
		unpack qt-assistant-qassistantclient-library-compat-src-4.6.3.tar.gz \
			qt-assistant-compat-headers-4.7.tar.gz
		mv "${WORKDIR}"/qt-assistant-qassistantclient-library-compat-version-4.6.3 \
			"${S}"/tools/assistant/compat || die
		mv "${WORKDIR}"/QtAssistant "${S}"/include/ || die
	fi
}

src_prepare() {
	qt4-build_src_prepare

	use compat && epatch "${FILESDIR}"/${PN}-4.7-fix-compat.patch

	# bug 348034
	sed -i -e '/^sub-qdoc3\.depends/d' doc/doc.pri || die
}

src_configure() {
	myconf+="
		-system-libpng -system-libjpeg -system-zlib
		-no-sql-mysql -no-sql-psql -no-sql-ibase -no-sql-sqlite2 -no-sql-odbc
		-sm -xshape -xsync -xcursor -xfixes -xrandr -xrender -mitshm -xinput -xkb
		-no-multimedia -no-opengl -no-phonon -no-svg -no-webkit -no-xmlpatterns
		-no-nas-sound -no-dbus -no-cups -no-nis -fontconfig"

	qt4-build_src_configure
}

src_compile() {
	# help libQtHelp find freshly built libQtCLucene (bug #289811)
	export LD_LIBRARY_PATH="${S}/lib:${QTLIBDIR}"
	export DYLD_LIBRARY_PATH="${S}/lib:${S}/lib/QtHelp.framework"

	qt4-build_src_compile

	# ugly hack to build docs
	"${S}"/bin/qmake "LIBS+=-L${QTLIBDIR}" "CONFIG+=nostrip" || die

	if use doc; then
		emake docs
	elif [[ ${QT4_BUILD_TYPE} == release ]]; then
		# live ebuild cannot build qch_docs, it will build them through emake docs
		emake qch_docs
	fi
}

src_install() {
	qt4-build_src_install

	emake INSTALL_ROOT="${D}" install_qchdocs

	# do not compress .qch files
	docompress -x "${QTDOCDIR}"/qch

	if use doc; then
		emake INSTALL_ROOT="${D}" install_htmldocs
	fi

	if use compat; then
		insinto "${QTDATADIR#${EPREFIX}}"/mkspecs/features
		doins tools/assistant/compat/features/assistant.prf
	fi
}
