#!/bin/sh

DEBUG=1

ALL_LIBS="FFTW FAAC LAME OGG OGGZ THEORA VORBIS SPEEX FLAC MMS AACPLUS ID3LIB SNDFILE FISHSOUND"
#ALL_LIBS="LAME"

PLATFORMBASE="/Applications/Xcode.app/Contents/Developer/Platforms"
SDKVER=6.1

# configuration end

source $(dirname $0)/functions.sh

PREFIX="`pwd`/build"
ARCHS=${ARCHS:-"armv7 i386"}

LIPO=lipo
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
DEPS_DIR=$SCRIPT_DIR/libs
LOG_FILE="$SCRIPT_DIR/build_deps.log"
IOS_CONFIG_SCRIPT_NAME="ios-configure"
IOS_CONFIG_SCRIPT="$SCRIPT_DIR/$IOS_CONFIG_SCRIPT_NAME"

FAAC_DIR="$DEPS_DIR/faac"
FAAC_OPTIONS="--with-mp4v2 --with-ogg="
FAAC_LIB="libfaac.a"

FFTW_DIR="$DEPS_DIR/fftw"
FFTW_OPTIONS="--enable-single --enable-float"
FFTW_LIB="libfftw3.a"

SNDFILE_DIR="$DEPS_DIR/libsndfile"
SNDFILE_OPTIONS="--enable-experimental --disable-alsa --disable-test-coverate --disable-octave --disable-sqlite"
#SNDFILE_OPTIONS=""
SNDFILE_LIB="libsndfile.a"

LAME_DIR="$DEPS_DIR/lame"
LAME_OPTIONS="--disable-frontend --disable-nasm"
LAME_LIB="libmp3lame.a"

OGG_DIR="$DEPS_DIR/libogg"
OGG_OPTIONS=""
OGG_LIB="libogg.a"

OGGZ_DIR="$DEPS_DIR/liboggz"
OGGZ_OPTIONS="--enable-experimental --disable-oggtest"
OGGZ_LIB="liboggz.a"

THEORA_DIR="$DEPS_DIR/libtheora"
THEORA_OPTIONS="--disable-examples"
THEORA_LIB="libtheora.a"

VORBIS_DIR="$DEPS_DIR/libvorbis"
VORBIS_OPTIONS="--disable-examples --disable-docs"
VORBIS_LIB="libvorbis.a"

SPEEX_DIR="$DEPS_DIR/speex"
SPEEX_OPTIONS=""
SPEEX_LIB="libspeex.a"

FLAC_DIR="$DEPS_DIR/flac"
FLAC_OPTIONS="--disable-thorough-tests  --disable-doxygen-docs   --disable-xmms-plugin  --disable-oggtest --without-libiconv-prefix"
FLAC_LIB="libflac.a"

FISHSOUND_DIR="$DEPS_DIR/libfishsound"
FISHSOUND_OPTIONS="--enable-experimental"
FISHSOUND_LIB="libfishsound.a"

MMS_DIR="$DEPS_DIR/libmms"
MMS_OPTIONS=""
MMS_LIB="libmms.a"

AACPLUS_DIR="$DEPS_DIR/libaacplus"
AACPLUS_OPTIONS="--with-fftw3 --with-parameter-expansion-string-replace-capable-shell=/bin/bash"
AACPLUS_LIB="libaacplus.a"

ID3LIB_DIR="$DEPS_DIR/id3lib"
ID3LIB_OPTIONS=""
ID3LIB_LIB="libid3.a"

### NO CHANGES FROM HERE ON

if [ $DEBUG -eq 0 ]; then 
exec 1> $LOG_FILE
exec 2> $LOG_FILE
fi

if [ -n "$2" ]; then
    ARCHS="$2"
fi

if [ -n "$1" ]; then
    PREFIX=$(realpath "$1")
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
    export PFX_CURRENT=$PREFIX/$SDKVER

    # configure for each enabled arch
    for ARCH1 in $ARCHS
    do
	echo "Building $LIB for architecture: $ARCH1..."
	
	export ARCH=$ARCH1
	
	export PFX=$PFX_CURRENT/$ARCH
	export PFX_LIB=$PFX/lib
	export PFX_INC=$PFX/include

#	export VORBIS_LIBS=$PFX_LIB
#	export VORBISENC_LIBS=$PFX_LIB
#	export SPEEX_LIBS=$PFX_LIB
#	export FLAC_LIBS=$PFX_LIB
#	export OGGZ_LIBS=$PFX_LIB
#	export SNDFILE_LIBS=$PFX_LIB

#	export FLAC_CFLAGS="-I$PFX_INC/FLAC"
#	export OGG_CFLAGS="-I$PFX_INC/ogg"
#	export SPEEX_CFLAGS="-I$PFX_INC/speex"
#	export VORBIS_CFLAGS="-I$PFX_INC/vorbis"
#	export VORBISENC_CFLAGS="-I$PFX_INC/vorbis"

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
	    EXTRA_CONFIGURE_FLAGS="$EXTRA_CONFIGURE_FLAGS --with-ogg=$PFX --with-ogg-libraries=$PFX_LIB --with-ogg-includes=$PFX_INC"
	fi
	
	if [ $LIB = "THEORA" ]; then
	    EXTRA_CONFIGURE_FLAGS="$EXTRA_CONFIGURE_FLAGS --with-vorbis=$PFX --with-vorbis-includes=$PFX_INC --with-vorbis-libraries=$PFX_LIB"
	fi
    
	if [ $LIB = "AACPLUS" ]; then
	    EXTRA_CONFIGURE_FLAGS="--with-fftw3-prefix=$PFX"
	fi

	# copy ios configure script
	LIB_F=$LIB"_DIR"
	eval LIB_DIR='${'$LIB_F'}'
	rm -rf "$LIB_DIR/$IOS_CONFIG_SCRIPT_NAME" > /dev/null 2>&1
	cp "$IOS_CONFIG_SCRIPT" "$LIB_DIR/$IOS_CONFIG_SCRIPT_NAME" > /dev/null 2>&1 || { echo "Could not copy ios configure script in $LIB_DIR"; exit 3; }

	cd "$LIB_DIR"

	# clean
	make clean > /dev/null 2>&1
	make distclean > /dev/null 2>&1

	# run the ios configure script
	LIB_F=$LIB"_OPTIONS"
	eval CONFIG_OPTIONS='${'$LIB_F'}'
    
	./ios-configure --prefix=$PFX $CONFIG_OPTIONS $EXTRA_CONFIGURE_FLAGS
    
	[ $? -eq 0 ] || {
	    echo "Error while configuring $LIB."
	    exit 4
	}
    
	# make 
	make &&
	make install
    
	[ $? -eq 0 ] || {
	    echo "Error while making $LIB."
	    exit 5
	}

	cd ..
    done

    # combine all archs
    #echo "Combining architectures..."
    #COMBINE_F=$LIB"_LIB"
    #eval COMBINE_LIB='${'$COMBINE_F'}'
    #echo $COMBINE_LIB

    #cd "$SCRIPT_DIR"
    #$SCRIPT_DIR/combine.sh "$PFX_CURRENT" "$COMBINE_LIB"

    #[ $? -eq 0 ] || {
    #	echo Error while combining archs for lib: $LIB
    #	exit 6
    #}

done
    
echo "All deps built successfully!"

exit 0
