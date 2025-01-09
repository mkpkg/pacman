#!/usr/bin/env bash

stoped=false

if [[ "${stoped}" == false ]]; then
  . PKGBUILD
  version=$(curl -s https://api.github.com/repos/JetBrains/qodana-cli/releases/latest | jq -r .tag_name | sed "s#v##g")

  if [[ "${version}" != "${pkgver}" ]]; then
    echo "have update"
  else
    echo "no change"
  fi
fi