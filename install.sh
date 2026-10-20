#!/bin/bash  -eu

PACKAGENAME="fortune"
PACKAGEURL="https://api.github.com/repos/jvzantvoort/${PACKAGENAME}/releases/latest"
G_SERVER="false"
G_DEST="${HOME}/bin"

readonly PACKAGENAME
readonly PACKAGEURL

help_usage() {
  printf "%s [-h] [-s] [-d <inputfile>]\n\n" "$0"
  printf " -h             print help\n"
  printf " -s             install server\n"
  printf " -d <destdir>   specify installation directory\n"

  exit 0
}

die() {
  printf "FATAL: %s\n", "$1"
  exit 1
}

function get_goos() { uname -s | tr "[:upper:]" "[:lower:]"; }

function get_goarch() {
  case "$(uname -m)" in
  i386 | i686) echo "386" ;;
  x86_64 | amd64) echo "amd64" ;;
  armv6l | armv7l) echo "arm" ;;
  aarch64 | arm64) echo "arm64" ;;
  *) die "unsupported machine type $(uname -m)" ;;
  esac
}

mkstaging_area() {
  STAGING_AREA="$(mktemp -d /tmp/install.sh.XXXXXX)"
  return "$?"
}

rmstaging_area() {
  [[ -n "${STAGING_AREA}" ]] || return 1
  [[ -e "${STAGING_AREA}" ]] || return 2
  rm -rf "${STAGING_AREA}"

}

download_url() {
  local goos
  local goarch
  local extension

  goos="$(get_goos)"
  goarch="$(get_goarch)"
  extension=".${goos}.${goarch}.tar.gz"

  curl -fsSL "$PACKAGEURL" | jq -r .assets[].browser_download_url |
    grep "${extension}$" | head -n 1

}

#------------------------------------------------------------------------------#
#                                    Main                                      #
#------------------------------------------------------------------------------#

while getopts "vsd:h" argname; do
  case "$argname" in
  d) G_DEST="$OPTARG" ;;
  s) G_SERVER="true" ;;
  \?)
    echo "Invalid option -$OPTARG"
    help_usage
    ;;
  h | *) help_usage ;;
  esac
done
shift $((OPTIND - 1))

DOWNLOAD_URL="$(download_url)"
FILENAME="$(basename "${DOWNLOAD_URL}")"

[[ -n "${DOWNLOAD_URL}" ]] || die "download url is empty"

trap rmstaging_area EXIT INT TERM
mkstaging_area

pushd "${STAGING_AREA}" >/dev/null 2>&1 ||
  die "cannot changedir to \"${STAGING_AREA}\""

curl -fsSLo "${FILENAME}" "${DOWNLOAD_URL}" ||
  die "download ${DOWNLOAD_URL} failed"

tar -xf "${FILENAME}" -C "${G_DEST}" fortune ||
  die "extraction of fortune from ${FILENAME} failed"

if [[ "${G_SERVER}" == "true" ]]; then
  tar -xf "${FILENAME}" -C "${G_DEST}" fortune-server ||
    die "extraction of fortune-server from ${FILENAME} failed"
fi

popd >/dev/null 2>&1 || die "cannot changedir to \"${STAGING_AREA}\""

#------------------------------------------------------------------------------#
#                                  The End                                     #
#------------------------------------------------------------------------------#
