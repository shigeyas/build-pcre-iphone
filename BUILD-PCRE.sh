#!/bin/bash
OPATH=$PATH

TARGET=pcre-8.32
SDK_VERSION=6.0

CONFIG="--disable-shared --enable-utf8"
DEVROOT="/Applications/Xcode.app/Contents/Developer"

# This script will compile a PCRE static lib for the device and simulator

build_pcre() {

    LIBNAME=$1
    DISTDIR=`pwd`/dist-$LIBNAME
    PLATFORM=$2

    echo "Building binary for iPhone $LIBNAME $PLATFORM to $DISTDIR"

    echo Removing ${TARGET}
    /bin/rm -rf ${TARGET}
    echo Extracting ${TARGET}
    tar zxf ${TARGET}.tar.gz

    case $LIBNAME in
	device)  ARCH="armv7"; HOST="--host=arm-apple-darwin";;
	*)       ARCH="i386"; HOST="";;
    esac

# Compile a version for the device...

    cd ${TARGET}

    SDKPATH="${DEVROOT}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDK_VERSION}.sdk"

    PATH="${DEVROOT}/Platforms/${PLATFORM}.platform/Developer/usr/bin:$OPATH"
    export PATH

    case $LIBNAME in
	simulator)
	    ln -s ${SDKPATH}/usr/lib/crt1.10.5.o crt1.10.6.o;
	    ;;
    esac

    ./configure ${CONFIG} ${HOST} \
	CFLAGS="-arch ${ARCH} -isysroot ${SDKPATH}" \
	CXXFLAGS="-arch ${ARCH} -isysroot ${SDKPATH}" \
	LDFLAGS="-L." \
	CC="${DEVROOT}/Platforms/${PLATFORM}.platform/Developer/usr/bin/gcc" \
	CXX="${DEVROOT}/Platforms/${PLATFORM}.platform/Developer/usr/bin/g++"

    # Eliminate test unit entry 
    perl -pi.bak \
	    -e 'if (/^all-am:/) { s/\$\(PROGRAMS\) //; }' \
            Makefile

    make

    mkdir ${DISTDIR}
    mkdir ${DISTDIR}/lib
    mkdir ${DISTDIR}/include

    cp -p .libs/libpcre.a ${DISTDIR}/lib
    cp -p .libs/libpcrecpp.a ${DISTDIR}/lib
    cp -p .libs/libpcreposix.a ${DISTDIR}/lib
    cp -p pcre*h ${DISTDIR}/include

    cd ..

    echo Clean-up ${TARGET}
    /bin/rm -rf ${TARGET}
}



build_pcre "device" "iPhoneOS"
build_pcre "simulator" "iPhoneSimulator"

### Then, combine them into one..

echo "Creating combined binary into directory 'dist'"

/bin/rm -rf dist
mkdir dist
TOP=`pwd`
(cd ${TOP}/dist-device; /usr/bin/tar cf - . ) | (cd ${TOP}/dist; /usr/bin/tar xf -)

for i in pcre pcrecpp pcreposix
do
    lipo -create dist-device/lib/lib$i.a dist-simulator/lib/lib$i.a \
	-o dist/lib/lib$i.a
done

/bin/rm -rf dist-simulator dist-device

echo "Now package is ready in 'dist' directory'"
