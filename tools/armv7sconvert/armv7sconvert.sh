#!/bin/bash

CONVERT="armv7sconvert"
ARCHIVE="$1"
LIPO="xcrun -sdk iphoneos lipo"
AR="xcrun -sdk iphoneos ar"
TEMP="`mktemp -d -t build`"

cp ${ARCHIVE} ${TEMP}
pushd ${TEMP}

#/bin/cp ${ARCHIVE} ${ARCHIVE}.armv7
${LIPO} -thin armv7 ${ARCHIVE} -output ${ARCHIVE}.armv7

[ $? -eq 0 ] || {
    echo "LIPO error 1"
    exit 1
}

${AR} -x ${ARCHIVE}.armv7

[ $? -eq 0 ] || {
    echo "XCRUN error"
    exit 2
}

find . -name '*.o' -exec ${CONVERT} {} {}2 \; > /dev/null
find . -name '*.ao' -exec ${CONVERT} {} {}2 \; > /dev/null

rm *.ao
rm *.o

${AR} -r ${ARCHIVE}.armv7s *.o2
${AR} -r ${ARCHIVE}.armv7s *.ao2

[ $? -eq 0 ] || {
    echo "XCRUN error 2"
    #exit 3
}

rm *.o2
rm *.ao2
${LIPO} -create -arch armv7s ${ARCHIVE}.armv7s ${ARCHIVE} -output ${ARCHIVE}.new

[ $? -eq 0 ] || {
    echo "LIPO error 2"
    exit 4
}

popd

mv ${ARCHIVE}.new ${ARCHIVE}

[ $? -eq 0 ] || {
    echo "Could not move generated armv7s fat lib"
    exit 5
}

rm -rf ${TEMP}
rm -rf ${ARCHIVE}.armv7
rm -rf ${ARCHIVE}.armv7s

exit 0