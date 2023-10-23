#!/usr/bin/env bash

set -e

pr() { echo -e "\033[0;32m[+] ${1}\033[0m"; }
ask() {
	local y
	for ((n = 0; n < 3; n++)); do
		pr "$1"
		if read -r y; then
			if [ "$y" = y ]; then
				return 0
			elif [ "$y" = n ]; then
				return 1
			fi
		fi
		pr "Preguntando de nuevo..."
	done
	return 1
}

if [ ! -f ~/.rvmm_"$(date '+%Y%m')" ]; then
	pr "Preparando entorno..."
	yes "" | pkg update -y && pkg install -y openssl git wget jq openjdk-17 zip
	: >~/.rvmm_"$(date '+%Y%m')"
fi

if [ -f build.sh ]; then cd ..; fi
if [ -d revanced-magisk-module ]; then
	pr "Revisando actualizaciones de revanced-magisk-module"
	git -C revanced-magisk-module fetch
	if git -C revanced-magisk-module status | grep -q 'is behind'; then
		pr "revanced-magisk-module already is not synced with upstream."
		pr "Clonando revanced-magisk-module. config.toml se va a preservar."
		cp -f revanced-magisk-module/config.toml .
		rm -rf revanced-magisk-module
		git clone https://github.com/j-hc/revanced-magisk-module --recurse --depth 1
		mv -f config.toml revanced-magisk-module/config.toml
	fi
else
	pr "Clonando revanced-magisk-module."
	git clone https://github.com/j-hc/revanced-magisk-module --recurse --depth 1
	sed -i '/^enabled.*/d; /^\[.*\]/a enabled = false' revanced-magisk-module/config.toml
fi
cd revanced-magisk-module
chmod +x build.sh build-termux.sh

if ask "Querés abrir config.toml para personalizar? [y/n]"; then
	nano config.toml
fi
if ! ask "Preparación terminada. Empezar? [y/n]"; then
	exit 0
fi
./build.sh

cd build
pr "Pidiendo permiso de almacenamiento"
until
	yes | termux-setup-storage >/dev/null 2>&1
	ls /sdcard >/dev/null 2>&1
do
	sleep 1
done

PWD=$(pwd)
mkdir -p ~/storage/downloads/revanced-magisk-module
for op in *; do
	[ "$op" = "*" ] && continue
	mv -f "${PWD}/${op}" ~/storage/downloads/revanced-magisk-module/"${op}"
done

pr "Los archivos finales se encuentran en /sdcard/Download/revanced-magisk-module "
am start -a android.intent.action.VIEW -d file:///sdcard/Download/revanced-magisk-module -t resource/folder
sleep 2
am start -a android.intent.action.VIEW -d file:///sdcard/Download/revanced-magisk-module -t resource/folder
