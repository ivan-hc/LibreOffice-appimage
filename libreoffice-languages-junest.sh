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

DEPENDENCES=$(echo "$DEPENDENCES" | sed -- "s/libreoffice-/libreoffice-$LOREL-/g")
#BASICSTUFF="binutils debugedit gzip"
#COMPILERS="base-devel"

#############################################################################
#	SETUP THE ENVIRONMENT
#############################################################################

# Download appimagetool
if [ ! -f ./appimagetool ]; then
	echo "-----------------------------------------------------------------------------"
	echo "◆ Downloading \"appimagetool\" from https://github.com/AppImage/appimagetool"
	echo "-----------------------------------------------------------------------------"
	curl -#Lo appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage && chmod a+x appimagetool
fi

# Create and enter the AppDir
mkdir -p "$APP".AppDir archlinux && cd archlinux || exit 1

# Set archlinux as a temporary $HOME directory
HOME="$(dirname "$(readlink -f "$0")")"

#############################################################################
#	DOWNLOAD, INSTALL AND CONFIGURE JUNEST
#############################################################################

_enable_multilib() {
	printf "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> ./.junest/etc/pacman.conf
}

_enable_chaoticaur() {
	# This function is ment to be used during the installation of JuNest, see "_pacman_patches"
	./.local/share/junest/bin/junest -- sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
	./.local/share/junest/bin/junest -- sudo pacman-key --lsign-key 3056513887B78AEB
	./.local/share/junest/bin/junest -- sudo pacman-key --populate chaotic
	./.local/share/junest/bin/junest -- sudo pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
	printf "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >> ./.junest/etc/pacman.conf
}

_enable_archlinuxcn() {
	./.local/share/junest/bin/junest -- sudo pacman --noconfirm -U "https://repo.archlinuxcn.org/x86_64/$(curl -Ls https://repo.archlinuxcn.org/x86_64/ | tr '"' '\n' | grep "^archlinuxcn-keyring.*zst$" | tail -1)"
	printf "\n[archlinuxcn]\n#SigLevel = Never\nServer = http://repo.archlinuxcn.org/\$arch" >> ./.junest/etc/pacman.conf
}

_custom_mirrorlist() {
	COUNTRY=$(curl -i ipinfo.io 2>/dev/null | grep country | cut -c 15- | cut -c -2)
	if [ -n "$GITHUB_REPOSITORY_OWNER" ] || ! curl --output /dev/null --silent --head --fail "https://archlinux.org/mirrorlist/?country=$COUNTRY" 1>/dev/null; then
		curl -Ls https://archlinux.org/mirrorlist/all | awk NR==2 RS= | sed 's/#Server/Server/g' > ./.junest/etc/pacman.d/mirrorlist
	else
		curl -Ls "https://archlinux.org/mirrorlist/?country=$COUNTRY" | sed 's/#Server/Server/g' > ./.junest/etc/pacman.d/mirrorlist
	fi
}

_bypass_signature_check_level() {
	sed -i 's/#SigLevel/SigLevel/g; s/Required DatabaseOptional/Never/g' ./.junest/etc/pacman.conf
}

_install_junest() {
	echo "-----------------------------------------------------------------------------"
	echo "◆ Clone JuNest from https://github.com/fsquillace/junest"
	echo "-----------------------------------------------------------------------------"
	git clone https://github.com/fsquillace/junest.git ./.local/share/junest
	echo "-----------------------------------------------------------------------------"
	echo "◆ Downloading JuNest archive from https://github.com/ivan-hc/junest"
	echo "-----------------------------------------------------------------------------"
	curl -#Lo junest-x86_64.tar.gz https://github.com/ivan-hc/junest/releases/download/continuous/junest-x86_64.tar.gz
	./.local/share/junest/bin/junest setup -i junest-x86_64.tar.gz
	rm -f junest-x86_64.tar.gz
	echo " Apply patches to PacMan..."
	#_enable_multilib
	#_enable_chaoticaur
	#_enable_archlinuxcn
	_custom_mirrorlist
	_bypass_signature_check_level

	# Update arch linux in junest
	./.local/share/junest/bin/junest -- sudo pacman -Syy
	./.local/share/junest/bin/junest -- sudo pacman --noconfirm -Syu
}

if ! test -d "$HOME/.local/share/junest"; then
	echo "-----------------------------------------------------------------------------"
	echo " DOWNLOAD, INSTALL AND CONFIGURE JUNEST"
	echo "-----------------------------------------------------------------------------"
	_install_junest
else
	echo "-----------------------------------------------------------------------------"
	echo " RESTART JUNEST"
	echo "-----------------------------------------------------------------------------"
fi

#############################################################################
#	INSTALL PROGRAMS USING YAY
#############################################################################

./.local/share/junest/bin/junest -- yay -Syy
#./.local/share/junest/bin/junest -- gpg --keyserver keyserver.ubuntu.com --recv-key C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF # UNCOMMENT IF YOU USE THE AUR
if [ -n "$BASICSTUFF" ]; then
	./.local/share/junest/bin/junest -- yay --noconfirm -S $BASICSTUFF
fi
if [ -n "$COMPILERS" ]; then
	./.local/share/junest/bin/junest -- yay --noconfirm -S $COMPILERS
	./.local/share/junest/bin/junest -- yay --noconfirm -S python # to force one Python version and prevent modules from being installed in different directories (e.g. "mesonbuild")
fi
if [ -n "$DEPENDENCES" ]; then
	./.local/share/junest/bin/junest -- yay --noconfirm -S $DEPENDENCES
fi
if [ -n "$APP" ]; then
	./.local/share/junest/bin/junest -- yay --noconfirm -S alsa-lib gtk3 xapp
	./.local/share/junest/bin/junest -- yay --noconfirm -S "$APP"
	./.local/share/junest/bin/junest -- glib-compile-schemas /usr/share/glib-2.0/schemas/
else
	echo "No app found, exiting"; exit 1
fi

cd ..

echo ""
echo "-----------------------------------------------------------------------------"
echo " CREATING THE APPDIR"
echo "-----------------------------------------------------------------------------"
echo ""

#############################################################################
#	EXTRACT PACKAGES
#############################################################################

echo "$DEPENDENCES" > ./userdeps

_extract_main_package() {
	mkdir -p base
	rm -Rf ./base/*
	pkg_full_path=$(find ./archlinux -type f -name "$APP-*zst")
	if [ "$(echo "$pkg_full_path" | wc -l)" = 1 ]; then
		pkg_full_path=$(find ./archlinux -type f -name "$APP-*zst")
	else
		for p in $pkg_full_path; do
			if tar fx "$p" .PKGINFO -O | grep -q "pkgname = $APP$"; then
				pkg_full_path="$p"
			fi
		done
	fi
	[ -z "$pkg_full_path" ] && echo "💀 ERROR: no package found for \"$APP\", operation aborted!" && exit 0
	tar fx "$pkg_full_path" -C ./base/
	VERSION=$(cat ./base/.PKGINFO | grep pkgver | cut -c 10- | sed 's@.*:@@')
	mkdir -p deps
}

_download_missing_packages() {
	localpackage=$(find ./archlinux -name "$arg-[0-9]*zst")
	if ! test -f "$localpackage"; then
		./archlinux/.local/share/junest/bin/junest -- yay --noconfirm -Sw "$arg"
	fi
}

_extract_package() {
	_download_missing_packages &> /dev/null
	pkg_full_path=$(find ./archlinux -name "$arg-[0-9]*zst")
	pkgname=$(echo "$pkg_full_path" | sed 's:.*/::')
	[ ! -f ./packages ] && rm -Rf ./deps/* && touch ./packages
	if [ -z "$( ls -A './deps' )" ]; then
		rm -f ./packages
		echo ""
		echo "-----------------------------------------------------------------------------"
		echo " EXTRACTING PACKAGES"
		echo "-----------------------------------------------------------------------------"
		echo ""
	fi
	if test -f "$pkg_full_path"; then
		if ! grep -q "$pkgname" ./packages 2>/dev/null;then
			echo "◆ Extracting $pkgname"
			tar fx "$pkg_full_path" -C ./deps/ --warning=no-unknown-keyword
			echo "$pkgname" >> ./packages
		fi
		[ -n "$lib_browser_launcher" ] && [[ "$arg" =~ (hicolor-icon-theme|xapp) ]] && tar fx "$pkg_full_path" -C ./base/ --warning=no-unknown-keyword --exclude='.PKGINFO'
	fi
}

_determine_packages_and_libraries() {
	if echo "$arg" | grep -q "\.so"; then
		LIBSAVED="$LIBSAVED $arg"
	elif [ "$arg" != autoconf ] && [ "$arg" != autoconf ] && [ "$arg" != automake ] && [ "$arg" != bison ] && [ "$arg" != debugedit ] && [ "$arg" != dkms ] && [ "$arg" != fakeroot ] && [ "$arg" != flatpak ] && [ "$arg" != linux ] && [ "$arg" != gcc ] && [ "$arg" != make ] && [ "$arg" != pacman ] && [ "$arg" != patch ] && [ "$arg" != systemd ]; then
		_extract_package
		cat ./deps/.PKGINFO 2>/dev/null | grep "^depend = " | cut -c 10- | sed 's/=.*//' >> depdeps
		rm -f ./deps/.*
	fi
}

_extract_deps() {
	DEPS=$(sort -u ./depdeps)
	for arg in $DEPS; do
		_determine_packages_and_libraries
	done
}

_extract_all_dependences() {
	rm -f ./depdeps

	OPTDEPS=$(cat ./base/.PKGINFO 2>/dev/null | grep "^optdepend = " | sed 's/optdepend = //g' | sed 's/=.*//' | sed 's/:.*//')
	for arg in $OPTDEPS; do
		_determine_packages_and_libraries
	done
	[ -f ./depdeps ] && _extract_deps
	rm -f ./depdeps

	ARGS=$(echo "$DEPENDENCES" | tr " " "\n")
	for arg in $ARGS; do
		_determine_packages_and_libraries
	done

	DEPS=$(cat ./base/.PKGINFO 2>/dev/null | grep "^depend = " | sed 's/depend = //g' | sed 's/=.*//')
	for arg in $DEPS; do
		_determine_packages_and_libraries
	done

	# Set the level of sub-dependencies extraction, the higher the number, the bigger the AppImage will be
	if [ "$extraction_count" != 0 ]; then
		for e in $(seq "$extraction_count"); do _extract_deps; done
	fi
}

_extract_main_package
_extract_all_dependences

# Add languages (if available)
rsync -av ./archlinux/.junest/usr/lib/libreoffice/program/* ./"$APP".AppDir/.junest/usr/lib/libreoffice/program/
rsync -av ./archlinux/.junest/usr/lib/libreoffice/share/* ./"$APP".AppDir/.junest/usr/lib/libreoffice/share/

#############################################################################
#	REMOVE BLOATWARES, ENABLE MOUNTPOINTS
#############################################################################

_remove_more_bloatwares() {
	etc_remove="makepkg.conf pacman"
	for r in $etc_remove; do
		rm -Rf ./"$APP".AppDir/.junest/etc/"$r"*
	done
	bin_remove="gcc"
	for r in $bin_remove; do
		rm -Rf ./"$APP".AppDir/.junest/usr/bin/"$r"*
	done
	lib_remove="gcc"
	for r in $lib_remove; do
		rm -Rf ./"$APP".AppDir/.junest/usr/lib/"$r"*
	done
	share_remove="gcc gir i18n perl"
	for r in $share_remove; do
		rm -Rf ./"$APP".AppDir/.junest/usr/share/"$r"*
	done
	echo Y | rm -Rf ./"$APP".AppDir/.cache/yay/*
	find ./"$APP".AppDir/.junest/usr/share/doc/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null #REMOVE ALL DOCUMENTATION NOT RELATED TO THE APP
	find ./"$APP".AppDir/.junest/usr/share/locale/*/*/* -not -iname "*$BIN*" -a -not -name "." -delete 2> /dev/null #REMOVE ALL ADDITIONAL LOCALE FILES
	rm -Rf ./"$APP".AppDir/.junest/home # remove the inbuilt home
	rm -Rf ./"$APP".AppDir/.junest/usr/include # files related to the compiler
	rm -Rf ./"$APP".AppDir/.junest/usr/share/man # AppImages are not ment to have man command
	rm -Rf ./"$APP".AppDir/.junest/usr/lib/python*/__pycache__/* # if python is installed, removing this directory can save several megabytes
	rm -Rf ./"$APP".AppDir/.junest/usr/lib/libgallium*
	rm -Rf ./"$APP".AppDir/.junest/usr/lib/libgo.so*
	rm -Rf ./"$APP".AppDir/.junest/usr/lib/libLLVM* # included in the compilation phase, can sometimes be excluded for daily use
	rm -Rf ./"$APP".AppDir/.junest/var/* # remove all packages downloaded with the package manager
}

_enable_mountpoints_for_the_inbuilt_bubblewrap() {
	mkdir -p ./"$APP".AppDir/.junest/home
	mkdir -p ./"$APP".AppDir/.junest/media
	mkdir -p ./"$APP".AppDir/.junest/usr/lib/locale
	mkdir -p ./"$APP".AppDir/.junest/usr/share/fonts
	mkdir -p ./"$APP".AppDir/.junest/usr/share/themes
	mkdir -p ./"$APP".AppDir/.junest/run/media
	mkdir -p ./"$APP".AppDir/.junest/run/user
	rm -f ./"$APP".AppDir/.junest/etc/localtime && touch ./"$APP".AppDir/.junest/etc/localtime
	[ ! -f ./"$APP".AppDir/.junest/etc/asound.conf ] && touch ./"$APP".AppDir/.junest/etc/asound.conf
}

# Fix libcurl
if test -f ./"$APP".AppDir/.junest/usr/lib/libcurl*; then
	rm -f ./"$APP".AppDir/.junest/usr/lib/libcurl* && cp -r ./archlinux/.junest/usr/lib/libcurl* ./"$APP".AppDir/.junest/usr/lib/
fi

_remove_more_bloatwares
find ./"$APP".AppDir/.junest/usr/lib ./"$APP".AppDir/.junest/usr/lib32 -type f -regex '.*\.a' -exec rm -f {} \; 2>/dev/null
find ./"$APP".AppDir/.junest/usr -type f -regex '.*\.so.*' -exec strip --strip-debug {} \;
find ./"$APP".AppDir/.junest/usr/bin -type f ! -regex '.*\.so.*' -exec strip --strip-unneeded {} \;
find ./"$APP".AppDir/.junest/usr -type d -empty -delete
_enable_mountpoints_for_the_inbuilt_bubblewrap

#############################################################################
#	CREATE THE APPIMAGE
#############################################################################

if test -f ./*.AppImage; then rm -Rf ./*archimage*.AppImage; fi

APPNAME=$(cat ./"$APP".AppDir/*.desktop | grep 'Name=' | head -1 | cut -c 6- | sed 's/ /-/g')
REPO="$APPNAME-appimage"
TAG="continuous-$LOREL"
VERSION="$VERSION"
UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|$REPO|$TAG|*$LOREL-$LOLP*x86_64.AppImage.zsync"

ARCH=x86_64 ./appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 \
	-u "$UPINFO" \
	./"$APP".AppDir "$APPNAME"-"$LOREL"-"$LOLP"_"$VERSION"-archimage4.3-x86_64.AppImage
