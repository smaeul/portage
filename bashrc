# Runs after source is unpacked, but before autoconf
# See https://wiki.gentoo.org/wiki//etc/portage/patches
pre_src_prepare() {
  [ "$(type -t epatch_user)" = "function" ] && epatch_user
}
