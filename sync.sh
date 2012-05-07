#!/bin/sh

set -e

SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
DIST_DIR_BASE=${DIST_DIR_BASE:="$SCRIPT_DIR/dist"}

if [ -d ffmpeg ]
then
  echo "Found ffmpeg source directory, no need to update anything"
  #exit 0
else
  echo "Fetching ffmpeg..."
  git clone git://source.ffmpeg.org/ffmpeg.git
  
  [ $? -eq 0 ] || exit 1
fi

ARCHS=${ARCHS:-"armv6 armv7 i386"}

for ARCH in $ARCHS
do
    FFMPEG_DIR=ffmpeg-$ARCH
    echo "Syncing source for $ARCH to directory $FFMPEG_DIR"
    rsync ffmpeg/ $FFMPEG_DIR/ --exclude '.*' -a --delete
    if [ -d patches ]
    then
        echo "Applying patches to source in directory $FFMPEG_DIR"
        git apply -v --directory=$FFMPEG_DIR patches/0001-iOS-SDK-Fixes.patch
    fi
done
