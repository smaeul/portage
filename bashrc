export CONFIG_SITE="${PORTAGE_CONFIGROOT}/etc/portage/config.site"
export TZ=":Etc/UTC"

pre_src_prepare() {
	# Always apply user patches
	# From https://wiki.gentoo.org/wiki//etc/portage/patches
	[[ ${EAPI:-0} == [012345] ]] || return

	if ! type epatch_user > /dev/null 2>&1; then
		local epatch_names="EPATCH_SOURCE EPATCH_USER_SOURCE epatch_user_death_notice epatch_user epatch"
		source <(awk "/^# @(FUNCTION|VARIABLE): / { p = 0 } /^_EPATCH_ECLASS/ { p = 0 } /^# @(FUNCTION|VARIABLE): (${epatch_names// /|})\$/ { p = 1 } p { print }" ${PORTDIR}/eclass/epatch.eclass)
	fi

	epatch_user

	for name in $epatch_names; do
		unset $name
	done
}

post_src_install() {
	local dest dir file link

	# INSTALL_MASK, but also for packages
	for dir in /etc/{conf.d,init.d,portage,xinetd.d} {/usr,}/lib/systemd /usr/share/{bash-completion,locale}; do
		test -d "${D}/${dir}" && rm -rf "${D}/${dir}"
	done
	for file in charset.alias; do
		find "${D}" -name "$file" -exec rm -f {} +
	done
}
