#!/bin/sh

PLATFORMBASE="/Applications/Xcode.app/Contents/Developer/Platforms"
IOSSDKVERSION=6.1
PREFIX="`pwd`/build"

ARCHS=${ARCHS:-"armv7 i386"}
ARCHFAT="fat"

set -e

SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
DIST_DIR_BASE="$PREFIX/$IOSSDKVERSION"

if [ ! -d $SCRIPT_DIR/dist/ffmpeg ]
then
  echo "ffmpeg source directory does not exist, run sync.sh"
  exit 1
fi

export DEVROOT="$PLATFORMBASE/iPhoneOS.platform/Developer"
export SDKROOT="$DEVROOT/SDKs/iPhoneOS$IOSSDKVERSION.sdk"

for ARCH in $ARCHS
do
    export PFX=$PREFIX/$IOSSDKVERSION/$ARCH
    export PKG_CONFIG_PATH=$SDKROOT/usr/lib/pkgconfig:$DEVROOT/usr/lib/pkgconfig:$PFX/lib/pkgconfig

    FFMPEG_DIR=$SCRIPT_DIR/dist/ffmpeg-$ARCH
    if [ ! -d $FFMPEG_DIR ]
    then
      echo "Directory $FFMPEG_DIR does not exist, run sync.sh"
      exit 1
    fi

    echo "Compiling source for $ARCH in directory $FFMPEG_DIR"

    cd $FFMPEG_DIR

    DIST_DIR="$DIST_DIR_BASE/$ARCH"

    case $ARCH in
        armv6)
            EXTRA_FLAGS="--cpu=arm1176jzf-s"
            EXTRA_CFLAGS=""
            PLATFORM="${PLATFORMBASE}/iPhoneOS.platform"
            IOSSDK=iPhoneOS${IOSSDKVERSION}
            ;;
        armv7)
            EXTRA_FLAGS="--cpu=cortex-a8 --enable-pic"
            EXTRA_CFLAGS="-mfpu=neon -I$DIST_DIR/include"
            PLATFORM="${PLATFORMBASE}/iPhoneOS.platform"
            IOSSDK=iPhoneOS${IOSSDKVERSION}
            ;;
        i386)
            EXTRA_FLAGS="--enable-pic"
            EXTRA_CFLAGS=""
            PLATFORM="${PLATFORMBASE}/iPhoneSimulator.platform"
            IOSSDK=iPhoneSimulator${IOSSDKVERSION}
            ;;
        *)
            echo "Unsupported architecture ${ARCH}"
            exit 1
            ;;
    esac

    EXTRA_CFLAGS="$EXTRA_CFLAGS -I$PREFIX/$IOSSDKVERSION/$ARCH/include -L$PREFIX/$IOSSDKVERSION/$ARCH/lib -I$PREFIX/$IOSSDKVERSION/$ARCH/include -L$PREFIX/$IOSSDKVERSION/$ARCH/lib"

    echo "Configuring ffmpeg for $ARCH (using $PREFIX/$IOSSDKVERSION/$ARCH path for external libraries)..."
    ./configure \
    --enable-zlib \
    --enable-version3 \
    --enable-nonfree \
    --enable-libmp3lame \
    --enable-libspeex \
    --enable-libtheora \
    --enable-libfaac \
    --enable-libvorbis \
    --enable-libaacplus \
    --prefix=$DIST_DIR \
    --enable-cross-compile --target-os=darwin --arch=$ARCH \
    --extra-ldflags="-L${PLATFORM}/Developer/SDKs/${IOSSDK}.sdk/usr/lib/system -L$PREFIX/$IOSSDKVERSION/$ARCH/lib" \
    --cross-prefix="${PLATFORM}/Developer/usr/bin/" \
    --sysroot="${PLATFORM}/Developer/SDKs/${IOSSDK}.sdk" \
    --enable-neon \
    --disable-doc \
    --disable-debug \
    --disable-ffmpeg \
    --disable-ffplay \
    --disable-ffserver \
    --disable-ffprobe \
    --disable-decoder=h264,svq3 \
    --disable-parser=h264 \
    --as="/usr/bin/gas-preprocessor.pl ${PLATFORM}/Applications/Xcode.app/Contents/Developer/usr/bin/as" \
    --extra-ldflags="-arch $ARCH -L$PREFIX/$IOSSDKVERSION/$ARCH/lib" \
    --extra-cflags="-arch $ARCH $EXTRA_CFLAGS" \
    --extra-cxxflags="-arch $ARCH" \
    $EXTRA_FLAGS

    echo "Installing ffmpeg for $ARCH..."

    make clean
    make -j8 V=1
    make install

    cd $SCRIPT_DIR

    if [ -d $DIST_DIR/bin ]
    then
      rm -rf $DIST_DIR/bin
    fi

    if [ -d $DIST_DIR/share ]
    then
      rm -rf $DIST_DIR/share
    fi
done

# combine all
#echo "Combining architectures..."
#cd "$SCRIPT_DIR"
#$SCRIPT_DIR/combine.sh

#[ $? -eq 0 ] || {
#	echo "Error while combining archs"
#	exit 6
#}

# output the end result
#lipo -info $SHAREDLIBS/$IOSSDKVERSION/fat/lib/*

exit 0
