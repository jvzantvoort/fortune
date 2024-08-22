#!/bin/bash
#===============================================================================
#
#         FILE:  build.sh
#
#        USAGE:  build.sh
#
#  DESCRIPTION:  Wrap the go build commands
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  jvzantvoort (John van Zantvoort), john@vanzantvoort.org
#      COMPANY:  JDC
#      CREATED:  2024-07-12
#
# Copyright (C) 2024 John van Zantvoort
#
#===============================================================================
C_BUILDLIST=$(cat <<-END
linux  amd64
linux  386
linux  arm64
linux  arm
darwin amd64
windows amd64
END
)

C_HELPMSG=$(cat <<-HELP

Development:
    fmt
    tags

Build:
    build
    update
    install
    package
    cleanup
    check
    list

HELP
)

# constants {{{
C_SCRIPTPATH="$(readlink -f "$0")"
C_SCRIPTDIR="$(dirname "$C_SCRIPTPATH")"
C_BUILDDIR="${C_SCRIPTDIR}/build"
C_TAGSPATH="${C_SCRIPTDIR}/tags"
C_PACKAGESPATH="${C_SCRIPTDIR}/pkg"

C_VERSION="$(git describe --tags --abbrev=0 2>/dev/null)"
C_REVISION=$(git rev-parse --short HEAD)
C_URL="$(git config --get remote.origin.url)"
C_REPONAME="$(basename "${C_URL}" .git)"


C_MSG_FORMAT="%-60s [ %-7s ]\n"
#shellcheck disable=SC2059
C_MSG_LEN="$(printf "${C_MSG_FORMAT}" "x" "x")"
C_MSG_LEN="${#C_MSG_LEN}"
C_MSG_LEN="$((C_MSG_LEN-12))"

readonly C_SCRIPTPATH
readonly C_SCRIPTDIR
readonly C_BUILDDIR


LDFLAGS=""
[[ -n "${C_VERSION}"  ]] && LDFLAGS="${LDFLAGS} -X main.version=${C_VERSION}"
[[ -n "${C_REVISION}" ]] && LDFLAGS="${LDFLAGS} -X main.revision=${C_REVISION}"
LDFLAGS="${LDFLAGS} -w -s"

# }}}

# messages {{{
#shellcheck disable=SC2034
function strrep()
{
  local num="$1"
  local re

  re='^[0-9]+$'

  if [[ $num =~ $re ]]
  then
    seq 1 "${num}" | while read -r x
    do
      printf "-"
    done
  fi
}

function getpad()
{
  local msg="$1"
  pad="${#msg}" # length of the string
  pad="$((C_MSG_LEN-pad))" # subtract it from then screen width
  strrep "${pad}"
}

function print_msg()
{
  local state=$1; shift
  local msg="$*"
  local pad

  padstr="$(getpad "${msg}")"

  msg="${msg} $(strrep "${padstr}")" # create padding

  #shellcheck disable=SC2059
  printf "${C_MSG_FORMAT}" "$msg ${padstr}" "${state}"
}
function print_title()
{
  local msg
  msg="$(echo "$@"|tr "[:lower:]" "[:upper:]")"
  print_msg "       " "$msg"
}
function print_subtitle()
{
  local msg
  msg="$(echo "$@"|sed 's/.*/\L&/; s/[a-z]*/\u&/g')"
  print_msg "-------" "$msg"
}
function print_ok()      { print_msg "SUCCESS" "$@"; }
function print_nok()     { print_msg "FAILURE" "$@"; }
function print_fatal()   { print_msg "FATAL"   "$@"; }
function print_warning() { print_msg "WARNING" "$@"; }
function print_unknown() { print_msg "UNKNOWN" "$@"; }
function print_skipped() { print_msg "SKIPPED" "$@"; }

function test_result()
{
  local retv=$1
  local message=$2
  if [[ "${retv}" == "0" ]]
  then
    print_ok "${message}"
  elif [[ "${retv}" == "127" ]]
  then
    print_nok "${message} (not found)"
  else
    print_nok "${message}"
  fi
}

function test_fatal()
{
  local retv=$1
  local message=$2
  if [[ "${retv}" == "0" ]]
  then
    print_ok "${message}"
  else
    print_fatal "${message}"
    exit 1
  fi
}

function die() { test_fatal 1 "FATAL: $1"; }

# }}}

# listings {{{
function list_gofiles()
{
  pushd "${C_SCRIPTDIR}" >/dev/null 2>&1 || die "cannot changedir to scriptdir"
  find "." -type f -name '*.go' -not -path '*/vendor/*'
  popd >/dev/null 2>&1 || die "cannot changedir back"
}

function list_binaries()
{
  pushd "${C_SCRIPTDIR}" >/dev/null 2>&1 || die "cannot changedir to scriptdir"
  find cmd -maxdepth 1 -mindepth 1 -type d -printf "%f\n"
  popd >/dev/null 2>&1 || die "cannot changedir back"
}

# }}}

function __calcdest()
{
  local goos="$1"
  local arch="$2"
  local target="$3"
  printf "%s/%s/%s/%s\n" "${C_BUILDDIR}" "${goos}" "${arch}" "${target}"
}

# actions {{{

function action_fmt()
{
  list_gofiles | while read -r target
  do
    goimports -w "${target}"
    test_result "$?" "reformat ${target}"
  done
  echo
  echo "Changed:"
  echo
  git status -s | awk '$1 ~ /M/ && /\.go/ { printf " - %s\n", $2 }'
  echo
}

function action_tags()
{
  list_gofiles | xargs gotags > "${C_TAGSPATH}"
  test_result "$?" "Generate c-tags"
}

function action_build()
{
  local goos="$1"
  local arch="$2"
  local dest
  local exitcode

  exitcode=0

  while read -r target
  do
    dest="$(__calcdest "${goos}" "${arch}" "${target}")"

    CGO_ENABLED=0 \
    GOOS=${goos} GOARCH=${arch} \
      go  build -ldflags "${LDFLAGS}" \
      -o "${dest}" "./cmd/${target}"
    retv="$?"
    test_result "$retv" "    ${target}"
    [[ "${retv}" == "0" ]] || exitcode=$((exitcode+1))
  done < <(list_binaries)
  test_fatal "${exitcode}" "build results"
}

function action_dependencies()
{
  local msg

  pushd "${C_SCRIPTDIR}" >/dev/null 2>&1 || die "cannot changedir to scriptdir"
  msg="go mod init"
  if [[ -e "go.mod" ]]
  then
    print_skipped "${msg}"
  else
    go mod init
    test_result "$?" "${msg}"
  fi
  msg="go mod tidy"
  go mod tidy
  test_result "$?" "${msg}"

  msg="go mod vendor"
  go mod vendor
  test_result "$?" "${msg}"

  msg="go get packages"
  go get -v -t -d ./...
  test_result "$?" "${msg}"

  popd >/dev/null 2>&1 || die "cannot changedir back"
}

function action_install()
{
  local goos="$1"
  local arch="$2"
  local bindir
  bindir="$(go env GOBIN)"

  while read -r target
  do
    local dest
    dest="$(__calcdest "${goos}" "${arch}" "${target}")"
    install -m 755 "${dest}" "${bindir}/${target}"
    test_result "$?" "    ${target}"
  done < <(list_binaries)
}

function action_package()
{
  local goos="$1"
  local arch="$2"
  local dest
  local destdir
  local destv
  local destf

  mkdir -p "${C_PACKAGESPATH}"

  # define a version
  destv="${C_VERSION}"
  [[ -n "${destv}" ]] || destv="${C_REVISION}"
  [[ -n "${destv}" ]] || destv="$(date +%y%m%d%H%M)"

  # define a filename
  destf="${C_REPONAME}-${goos}-${arch}-${destv}.zip"

  destdir="$(dirname "$(__calcdest "${goos}" "${arch}" "none")")"

  pushd "${destdir}" >/dev/null 2>&1 || die "cannot changedir to destdir"
  list_binaries | zip -@ "${C_PACKAGESPATH}/${destf}" >/dev/null 2>&1
  test_result "$?" "  create ${destf} archive"
  popd >/dev/null 2>&1 || die "cannot changedir back"

}

function action_createpackages()
{
  action_dependencies
  while read -r goos arch
  do
    print_subtitle "create ${goos}/${arch} archive"
    action_build   "${goos}" "${arch}"
    action_package "${goos}" "${arch}"
  done  < <(echo "${C_BUILDLIST}")
}

function action_cleanup()
{

  [[ -d "${C_BUILDDIR}" ]] && rm -rvf "${C_BUILDDIR}"
  [[ -e "${C_PACKAGESPATH}" ]] && rm -vrf "${C_PACKAGESPATH}"
  [[ -d "${C_TAGSPATH}" ]] && rm -vf "${C_TAGSPATH}"


}

function action_check()
{
  pushd "${C_SCRIPTDIR}" >/dev/null 2>&1 || die "cannot changedir to scriptdir"

  go vet ./...
  test_result "$?" "go vet"

  local goroot
  goroot="$(go env GOROOT)"

  golangci-lint run --exclude-dirs "${goroot}" ./...
  test_result "$?" "golangci-lint"

  staticcheck ./...
  test_result "$?" "staticcheck"

  # go install golang.org/x/tools/cmd/deadcode@latest
  deadcode ./...
  test_result "$?" "deadcode"

  popd >/dev/null 2>&1 || die "cannot changedir back"

}

function action_list()
{
  pushd "${C_SCRIPTDIR}" >/dev/null 2>&1 || die "cannot changedir to scriptdir"

  find "${C_SCRIPTDIR}" -mindepth 1 -maxdepth 1 -type d \
    -not -name '.git*' -not -name build -not -name vendor \
    -printf "%f\n" | sort | while read -r target
    do
      find "${target}" -type f
    done
  find "${C_SCRIPTDIR}" -mindepth 1 -maxdepth 1 -type f \
    -name '*.go'
  popd >/dev/null 2>&1 || die "cannot changedir back"

}

# }}}

# interfaces {{{
function do_fmt() { print_title "format the sources"; action_fmt; }
function do_tags() { print_title "generate tags"; action_tags; }
function do_cleanup() { print_title "cleanup"; action_cleanup; }
function do_dependencies() { print_title "update dependencies"; action_dependencies; }
function do_build()
{
  print_title "build ${goos}/${arch}"
  action_dependencies
  action_build "$(go env GOOS)" "$(go env GOARCH)"
}
function do_install() {
  print_title "install locally"
  action_install "$(go env GOOS)" "$(go env GOARCH)"
}
function do_package() { print_title "create packages"; action_createpackages; }
function do_usage()
{
  printf "USAGE:\n\n  %s <option>\n\n" "${C_SCRIPTPATH}"
  echo "${C_HELPMSG}"
  printf "\n\n"
  exit 0
}
function do_check() { print_title "check the sources"; action_check; }
function do_list() { action_list; }
# }}}

#------------------------------------------------------------------------------#
#                                    Main                                      #
#------------------------------------------------------------------------------#

case "$1" in
  fmt)     do_fmt          ;;
  tags)    do_tags         ;;
  build)   do_build        ;;
  update)  do_dependencies ;;
  install) do_install      ;;
  package) do_package      ;;
  cleanup) do_cleanup      ;;
  check)   do_check        ;;
  list)    do_list         ;;
  help)    do_usage        ;;
  *)       do_usage        ;;
esac

#------------------------------------------------------------------------------#
#                                  The End                                     #
#------------------------------------------------------------------------------#
# vim: foldmethod=marker
