#!/usr/bin/env bash
###
# @Author: Cloudflying
# @Date: 2022-06-23 13:19:21
# @LastEditTime: 2024-09-18 15:03:09
# @LastEditors: Cloudflying
# @Description: 构建 AUR 包
###

ROOT_DIR=$(realpath $(dirname $0))
PKGBUILD_PATH="${ROOT_DIR}/PKGBUILD"
BUILD_USER='builder'
BUILD_DIR="/tmp/build"
mkdir -p ${BUILD_DIR}
REPO_PATH=${ROOT_DIR}/repo
mkdir -p ${REPO_PATH}

# Define AUR makepkg.conf
DLAGENTS=('file::/usr/bin/curl -qgC - -o %o %u'
  'ftp::/usr/bin/curl -qgfC - --ftp-pasv --retry 3 --retry-delay 3 -o %o %u'
  'http::/usr/bin/axel -n 16 -c -k -a -U Mozilla/5.0 -o %o %u'
  'https::/usr/bin/axel -n 16 -c -k -a -U Mozilla/5.0 -o %o %u'
  'rsync::/usr/bin/rsync --no-motd -z %u %o'
  'scp::/usr/bin/scp -C %u %o')
export MAKEFLAGS="-j $(nproc)"
export PACKAGER="Cloud Flying <oss@live.hk>"

[ -z "$(id -u builders 2>&1 >/dev/null | grep user)" ] && useradd -s /bin/nologin ${BUILD_USER}

# 构建指定包 优先从本地查找 否则从 aur clone 仓库直接构建
_build()
{
  _makepkg_options="--syncdeps  --noconfirm --rmdeps --force --cleanbuild --clean"
  cd "${BUILD_DIR}" || exit 1
  name=$1
  [ -z ${name} ] && echo "Type aur name please" && exit 1
  if [[ -f "${PKGBUILD_PATH}/${name}/PKGBUILD" ]]; then
    echo "==> Fetch ${name} from Local"
    cp -fr "${PKGBUILD_PATH}/${name}" "${BUILD_DIR}/"
  else
    echo "==> Fetch ${name} from aur"
    fetch_aur "${name}"
  fi
  cd "${BUILD_DIR}/${name}" || exit 1

  [ -f "${BUILD_DIR}/${name}/PKGBUILD" ] && . "${BUILD_DIR}/${name}/PKGBUILD"

  if [[ -f "${ROOT_DIR}/makepkg.conf" ]]; then
    makepkg --config ${ROOT_DIR}/makepkg.conf ${_makepkg_options}
  else
    makepkg ${_makepkg_options}
  fi

  if [[ -z "$(ls ${BUILD_DIR}/${name}/*.zst)" ]]; then
    echo "Build Fail"
  else
    cp -fr ${BUILD_DIR}/${name}/*.zst ${REPO_PATH}
    echo " ==> Move Package to repo path"
    cd ${ROOT_DIR} || exit 1
    # rm -fr "${BUILD_DIR}/${name}"
  fi
}

build_aur_all()
{
  cd ${ROOT_DIR}/build
  for pkg in $(cat $ROOT_DIR/packages.txt); do
    REPO="https://aur.archlinux.org/${pkg}.git"
    [ ! -d "$pkg" ] && git clone --depth=1 ${REPO}
    cd ${pkg}
    sudo -Hu ${BUILD_USER} makepkg
    exit
  done
}

# 获取 AUR 包仓库
fetch_aur()
{
  if [[ ! -d ${BUILD_DIR}/${name} ]]; then
    git clone --depth=1 "https://aur.archlinux.org/${name}.git" ${BUILD_DIR}/${name}
  fi
}

# 生成 repo 数据库
_gen_repo()
{
  cd "${ROOT_DIR}/repo/pacman" || exit 1
  repo-add --new --remove boxs.db.tar.gz "*.tar.zst"
}

_usage()
{
  echo "mkpkg.sh build pkgname"
}

case "$1" in
  build)
    _build $2
    ;;
  gendb)
    _gen_repo
    ;;
  *)
    _usage
    ;;
esac
