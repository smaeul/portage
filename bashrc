# Runs after source is unpacked, but before autoconf
# See https://wiki.gentoo.org/wiki//etc/portage/patches
pre_src_prepare() {
  [[ ${EAPI:-0} == [012345] ]] || return
  if ! type epatch_user > /dev/null 2>&1; then
    local names="EPATCH_USER_SOURCE epatch_user epatch evar_push evar_push_set evar_pop estack_push estack_pop"
    source <(awk "/^# @(FUNCTION|VARIABLE): / { p = 0 } /^# @(FUNCTION|VARIABLE): (${names// /|})\$/ { p = 1 } p { print }" ${PORTDIR}/eclass/eutils.eclass)
  fi

  epatch_user

  for name in $names; do
    unset $name
  done
}
