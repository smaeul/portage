export TZ=":Etc/UTC"

pre_src_prepare() {
	# Always apply user patches
	# From https://wiki.gentoo.org/wiki//etc/portage/patches
	[[ ${EAPI:-0} == [012345] ]] || return

	if ! type estack_push > /dev/null 2>&1; then
		local estack_names="eshopts_push eshopts_pop evar_push evar_push_set evar_pop estack_push estack_pop"
		source <(awk "/^# @(FUNCTION|VARIABLE): / { p = 0 } /^_ESTACK_ECLASS/ { p = 0 } /^# @(FUNCTION|VARIABLE): (${estack_names// /|})\$/ { p = 1 } p { print }" ${PORTDIR}/eclass/estack.eclass)
	fi
	if ! type epatch_user > /dev/null 2>&1; then
		local epatch_names="EPATCH_SOURCE EPATCH_USER_SOURCE epatch_user_death_notice epatch_user epatch"
		source <(awk "/^# @(FUNCTION|VARIABLE): / { p = 0 } /^_EPATCH_ECLASS/ { p = 0 } /^# @(FUNCTION|VARIABLE): (${epatch_names// /|})\$/ { p = 1 } p { print }" ${PORTDIR}/eclass/epatch.eclass)
	fi

	epatch_user

	for name in $epatch_names; do
		unset $name
	done
	for name in $estack_names; do
		unset $name
	done
}

post_src_install() {
	local dest dir file link

	# INSTALL_MASK, but also for packages
	for dir in /etc/{conf.d,init.d,portage,xinetd.d} {/usr,}/lib/systemd /usr/share/{bash-completion,locale}; do
		rm -rf "${D}/${dir}"
	done
	for file in charset.alias; do
		find "${D}" -name "$file" -exec rm -f {} +
	done

	# Move all binaries to /usr/bin
	for file in "${D%/}"/{bin,sbin,usr/sbin}/*; do
		test -e "$file" || test -L "$file" || continue
		dest=${D%/}/usr/bin/${file##*/}
		link=$(readlink "$dest")
		# If /usr/bin/foo is a symlink to *bin/foo, remove it
		if test "${link%bin/${dest##*/}}" != "$link"; then
			rm "$dest" || die
		fi
		# If /usr/bin/foo exists, remove *bin/foo; else move *bin/foo to /usr/bin/foo
		if test -f "$dest"; then
			test -L "$file" || ewarn "Removing conflicting binary ${file#${D%/}}"
			rm "$file" || die
		else
			link=$(readlink "$file")
			# If *bin/foo is a symlink with a path, check if it links to *bin/bar
			if test "${link%/*}" != "$link"; then
				dir=${link%/*}
				dir=${dir#..}
				dir=${dir#/usr}
				# If this is a symlink to *bin/bar; remove the path
				if test "$dir" = "/bin" || test "$dir" = "/sbin"; then
					rm "$file" || die
					ln -s "${link##*/}" "$dest"
					continue
				elif test "${link#..}" != "$link"; then
					# Relative symlink outside *bin might be broken...
					ewarn "Possibly broken symlink ${dest}"
				fi
			fi
			# *bin/foo is a regular file or a symlink outside *bin; move it
			mkdir -p "${D%/}/usr/bin" || die
			rm -f "$dest"
			mv "$file" "$dest" || die
		fi
	done
	rmdir -p "${D%/}"/{bin,sbin,usr/sbin} 2>/dev/null
}
