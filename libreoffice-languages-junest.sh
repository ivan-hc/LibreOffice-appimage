#!/usr/bin/env bash

if [ ! -f ./libreoffice-junest.sh ] && [ ! -d AppDir/.junest/usr/lib/libreoffice/program ] && [ ! -d archlinux/.junest/usr/lib/libreoffice/program ] && [ ! -f ./version ]; then
	exit 0
fi

# Determine if LibreOffice release "LOREL" is "still" (default) or "fresh"
[ -z "$LOREL" ] && LOREL="still"

# Determine if language pack set is "base", "standard" or "full"
[ -z "$LOLP" ] && LOLP="base"

APP=libreoffice-"$LOREL"
BIN="libreoffice" #CHANGE THIS IF THE NAME OF THE BINARY IS DIFFERENT FROM "$APP" (for example, the binary of "obs-studio" is "obs")

# Language packs
add_italian="libreoffice-it"
add_european="$add_italian libreoffice-en-gb libreoffice-fr libreoffice-de libreoffice-pt libreoffice-es"
add_standard="$add_european libreoffice-ar libreoffice-zh-cn libreoffice-zh-tw libreoffice-ja libreoffice-ko libreoffice-pt-br libreoffice-ru"
add_all="$add_standard libreoffice-af libreoffice-am libreoffice-as libreoffice-ast libreoffice-be libreoffice-bg libreoffice-bn libreoffice-bn-in libreoffice-bo libreoffice-br libreoffice-brx libreoffice-bs libreoffice-ca libreoffice-ca-valencia libreoffice-ckb libreoffice-cs libreoffice-cy libreoffice-da libreoffice-dgo libreoffice-dsb libreoffice-dz libreoffice-el libreoffice-en-za libreoffice-eo libreoffice-et libreoffice-eu libreoffice-fa libreoffice-fi libreoffice-fur libreoffice-fy libreoffice-ga libreoffice-gd libreoffice-gl libreoffice-gu libreoffice-gug libreoffice-he libreoffice-hi libreoffice-hr libreoffice-hsb libreoffice-hu libreoffice-id libreoffice-is libreoffice-ka libreoffice-kab libreoffice-kk libreoffice-km libreoffice-kmr-latn libreoffice-kn libreoffice-kok libreoffice-ks libreoffice-lb libreoffice-lo libreoffice-lt libreoffice-lv libreoffice-mai libreoffice-mk libreoffice-ml libreoffice-mn libreoffice-mni libreoffice-mr libreoffice-my libreoffice-nb libreoffice-ne libreoffice-nl libreoffice-nn libreoffice-nr libreoffice-nso libreoffice-oc libreoffice-om libreoffice-or libreoffice-pa-in libreoffice-pl libreoffice-ro libreoffice-rw libreoffice-sa-in libreoffice-sat libreoffice-sd libreoffice-si libreoffice-sid libreoffice-sk libreoffice-sl libreoffice-sq libreoffice-sr libreoffice-sr-latn libreoffice-ss libreoffice-st libreoffice-sv libreoffice-sw-tz libreoffice-szl libreoffice-ta libreoffice-te libreoffice-tg libreoffice-th libreoffice-tn libreoffice-tr libreoffice-ts libreoffice-tt libreoffice-ug libreoffice-uk libreoffice-uz libreoffice-ve libreoffice-vec libreoffice-vi libreoffice-xh libreoffice-zu"

if [ "$LOLP" = base ]; then
	LANGUAGE_PACKS=""
elif [ "$LOLP" = italian ]; then
	LANGUAGE_PACKS="$add_italian"
elif [ "$LOLP" = european ]; then
	LANGUAGE_PACKS="$add_european"
elif [ "$LOLP" = standard ]; then
	LANGUAGE_PACKS="$add_standard"
elif [ "$LOLP" = all ]; then
	LANGUAGE_PACKS="$add_all"
fi

LANGUAGE_PACKS=$(echo "$LANGUAGE_PACKS" | sed -- "s/libreoffice-/libreoffice-$LOREL-/g")

# Create and enter the AppDir
mkdir -p AppDir archlinux && cd archlinux || exit 1

_JUNEST_CMD() {
	./.local/share/junest/bin/junest "$@"
}

# Set archlinux as a temporary $HOME directory
HOME="$(dirname "$(readlink -f "$0")")"

_JUNEST_CMD -- yay --noconfirm -S $LANGUAGE_PACKS

cd ..

# Add languages (if available)
rsync -av archlinux/.junest/usr/lib/libreoffice/program/* AppDir/.junest/usr/lib/libreoffice/program/
rsync -av archlinux/.junest/usr/lib/libreoffice/share/* AppDir/.junest/usr/lib/libreoffice/share/

# Remove bloatwares and enable mountpoints
printf "\n◆ Trying to reduce size:\n\n"

find AppDir/.junest/usr -type f -regex '.*\.so.*' -exec strip --strip-debug {} \;

# CREATE THE APPIMAGE

APPNAME=$(cat AppDir/*.desktop | grep '^Name=' | head -1 | cut -c 6- | sed 's/ /-/g')
REPO="LibreOffice-appimage"
TAG="continuous-junest-$LOREL"
UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|$REPO|$TAG|*$LOREL-$LOLP*x86_64.AppImage.zsync"
VERSION=$(cat ./version)

_appimagetool() {
	if ! command -v appimagetool 1>/dev/null; then
		if [ ! -f ./appimagetool ]; then
			echo " Downloading appimagetool..." && curl -#Lo appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-"$ARCH".AppImage && chmod a+x ./appimagetool || exit 1
		fi
		./appimagetool "$@"
	else
		appimagetool "$@"
	fi
}

ARCH=x86_64 _appimagetool -u "$UPINFO" AppDir "$APPNAME"-"$LOREL"-"$LOLP"_"$VERSION"-"$ARCHIMAGE_VERSION"-x86_64.AppImage
