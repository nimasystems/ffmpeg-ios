#!/bin/bash

set -e

if [ -z "$ARCHS" ]; then
    export ARCHS="armv6 armv7 i386"
fi

if [ -z "$SHAREDLIBS" ]; then
    export SHAREDLIBS="/opt/ios"
fi

if [ -z "$SDKVER" ]; then
    export SDKVER="5.1"
fi

# start

for ARCH in $ARCHS
do
  if [ -d "$SHAREDLIBS/$SDKVER/$ARCH" ]
  then
    MAIN_ARCH=$ARCH
  fi
done

if [ -z "$MAIN_ARCH" ]
then
  echo "Please compile an architecture"
  exit 1
fi

OUTPUT_DIR="$SHAREDLIBS/$SDKVER/fat"
rm -rf $OUTPUT_DIR

mkdir -p $OUTPUT_DIR/lib $OUTPUT_DIR/include

for LIB in $SHAREDLIBS/$SDKVER/$MAIN_ARCH/lib/*.a
do
  LIB=`basename $LIB`
  LIPO_CREATE=""

  for ARCH in $ARCHS
  do
    if [ -d "$SHAREDLIBS/$SDKVER/$ARCH" ]
    then
      LIPO_CREATE="$LIPO_CREATE-arch $ARCH $SHAREDLIBS/$SDKVER/$ARCH/lib/$LIB "
    fi
  done
  OUTPUT="$OUTPUT_DIR/lib/$LIB"
  echo "Creating: $OUTPUT"

  lipo -create $LIPO_CREATE -output $OUTPUT
  lipo -info $OUTPUT
done

echo "Copying headers from dist-$MAIN_ARCH..."
cp -R $SHAREDLIBS/$SDKVER/$MAIN_ARCH/include $OUTPUT_DIR
