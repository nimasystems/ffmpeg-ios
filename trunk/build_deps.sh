#!/bin/sh

ARCHS=${ARCHS:-"armv7 i386"}
#ALL_LIBS="FAAC LAME OGG OGGZ THEORA VORBIS SPEEX FLAC FISHSOUND MMS AACPLUS ID3LIB"
ALL_LIBS="FAAC LAME OGG OGGZ THEORA VORBIS SPEEX FLAC MMS AACPLUS ID3LIB"
#ALL_LIBS="AACPLUS ID3LIB"

PLATFORMBASE="/Applications/Xcode.app/Contents/Developer/Platforms"
SDKVER=6.1
SHAREDLIBS="/opt/ios"

# configuration end

SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
LOG_FILE="$SCRIPT_DIR/build_deps.log"
IOS_CONFIG_SCRIPT_NAME="ios-configure"
IOS_CONFIG_SCRIPT="$SCRIPT_DIR/$IOS_CONFIG_SCRIPT_NAME"

FAAC_DIR="$SCRIPT_DIR/faac"
FAAC_OPTIONS=""

LAME_DIR="$SCRIPT_DIR/lame"
LAME_OPTIONS="--disable-frontend --disable-nasm"

OGG_DIR="$SCRIPT_DIR/libogg"
OGG_OPTIONS=""

OGGZ_DIR="$SCRIPT_DIR/liboggz"
OGGZ_OPTIONS="--enable-experimental  --disable-oggtest"

THEORA_DIR="$SCRIPT_DIR/libtheora"
THEORA_OPTIONS="--disable-valgrind-testing --disable-oggtest --disable-vorbistest --disable-sdltest --disable-float --disable-encode --disable-examples"

VORBIS_DIR="$SCRIPT_DIR/libvorbis"
VORBIS_OPTIONS="--disable-oggtest --disable-docs"

SPEEX_DIR="$SCRIPT_DIR/speex"
SPEEX_OPTIONS="--disable-oggtest"

FLAC_DIR="$SCRIPT_DIR/flac"
FLAC_OPTIONS="--disable-thorough-tests  --disable-doxygen-docs   --disable-xmms-plugin  --disable-oggtest --without-libiconv-prefix"

FISHSOUND_DIR="$SCRIPT_DIR/libfishsound"
FISHSOUND_OPTIONS="--enable-experimental"

MMS_DIR="$SCRIPT_DIR/libmms"
MMS_OPTIONS=""

AACPLUS_DIR="$SCRIPT_DIR/libaacplus"
AACPLUS_OPTIONS="--without-fftw3 --with-parameter-expansion-string-replace-capable-shell=/bin/bash"

ID3LIB_DIR="$SCRIPT_DIR/id3lib"
ID3LIB_OPTIONS=""

### NO CHANGES FROM HERE ON

if [ -n "$1" ]; then
	ALL_LIBS="$1"
fi

if [ -n "$2" ]; then
	ARCHS="$2"
fi

export SDKVER
export SHAREDLIBS
export ARCHS

# check if all libs exist
for LIB in $ALL_LIBS
do
    LIB_F=$LIB"_DIR"
    eval LIB_DIR='${'$LIB_F'}'
    
    [ -d $LIB_DIR ] || {
	echo "Library $LIB not found"
	echo "Remember to apply the necessary patches in ./patches before building!"
	exit 1
    } 
done

# check ios_configure script
[ -f $IOS_CONFIG_SCRIPT ] || {
    echo "iOS configure script not found: $IOS_CONFIG_SCRIPT"
    exit 2
}

# remove previous log file
if [ -f "$LOG_FILE" ]; then
    rm -rf "$LOG_FILE" > /dev/null 2>&1
fi

# configure each
for LIB in $ALL_LIBS
do
    # configure for each enabled arch
    for ARCH1 in $ARCHS
    do
	echo "Building $LIB for architecture: $ARCH1..."
	
	export ARCH=$ARCH1

	case $ARCH in
    	    armv6)
            	PLATFORM="${PLATFORMBASE}/iPhoneOS.platform"
		DEVROOT="$PLATFORM/Developer"
		SDKROOT="$DEVROOT/SDKs/iPhoneOS$SDKVER.sdk"
            	;;
    	    armv7)
            	PLATFORM="${PLATFORMBASE}/iPhoneOS.platform"
		DEVROOT="$PLATFORM/Developer"
		SDKROOT="$DEVROOT/SDKs/iPhoneOS$SDKVER.sdk"
            	;;
    	    i386)
            	PLATFORM="${PLATFORMBASE}/iPhoneSimulator.platform"
		DEVROOT="$PLATFORM/Developer"
		SDKROOT="$DEVROOT/SDKs/iPhoneSimulator$SDKVER.sdk"
            	;;
    	    *)
            	echo "Unsupported architecture ${ARCH}"
            	exit 1
            	;;
    	esac

	export DEVROOT
	export SDKROOT
	
	EXTRA_CONFIGURE_FLAGS=""
    
	# extra options depending on arch for THEORA/VORBIS/SPEEX
	if [ $LIB = "THEORA" ] || [ $LIB = "VORBIS" ] || [ $LIB = "SPEEX" ] || [ $LIB = "FLAC" ] || [ $LIB = "OGGZ" ] ; then
	    EXTRA_CONFIGURE_FLAGS="$EXTRA_CONFIGURE_FLAGS --with-ogg=$SHAREDLIBS/$SDKVER/$ARCH --with-ogg-libraries=$SHAREDLIBS/$SDKVER/$ARCH/lib/ --with-ogg-includes=$SHAREDLIBS/$SDKVER/$ARCH/include/"
	fi
	
	if [ $LIB = "THEORA" ]; then
	    EXTRA_CONFIGURE_FLAGS="$EXTRA_CONFIGURE_FLAGS --with-vorbis=$SHAREDLIBS/$SDKVER/$ARCH --with-vorbis-includes=$SHAREDLIBS/$SDKVER/$ARCH/include/ --with-vorbis-libraries=$SHAREDLIBS/$SDKVER/$ARCH/lib/"
	fi
    
	# copy ios configure script
	LIB_F=$LIB"_DIR"
	eval LIB_DIR='${'$LIB_F'}'
	rm -rf "$LIB_DIR/$IOS_CONFIG_SCRIPT_NAME" > /dev/null 2>&1
	cp "$IOS_CONFIG_SCRIPT" "$LIB_DIR/$IOS_CONFIG_SCRIPT_NAME" > /dev/null 2>&1 || { echo "Could not copy ios configure script in $LIB_DIR"; exit 3; }

	cd "$LIB_DIR"

	# clean
	make clean > /dev/null 2>&1

	# run the ios configure script
	LIB_F=$LIB"_OPTIONS"
	eval CONFIG_OPTIONS='${'$LIB_F'}'
    
	./ios-configure $CONFIG_OPTIONS $EXTRA_CONFIGURE_FLAGS >> $LOG_FILE 2>&1
    
	[ $? -eq 0 ] || {
	    echo "Error while configuring $LIB."
	    exit 4
	}
    
	# make 
	make >> $LOG_FILE 2>&1 &&
	make install >> $LOG_FILE 2>&1
    
	[ $? -eq 0 ] || {
	    echo "Error while making $LIB."
	    exit 5
	}

	cd ..
    done
done

echo "All deps built successfully!"

# combine all
echo "Combining architectures..."
cd "$SCRIPT_DIR"
$SCRIPT_DIR/combine.sh

[ $? -eq 0 ] || {
	echo "Error while combining archs"
	exit 6
}

# output the end result
lipo -info $SHAREDLIBS/$SDKVER/fat/lib/*

exit 0
