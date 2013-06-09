#!/bin/bash

[ -d "patches" ] || {
	echo "Patches dir not found"
	exit 1
}

echo "Patching deps..."

#patch -p1 -i patches/libmp3lame_configure_patch_darwin_xmms_problem_fix_3.99.5.patch &&
#patch -p1 -i patches/libogg_configure_darwin.patch 
patch -p1 -i patches/libvorbis_configure_patch_darwin_disabled_1.3.2.patch