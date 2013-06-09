#!/bin/bash

source $(dirname $0)/functions.sh

LIPO=lipo
ARMV7S="`pwd`/tools/armv7sconvert/armv7sconvert.sh"
PREFIX=$(realpath "$1")
SELECTED_LIB=$2
ARCHS=${ARCHS:-"armv7 i386"}

set -e

if [ ! -d $PREFIX ]; then
    echo "You must provide the base build path to the built libraries as the first parameter"
    exit 1
fi

# start

for ARCH in $ARCHS
do
  if [ -d "$PREFIX/$ARCH" ]
  then
    MAIN_ARCH=$ARCH
  fi
done

if [ -z "$MAIN_ARCH" ]
then
  echo "Please compile an architecture"
  exit 1
fi

OUTPUT_DIR="$PREFIX/fat"
rm -rf $OUTPUT_DIR

mkdir -p $OUTPUT_DIR/lib $OUTPUT_DIR/include

for LIB in $PREFIX/$MAIN_ARCH/lib/*.a
do

  LIB=`basename $LIB`

  if [ ! -z "$SELECTED_LIB" ] ; then
    if [ "$LIB" != "$SELECTED_LIB" ] ; then
	continue
    fi
  fi

  LIPO_CREATE=""

  for ARCH in $ARCHS
  do
    if [ -d "$PREFIX/$ARCH" ]
    then
        LIPO_CREATE="$LIPO_CREATE-arch $ARCH $PREFIX/$ARCH/lib/$LIB "	
    fi
  done
  OUTPUT="$OUTPUT_DIR/lib/$LIB"
  echo "Creating: $OUTPUT"

  $LIPO -create $LIPO_CREATE -output $OUTPUT
  
  [ $? -eq 0 ] || {
    echo "Error while creating fat library"
    exit 3
  }
  
  # run the special armv7s script
  if [[ "$ARCHS" == *"armv7"* ]] ; then
    $ARMV7S "$OUTPUT_DIR/lib/$LIB"
    
    [ $? -eq 0 ] || {
	echo "Error while creating armv7s slice"
	exit 4
    }
  fi
  
  $LIPO -info $OUTPUT
done

echo "Copying headers from dist-$MAIN_ARCH..."
cp -R $PREFIX/$MAIN_ARCH/include $OUTPUT_DIR

[ $? -eq 0 ] || {
    echo "Could not copy the include headers"
    exit 4
}

exit 0