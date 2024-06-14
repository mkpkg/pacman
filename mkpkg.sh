#!/usr/bin/env bash
###
 # @Author: Cloudflying
 # @Date: 2022-06-23 13:19:21
 # @LastEditTime: 2023-04-11 19:26:40
 # @LastEditors: Cloudflying
 # @Description:mkpkg aur
###

ROOT_DIR=$(realpath $(dirname $0))
BUILD_USER='builder'
BUILD_DIR="/tmp/build"
mkdir -p ${BUILD_DIR}

# Define AUR makepkg.conf

DLAGENTS=('file::/usr/bin/curl -qgC - -o %o %u'
          'ftp::/usr/bin/curl -qgfC - --ftp-pasv --retry 3 --retry-delay 3 -o %o %u'
          'http::/usr/bin/axel -n 16 -c -k -a -U Mozilla/5.0 -o %o %u'
          'https::/usr/bin/axel -n 16 -c -k -a -U Mozilla/5.0 -o %o %u'
          'rsync::/usr/bin/rsync --no-motd -z %u %o'
          'scp::/usr/bin/scp -C %u %o')
export MAKEFLAGS="-j $(nproc)"
export PACKAGER="Cloud Flying <oss@live.hk>"

[ -z "$(id -u builders 2>&1 > /dev/null | grep user)" ] && useradd -s /bin/nologin ${BUILD_USER}

build_aur()
{
    cd ${ROOT_DIR}/build
    for pkg in $(cat $ROOT_DIR/packages.txt)
    do
        REPO="https://aur.archlinux.org/${pkg}.git"
        [ ! -d "$pkg" ] && git clone --depth=1 ${REPO}
        cd ${pkg}
        sudo -Hu ${BUILD_USER} makepkg
        exit
    done
}

# 从 本地查找是否存在自维护包 否则从 aur clone 仓库直接构建
_build_aur()
{
	build_dir="/tmp/build"
	mkdir -p ${build_dir}
	name=$2

	[ -z ${name} ] && echo "Type aur name please" && exit 1
	if [ -f "${ROOT_DIR}/PKGBUILD/pacman/${name}/PKGBUILD" ];then
		if [[ ! -d ${build_dir}/${name} ]]; then
			cp -fr ${ROOT_DIR}/PKGBUILD/pacman/${name} ${build_dir}/
		fi
	else
		if [[ ! -d ${build_dir}/${name} ]]; then
			git clone --depth=1 "https://aur.archlinux.org/${name}.git" ${build_dir}/${name}
		fi
	fi

	cd ${build_dir}/${name}

	# _makepkg_options="-sf --skipchecksums --rmdeps --noconfirm"
	_makepkg_options="-sf --noconfirm --rmdeps"
	# if [[ -f "${ROOT_DIR}/conf/makepkg.conf" ]]; then
		# makepkg --config ${ROOT_DIR}/conf/makepkg.conf ${_makepkg_options}
	# else
		# makepkg ${_makepkg_options}
	# fi
	makepkg ${_makepkg_options}

	[ -f ${build_dir}/${name}/PKGBUILD ] && . ${build_dir}/${name}/PKGBUILD

	if [[ -z "$(ls ${build_dir}/${name}/*.zst)" ]]; then
		echo "Build Fail"
	else
		cp -fr ${build_dir}/${name}/*.zst ${ROOT_DIR}/repo/pacman/ > /dev/null 2>&1
		echo " ==> Move Package to repo path"
		cd ${ROOT_DIR}
		rm -fr ${build_dir}/${name}
	fi
}

#
build()
{
    pkg=$1
    if [[ -f "${ROOT_DIR}/PKGBUILD/${pkg}/PKGBUILD" ]]; then
        cp -fr ${ROOT_DIR}/PKGBUILD/${pkg} ${BUILD_DIR}/${pkg}
    fi

    cd "${BUILD_DIR}/${pkg}" || exit 1
    makepkg --force --syncdeps --rmdeps
    cp -fr ${BUILD_DIR}/${pkg}/*.tar.zst ${ROOT_DIR}/repo
}

_gen_repo()
{
	cd ${ROOT_DIR}/repo/pacman
	# repo-add --new --remove --quiet boxs.db.tar.gz *.tar.zst
	repo-add --new --remove boxs.db.tar.gz *.tar.zst
}

_usage()
{
    echo "mkpkg.sh build pkgname"
}

case "$1" in
	build)
		# _build_aur $@
        build $2
		;;
	gendb)
		_gen_repo
	;;
	*)
        _usage
	;;
esac
