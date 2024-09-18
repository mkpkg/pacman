#!/usr/bin/env bash
###
 # @Author: Cloudflying
 # @Date: 2022-09-21 09:03:57
 # @LastEditTime: 2022-09-21 16:17:56
 # @LastEditors: Cloudflying
 # @Description: Electron Launcher
 # @FilePath: electron15.sh
### 

set -euo pipefail

name=electron-beta
flags_file="${XDG_CONFIG_HOME:-$HOME/.config}/${name}-flags.conf"

declare -a flags

if [[ -f "${flags_file}" ]]; then
    mapfile -t < "${flags_file}"
fi

for line in "${MAPFILE[@]}"; do
    if [[ ! "${line}" =~ ^[[:space:]]*#.* ]]; then
        flags+=("${line}")
    fi
done

exec /usr/lib/${name}/electron "$@" "${flags[@]}"
