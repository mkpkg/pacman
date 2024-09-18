#!/bin/bash
export WINEPREFIX="$HOME/.cemu/wine"
export WINEDLLOVERRIDES="mscoree=;mshtml=;cemuhook.dll=n,b"

# Allows to play BotW with Polaris video cards
export R600_DEBUG="nohyperz"
export AMD_DEBUG="nohyperz"

if [ ! -d "$HOME"/.cemu ] ; then
  mkdir -p "$HOME"/.cemu/wine || exit 1
  ln -s /usr/share/cemu-wine/Cemu.exe "$HOME"/.cemu/Cemu.exe || exit 1
  ln -s /usr/share/cemu-wine/cemuhook.dll "$HOME"/.cemu/cemuhook.dll || exit 1
  ln -s /usr/share/cemu-wine/keystone.dll "$HOME"/.cemu/keystone.dll || exit 1
  ln -s /usr/share/cemu-wine/sharedFonts "$HOME"/.cemu/sharedFonts || exit 1
  cp -r /usr/share/cemu-wine/gameProfiles "$HOME"/.cemu/ || exit 1
  cp -r /usr/share/cemu-wine/mlc01 "$HOME"/.cemu/ || exit 1
  cp -r /usr/share/cemu-wine/shaderCache "$HOME"/.cemu/ || exit 1
fi

if [ -d "$HOME"/.cemu ] && [ -L "$HOME"/.cemu/Cemu.exe ] && [ $(readlink "$HOME"/.cemu/Cemu.exe) == "/usr/share/cemu/Cemu.exe" ]; then
  rm "$HOME"/.cemu/Cemu.exe
  rm "$HOME"/.cemu/cemuhook.dll
  rm "$HOME"/.cemu/keystone.dll
  rm "$HOME"/.cemu/sharedFonts
  ln -s /usr/share/cemu-wine/Cemu.exe "$HOME"/.cemu/Cemu.exe || exit 1
  ln -s /usr/share/cemu-wine/cemuhook.dll "$HOME"/.cemu/cemuhook.dll || exit 1
  ln -s /usr/share/cemu-wine/keystone.dll "$HOME"/.cemu/keystone.dll || exit 1
  ln -s /usr/share/cemu-wine/sharedFonts "$HOME"/.cemu/sharedFonts || exit 1
fi
if [ -d "$HOME"/.cemu ] && [ -L "$HOME"/.cemu/dbghelp.dll ] ; then
  rm "$HOME"/.cemu/dbghelp.dll
fi

if [ -d "$HOME"/.cemu ] && [ ! -L "$HOME"/.cemu/cemuhook.dll ] ; then
  ln -s /usr/share/cemu-wine/keystone.dll "$HOME"/.cemu/keystone.dll || exit 1
  ln -s /usr/share/cemu-wine/cemuhook.dll "$HOME"/.cemu/cemuhook.dll || exit 1
fi

if [ ! -L "$HOME"/.cemu/sharedFonts ] && [ ! -d "$HOME"/.cemu/sharedFonts ] ; then
  ln -s /usr/share/cemu-wine/sharedFonts "$HOME"/.cemu/sharedFonts || exit 1
fi
if [ -L "$HOME"/.cemu/gameProfiles ] ; then
  rm "$HOME"/.cemu/gameProfiles
  cp -r /usr/share/cemu-wine/gameProfiles "$HOME"/.cemu/ || exit 1
fi

if [ ! -f "$HOME"/.cemu/wine/drive_c/windows/syswow64/vcruntime140.dll ]; then
  if [ -n "`whereis zenity|grep bin`" ]; then
    winetricks arch=32 -q vcrun2017 | zenity --title 'Cemu' --text 'Installing wine dependencies.\n\nThe process may take a few minutes' --progress --pulsate --no-cancel --auto-close
  else
    winetricks arch=32 -q vcrun2017
  fi
  winetricks settings win7
fi
cd ~/.cemu
wine Cemu.exe "$@"
