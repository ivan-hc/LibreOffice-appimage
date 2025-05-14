#!/bin/sh

# Download appimagetool
if [ ! -f ./appimagetool ]; then
	echo "-----------------------------------------------------------------------------"
	echo "◆ Downloading \"appimagetool\" from https://github.com/AppImage/appimagetool"
	echo "-----------------------------------------------------------------------------"
	curl -#Lo appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage && chmod a+x appimagetool
fi

_release_still() {
	variant="still"
	release=$(curl -Ls https://www.libreoffice.org/download/download-libreoffice | tr '<' '\n' | grep dl_version | sed 's:.*>::' | tail -1)
	version=$(curl -Ls https://appimages.libreitalia.org/ | tr '"' '\n' | grep -oi "libreoffice-.*appimage$" | grep -v ">\|LibreOffice-fresh\|LibreOffice-still" | sort -t- -k1,1V -k2,2V -k3,3V -k4,4V | grep "$edition" | grep "$release" | tail -1 )
}

_release_fresh() {
	variant="fresh"
	release=$(curl -Ls https://www.libreoffice.org/download/download-libreoffice | tr '<' '\n' | grep dl_version | sed 's:.*>::' | head -1)
	version=$(curl -Ls https://appimages.libreitalia.org/ | tr '"' '\n' | grep -oi "libreoffice-.*appimage$" | grep -v ">\|LibreOffice-fresh\|LibreOffice-still" | sort -t- -k1,1V -k2,2V -k3,3V -k4,4V | grep "$edition" | grep "$release" | tail -1 )
}

_convert_to_appimage() {
	mkdir -p "$variant"
	[ ! -f "$variant"/appimagetool ] && cp -r ./appimagetool "$variant"/appimagetool
	cd "$variant" || exit 1

	curl -#Lo "$version" "https://appimages.libreitalia.org/$version" || exit 1
	echo "Extracting the AppImage, please wait..."
	chmod a+x ./"$version" && ./"$version" --appimage-extract 1>/dev/null
	rm -f "$version"

	FILENAME=$(echo "$version" | sed -- "s/$release/$variant-$release/g")
	REPO="LibreOffice-appimage"
	TAG="continuous-$variant"
	UPINFO="gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|$REPO|$TAG|*$variant*$edition.AppImage.zsync"

	ARCH=x86_64 ./appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 \
		-u "$UPINFO" \
		./squashfs-root "$FILENAME"

	[ -f ./"$FILENAME" ] && rm -Rf squashfs-root || exit 0
	cd ..
}

EDITIONS="basic-x86_64 basic.help-x86_64 standard-x86_64 standard.help-x86_64 full-x86_64 full.help-x86_64 basic-x86_64 basic.help-x86_64 standard-x86_64 standard.help-x86_64 full-x86_64 full.help-x86_64"
for edition in $EDITIONS; do
	# Create fresh
	_release_fresh
	_convert_to_appimage

	# Create still
	_release_still
	_convert_to_appimage
done

mv ./*/*AppImage* ./ || exit 0
