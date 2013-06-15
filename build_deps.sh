#!/bin/sh

DEBUG=1

#ALL_LIBS="FFTW ICU ICONV EXPAT FREETYPE FONTCONFIG FRIBIDI ASS GSM RTPMDUMP OPUS \ 
#FLITE HARFBUZZ FAAC LAME OGG OGGZ X264 THEORA VORBIS SPEEX FLAC MMS AACPLUS ID3LIB SNDFILE FISHSOUND"
ALL_LIBS="SQLITE_CIPHER"
#ALL_LIBS="ICU"

PLATFORMBASE="/Applications/Xcode.app/Contents/Developer/Platforms"
SDKVER=6.1

# configuration end

source $(dirname $0)/functions.sh

PREFIX="`pwd`/build"
ARCHS=${ARCHS:-"armv7 i386"}
ARCHS="i386"

LIPO=lipo
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
DEPS_DIR=$SCRIPT_DIR/libs
LOG_FILE="$SCRIPT_DIR/build_deps.log"
IOS_CONFIG_SCRIPT_NAME="ios-configure"
IOS_CONFIG_SCRIPT="$SCRIPT_DIR/$IOS_CONFIG_SCRIPT_NAME"

ICU_DIR="$DEPS_DIR/icu/source"
ICU_OPTIONS="--disable-shared --enable-static"

SQLITE_CIPHER_DIR="$DEPS_DIR/sqlcipher"
SQLITE_CIPHER_OPTIONS=""

VPX_DIR="$DEPS_DIR/libvpx"
VPX_OPTIONS=""

RTMPDUMP_DIR="$DEPS_DIR/rtmpdump/librtmp"
RTMPDUMP_OPTIONS=""

AMRNB_DIR="$DEPS_DIR/amrnb"
AMRNB_OPTIONS="--with-parameter-expansion-string-replace-capable-shell=/bin/bash"

GSM_DIR="$DEPS_DIR/gsm"
GSM_OPTIONS=""

FRIBIDI_DIR="$DEPS_DIR/fribidi"
FRIBIDI_OPTIONS="--without-glib"

RECODE_DIR="$DEPS_DIR/recode"
RECODE_OPTIONS="--without-libintl-prefix"

EXPAT_DIR="$DEPS_DIR/expat"
EXPAT_OPTIONS=""

ASS_DIR="$DEPS_DIR/libass"
ASS_OPTIONS="--disable-test "

FONTCONFIG_DIR="$DEPS_DIR/fontconfig"
FONTCONFIG_OPTIONS=""

HARFBUZZ_DIR="$DEPS_DIR/harfbuzz"
HARFBUZZ_OPTIONS="--with-coretext=no --with-glib=no --with-freetype=yes --with-cairo=no --with-uniscribe=no"

FLITE_DIR="$DEPS_DIR/flite"
FLITE_OPTIONS=""

FREETYPE_DIR="$DEPS_DIR/freetype"
FREETYPE_OPTIONS=""

VPX_DIR="$DEPS_DIR/libvpx"
VPX_OPTIONS="--disable-ccache --disable-docs --disable-examples --disable-unit-tests"

OPUS_DIR="$DEPS_DIR/opus"
OPUS_OPTIONS=""

X264_DIR="$DEPS_DIR/x264"
X264_OPTIONS="--disable-cli --disable-debug --disable-asm"
X264_OPTIONS_i386="--disable-cli --disable-debug"

ICONV_DIR="$DEPS_DIR/libiconv"
ICONV_OPTIONS="--enable-extra-encodings"

FAAC_DIR="$DEPS_DIR/faac"
FAAC_OPTIONS="--with-mp4v2 --with-ogg="

FFTW_DIR="$DEPS_DIR/fftw"
FFTW_OPTIONS="--enable-single --enable-float --enable-neon --disable-fma"
FFTW_OPTIONS_i386="--enable-single --enable-float --disable-fma"
# must enable #define ARM_NEON_GCC_COMPATIBILITY in simd-neon.h in order for NEON functions to build properly!

SNDFILE_DIR="$DEPS_DIR/libsndfile"
SNDFILE_OPTIONS="--enable-experimental --disable-alsa --disable-test-coverate --disable-octave --disable-sqlite"
#SNDFILE_OPTIONS=""

LAME_DIR="$DEPS_DIR/lame"
LAME_OPTIONS="--disable-frontend --enable-nasm"

OGG_DIR="$DEPS_DIR/libogg"
OGG_OPTIONS=""

OGGZ_DIR="$DEPS_DIR/liboggz"
OGGZ_OPTIONS="--enable-experimental --disable-oggtest"

THEORA_DIR="$DEPS_DIR/libtheora"
THEORA_OPTIONS="--disable-examples"

VORBIS_DIR="$DEPS_DIR/libvorbis"
VORBIS_OPTIONS="--disable-examples --disable-docs"

SPEEX_DIR="$DEPS_DIR/speex"
SPEEX_OPTIONS=""

FLAC_DIR="$DEPS_DIR/flac"
FLAC_OPTIONS="--disable-thorough-tests --disable-doxygen-docs --disable-xmms-plugin --disable-oggtest --disable-thorough-tests"
FLAC_OPTIONS_i386="--disable-thorough-tests --disable-doxygen-docs --disable-xmms-plugin --disable-oggtest --disable-sse --disable-3dnow --disable-altivec --disable-thorough-tests --disable-asm-optimizations"

FISHSOUND_DIR="$DEPS_DIR/libfishsound"
FISHSOUND_OPTIONS="--enable-experimental"

MMS_DIR="$DEPS_DIR/libmms"
MMS_OPTIONS=""

AACPLUS_DIR="$DEPS_DIR/libaacplus"
AACPLUS_OPTIONS="--with-fftw3 --with-parameter-expansion-string-replace-capable-shell=/bin/bash"

ID3LIB_DIR="$DEPS_DIR/id3lib"
ID3LIB_OPTIONS=""

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

	# create the dir
	mkdir -p $PFX
	mkdir -p "$PFX/include"

	# workaround a compilation error for a missing header file in the iOS SDK
	# which some libraries depend on
	touch "$PFX/include/crt_externs.h"

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

	LIB_F=$LIB"_DIR"
	eval LIB_DIR='${'$LIB_F'}'
    
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

	if [ $LIB = "RECODE" ]; then
	    EXTRA_CONFIGURE_FLAGS="--with-libiconv-prefix=$PFX"
	fi

	if [ $LIB = "ICU" ]; then
	    EXTRA_CONFIGURE_FLAGS="--with-cross-build=$LIB_DIR/hostbuild"
	    export EXT_INC="-Wl,-dead_strip -miphoneos-version-min=2.0 -lstdc++ -I$LIB_DIR/tools/tzcode/"
	    export EXT_CFLAGS="-DDARWIN -fno-common -Wall -g -O3 -ffast-math -fsigned-char -miphoneos-version-min=2.2"
	fi

	if [ $LIB = "SQLITE_CIPHER" ]; then
	    EXTRA_CONFIGURE_FLAGS="--enable-tempstore=yes --disable-tcl --enable-static --disable-shared"
	    export EXT_INC=""
	    export EXT_LIBS="-lstdc++ -lcrypto -liconv -licudata -licuio -licule -liculx -licutest -licutu -licuuc -licui18n"
	    export EXT_CFLAGS="-DSQLITE_ENABLE_ICU -DSQLITE_HAS_CODEC -DNDEBUG -DSQLITE_OS_UNIX=1 -DSQLITE_TEMP_STORE=2 -DSQLITE_THREADSAFE"
	fi
	
	if [ $LIB = "VPX" ]; then
	    if [ $ARCH = "armv7" ]; then
		EXTRA_CONFIGURE_FLAGS="--target=armv7-darwin-gcc"
	    else
		EXTRA_CONFIGURE_FLAGS="--target=x86-darwin10-gcc"
	    fi
	fi

	# copy ios configure script
	rm -rf "$LIB_DIR/$IOS_CONFIG_SCRIPT_NAME" > /dev/null 2>&1
	cp "$IOS_CONFIG_SCRIPT" "$LIB_DIR/$IOS_CONFIG_SCRIPT_NAME" > /dev/null 2>&1 || { echo "Could not copy ios configure script in $LIB_DIR"; exit 3; }

	cd "$LIB_DIR"

	# clean
	make clean > /dev/null 2>&1
	make distclean > /dev/null 2>&1

	# run the ios configure script
	LIB_F=$LIB"_OPTIONS"
	LIB_FC=$LIB_F"_"$ARCH
	
	eval CONFIG_OPTIONS='${'$LIB_FC'}'
	
	if [ "$CONFIG_OPTIONS" == "" ] ; then
	    eval CONFIG_OPTIONS='${'$LIB_F'}'
	fi

	./ios-configure --prefix=$PFX $CONFIG_OPTIONS $EXTRA_CONFIGURE_FLAGS --disable-programs --disable-debug
    
	[ $? -eq 0 ] || {
	    echo "Error while configuring $LIB."
	    exit 4
	}
    
	# make 
	make VERBOSE=1 &&
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
