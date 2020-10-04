#!/bin/sh
# called with aport branch/name eg: main/zsh

if [ -n "$1" ]
then
  tobuild="$1"
else
  >&2 echo "No aport specified, eg: $0 main/zsh"
  exit 2
fi

echo "Downloading aport files list..."
afiles=$(wget -qO- "https://git.alpinelinux.org/aports/tree/$tobuild" | \
grep 'ls-blob' | sed "s+blame+plain+" | sed -r "s+.*ls-blob.*href='(.*)'.*+\1+" | xargs)
echo "Extracted filenames: $afiles"

mkdir -p aport
cd aport
for afile in $afiles
do
  echo "Downloading $afile"
  wget -q "https://git.alpinelinux.org$afile"
done

echo "Preparing to build $tobuild"
[ -f ../APKBUILD.patch ] && patch -p1 -i ../APKBUILD.patch
[ -f ../prebuild.sh ] && sh ../prebuild.sh
[ -d ../newfiles ] && cp ../newfiles/* .
source ./APKBUILD
apk add $(echo "$depends" "$makedepends" "$checkdepends" | xargs)
#abuild checksum

#echo "Building $tobuild"
#abuild -r
