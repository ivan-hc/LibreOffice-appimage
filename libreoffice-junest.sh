#!/usr/bin/env bash

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
	DEPENDENCES=""
elif [ "$LOLP" = italian ]; then
	DEPENDENCES="$add_italian"
elif [ "$LOLP" = european ]; then
	DEPENDENCES="$add_european"
elif [ "$LOLP" = standard ]; then
	DEPENDENCES="$add_standard"
elif [ "$LOLP" = all ]; then
	DEPENDENCES="$add_all"
fi

#DEPENDENCES="$DEPENDENCES jre-openjdk"
DEPENDENCES=$(echo "$DEPENDENCES" | sed -- "s/libreoffice-/libreoffice-$LOREL-/g")
#BASICSTUFF="binutils debugedit gzip"
#COMPILERS="base-devel"

# Set keywords to searchan include in names of directories and files in /usr/bin (BINSAVED), /usr/share (SHARESAVED) and /usr/lib (LIBSAVED)
BINSAVED="SAVEBINSPLEASE"
SHARESAVED="applications libexttextcat liblangtag"
LIBSAVED="gdk-pixbuf"

# Set the items you want to manually REMOVE. Complete the path in /etc/, /usr/bin/, /usr/lib/, /usr/lib/python*/ and /usr/share/ respectively.
# The "rm" command will take into account the listed object/path and add an asterisk at the end, completing the path to be removed.
# Some keywords and paths are already set. Remove them if you consider them necessary for the AppImage to function properly.
ETC_REMOVED="makepkg.conf pacman"
BIN_REMOVED="gcc"
LIB_REMOVED="gcc libgallium libgo.so libLLVM"
PYTHON_REMOVED="__pycache__/"
SHARE_REMOVED="gcc icons/AdwaitaLegacy icons/Adwaita/cursors/ terminfo"

# Set mountpoints, they are ment to be set into the AppRun.
# Default mounted files are /etc/resolv.conf, /etc/hosts, /etc/nsswitch.conf, /etc/passwd, /etc/group, /etc/machine-id, /etc/asound.conf and /etc/localtime
# Default mounted directories are /media, /mnt, /opt, /run/media, /usr/lib/locale, /usr/share/fonts, /usr/share/themes, /var, and Nvidia-related directories
# Do not touch this if you are not sure.
mountpoint_files=""
mountpoint_dirs=""

# Post-installation processes (add whatever you want)
_post_installation_processes() {
	printf "\n◆ User's processes: \n\n"
	echo " - None"
	# Add here your code
}

##########################################################################################################################################################
#	SETUP THE ENVIRONMENT
##########################################################################################################################################################

# Download archimage-builder.sh
if [ ! -f ./archimage-builder.sh ]; then
	ARCHIMAGE_BUILDER="https://raw.githubusercontent.com/ivan-hc/ArchImage/refs/heads/main/core/archimage-builder.sh"
	wget --retry-connrefused --tries=30 "$ARCHIMAGE_BUILDER" -O ./archimage-builder.sh || exit 0
fi

# Create and enter the AppDir
mkdir -p AppDir archlinux && cd archlinux || exit 1

_JUNEST_CMD() {
	./.local/share/junest/bin/junest "$@"
}

# Set archlinux as a temporary $HOME directory
HOME="$(dirname "$(readlink -f "$0")")"

##########################################################################################################################################################
#	DOWNLOAD, INSTALL AND CONFIGURE JUNEST
##########################################################################################################################################################

_enable_archlinuxcn() {	ARCHLINUXCN_ON="1"; }
_enable_chaoticaur() { CHAOTICAUR_ON="1"; }
_enable_multilib() { MULTILIB_ON="1"; }

#_enable_archlinuxcn
#_enable_chaoticaur
#_enable_multilib

[ -f ../archimage-builder.sh ] && source ../archimage-builder.sh junest-setup "$@"

##########################################################################################################################################################
#	INSTALL PROGRAMS USING YAY
##########################################################################################################################################################

_JUNEST_CMD -- yay -Syy
#_JUNEST_CMD -- gpg --keyserver keyserver.ubuntu.com --recv-key C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF # UNCOMMENT IF YOU USE THE AUR

[ -f ../archimage-builder.sh ] && source ../archimage-builder.sh install "$@"

cd ..

##########################################################################################################################################################
#	APPDIR
##########################################################################################################################################################

[ -f ./archimage-builder.sh ] && source ./archimage-builder.sh appdir "$@"

##########################################################################################################################################################
#	APPRUN
##########################################################################################################################################################

rm -f AppDir/AppRun

# Set to "1" if you want to add Nvidia drivers manager in the AppRun
export NVIDIA_ON=0

[ -f ./archimage-builder.sh ] && source ./archimage-builder.sh apprun "$@"

# AppRun footer, here you can add options and change the way the AppImage interacts with its internal structure
cat <<-'HEREDOC' >> AppDir/AppRun

EXEC=$(grep -e '^Exec=.*' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2- | sed -e 's|%.||g')
if ! echo "$EXEC" | grep -q "/usr/bin"; then EXEC="/usr/bin/$EXEC"; fi

_JUNEST_CMD -- $EXEC "$@"

HEREDOC
chmod a+x AppDir/AppRun

##########################################################################################################################################################
#	COMPILE
##########################################################################################################################################################

[ -f ./archimage-builder.sh ] && source ./archimage-builder.sh compile "$@"

##########################################################################################################################################################
#	CREATE THE APPIMAGE
##########################################################################################################################################################

if test -f ./*.AppImage; then rm -Rf ./*archimage*.AppImage; fi

APPNAME=$(cat AppDir/*.desktop | grep '^Name=' | head -1 | cut -c 6- | sed 's/ /-/g')
REPO="LibreOffice-appimage"
TAG="continuous-junest-$LOREL"
UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|$REPO|$TAG|*$LOREL-$LOLP*x86_64.AppImage.zsync"

echo "$VERSION" > ./version

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

ARCH=x86_64 _appimagetool -u "$UPINFO" \
	AppDir "$APPNAME"-"$LOREL"-"$LOLP"_"$VERSION"-archimage5.0-x86_64.AppImage
