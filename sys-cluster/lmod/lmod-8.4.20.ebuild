# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

LUA_COMPAT=( lua5-{1..3} )
inherit autotools lua-single

DESCRIPTION="Environment Module System based on Lua"
HOMEPAGE="https://lmod.readthedocs.io/en/latest"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/TACC/Lmod"
else
	SRC_URI="https://github.com/TACC/Lmod/archive/${PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}"/Lmod-${PV}
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="MIT"
SLOT="0"
IUSE="auto-swap cache dotfiles duplicate +extend italic module-cmd nocase redirect test"
REQUIRED_USE="${LUA_REQUIRED_USE}"
RESTRICT="!test? ( test )"

RDEPEND="${LUA_DEPS}
	app-shells/tcsh
	|| (
		app-shells/loksh
		app-shells/mksh
		app-shells/ksh
	)
	app-shells/zsh
	dev-lang/tcl
	dev-lang/tk
	$(lua_gen_cond_dep '
		>=dev-lua/luafilesystem-1.8.0[${LUA_USEDEP}]
		dev-lua/luajson[${LUA_USEDEP}]
		dev-lua/luaposix[${LUA_USEDEP}]
		dev-lua/lua-term[${LUA_USEDEP}]
	')
	virtual/pkgconfig
"
DEPEND="${RDEPEND}"
BDEPEND="${RDEPEND}
	test? (
		$(lua_gen_cond_dep '
			dev-util/hermes[${LUA_SINGLE_USEDEP}]
		')
	)
"

PATCHES=( "${FILESDIR}"/${PN}-8.4.19-no-libsandbox.patch )

pkg_pretend() {
	elog "You can control the siteName and syshost settings by"
	elog "using the variables LMOD_SITENAME and LMOD_SYSHOST, during"
	elog "build time, which are both set to 'Gentoo' by default."
	elog "There are a lot of options for this package, especially"
	elog "for run time behaviour. Remember to use the EXTRA_ECONF variable."
	elog "To see full list of options visit:"
	elog "\t https://lmod.readthedocs.io/en/latest/090_configuring_lmod.html"
}

src_prepare() {
	default
	rm -rf pkgs/{luafilesystem,term} || die
	rm -rf rt/{colorize,end2end,help,ifur,settarg} || die
	eautoreconf
}

src_configure() {
	local LMOD_SITENAME="${LMOD_SITENAME:-Gentoo}"
	local LMOD_SYSHOST="${LMOD_SYSHOST:-Gentoo}"

	local LUAC="${LUA%/*}/luac${LUA#*lua}"

	local myconf=(
		--with-tcl
		--with-fastTCLInterp
		--with-colorize
		--with-supportKsh
		--without-useBuiltinPkgs
		--with-siteControlPrefix
		--with-siteName="${LMOD_SITENAME}"
		--with-syshost="${LMOD_SYSHOST}"
		--with-lua_include="$(lua_get_include_dir)"
		--with-lua="${LUA}"
		--with-luac="${LUAC}"
		--with-module-root-path="${EPREFIX}/etc/modulefiles"
		--with-updateSystemFn="${EPREFIX}/etc/modulefiles/.lmod_system_update"
		--prefix="${EPREFIX}/usr/share/Lmod"
		$(use_with duplicate duplicatePaths)
		$(use_with nocase caseIndependentSorting)
		$(use_with italic hiddenItalic)
		$(use_with auto-swap autoSwap)
		$(use_with module-cmd exportedModuleCmd)
		$(use_with redirect)
		$(use_with dotfiles useDotFiles)
		$(use_with cache cachedLoads)
		$(use_with extend extendedDefault)
	)
	econf "${myconf[@]}"
}

src_compile() {
	CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" \
	default
}

src_test() {
	local -x PATH="/opt/hermes/bin:${PATH}"
	tm -vvv || die
	testcleanup || die
}

src_install() {
	default

	insinto /etc/profile.d
	newins "${ED}"/usr/share/Lmod/init/profile lmod.sh
	newins "${ED}"/usr/share/Lmod/init/profile.fish lmod.fish

	keepdir /etc/modulefiles
}
