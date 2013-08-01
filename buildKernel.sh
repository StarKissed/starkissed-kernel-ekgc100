#!/bin/sh

# Copyright (C) 2011 Twisted Playground

# This script is designed by Twisted Playground for use on MacOSX 10.7 but can be modified for other distributions of Mac and Linux

PROPER=`echo $1 | sed 's/\([a-z]\)\([a-zA-Z0-9]*\)/\u\1\2/g'`

HANDLE=TwistedZero
KERNELSPEC=/Volumes/android/EK-GC100_Galaxy_Cam
KERNELREPO=/Users/TwistedZero/Public/Dropbox/TwistedServer/Playground/kernels
#TOOLCHAIN_PREFIX=/Volumes/android/android-toolchain-eabi/bin/arm-eabi-
TOOLCHAIN_PREFIX=/Volumes/android/android-tzb_ics4.0.1/prebuilt/darwin-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-
GOOSERVER=loungekatt@upload.goo.im:public_html
PUNCHCARD=`date "+%m-%d-%Y_%H.%M"`

echo "1. Wifi"
echo "2. AT&T"
echo "3. VZW"
echo "Please Choose: "
read profile

case $profile in
1)
zipfile=$HANDLE"_StarKissed-EKGC-Wifi.zip"
KENRELZIP="StarKissed-EKGC_$PUNCHCARD-Wifi.zip"
BUILDTYPE=buildimg
;;
2)
zipfile=$HANDLE"_StarKissed-EKGC-ATT.zip"
KENRELZIP="StarKissed-EKGC_$PUNCHCARD-ATT.zip"
BUILDTYPE=buildatt
;;
3)
zipfile=$HANDLE"_StarKissed-EKGC-VZW.zip"
KENRELZIP="StarKissed-EKGC_$PUNCHCARD-VZW.zip"
BUILDTYPE=buildvzw
;;
*)
exit 1
;;
esac

MODULEOUT=$KERNELSPEC/$BUILDTYPE/boot.img-ramdisk

CPU_JOB_NUM=8

# Copy the passed config to default
cp -R config/$1_config arch/arm/configs/gc1pq_00_defconfig

if [ -e $KERNELSPEC/$BUILDTYPE/boot.img ]; then
    rm -R $KERNELSPEC/$BUILDTYPE/boot.img
fi
if [ -e $KERNELSPEC/$BUILDTYPE/newramdisk.cpio.gz ]; then
    rm -R $KERNELSPEC/$BUILDTYPE/newramdisk.cpio.gz
fi
if [ -e $KERNELSPEC/$BUILDTYPE/zImage ]; then
    rm -R $KERNELSPEC/$BUILDTYPE/zImage
fi

make clean -j$CPU_JOB_NUM

make gc1pq_00_defconfig
make -j$CPU_JOB_NUM ARCH=arm CROSS_COMPILE=$TOOLCHAIN_PREFIX

if [ -e arch/arm/boot/zImage ]; then

    if [ `find . -name "*.ko" | grep -c ko` > 0 ]; then

        find . -name "*.ko" | xargs ${TOOLCHAIN_PREFIX}strip --strip-unneeded

        if [ ! -d $MODULEOUT ]; then
            mkdir $MODULEOUT
        fi
        if [ ! -d $MODULEOUT/lib ]; then
            mkdir $MODULEOUT/lib
        fi
        if [ ! -d $MODULEOUT/lib/modules ]; then
            mkdir $MODULEOUT/lib/modules
        else
            rm -r $MODULEOUT/lib/modules
            mkdir $MODULEOUT/lib/modules
        fi

        for j in $(find . -name "*.ko"); do
            cp -R "${j}" $MODULEOUT/lib/modules
        done

    fi

    cp -R arch/arm/boot/zImage $BUILDTYPE

    cd $BUILDTYPE
    ./img.sh

    echo "building boot package"
    cp -R boot.img ../output
    cd ../

    if [ -e output/boot.tar ]; then
        rm -R output/boot.tar
    fi
    if [ -e output/boot.tar ]; then
        rm -R output/boot.tar.md5
    fi
    if [ -e output/boot.tar ]; then
        rm -R output/boot.tar.md5.gz
    fi

    IMAGEFILE=boot.$PUNCHCARD.img
    KERNELFILE=boot.$PUNCHCARD.tar

    cp -r  output/boot.img $KERNELREPO/gooserver/$IMAGEFILE
    scp -P 2222 $KERNELREPO/gooserver/$IMAGEFILE $GOOSERVER/galaxycam

    cp -R output/boot.img starkissed
    cd starkissed
    rm *.zip
    zip -r $zipfile *
    cd ../
    cp -R $KERNELSPEC/starkissed/$zipfile $KERNELREPO/$zipfile

    if [ -e $KERNELREPO/$zipfile ]; then
        cp -R $KERNELREPO/$zipfile $KERNELREPO/gooserver/$KENRELZIP
        scp -P 2222 $KERNELREPO/gooserver/$KENRELZIP  $GOOSERVER/galaxycam
        rm -R $KERNELREPO/gooserver/$KENRELZIP
    fi

    if cat /etc/issue | grep Ubuntu; then
        tar -H ustar -c output/boot.img > output/boot.tar
    else
        gnutar -H ustar -c output/boot.img > output/boot.tar
    fi
    cp -r output/boot.tar $KERNELREPO/camera/boot.tar
    cp -r $KERNELREPO/camera/boot.tar $KERNELREPO/gooserver
    scp -P 2222 $KERNELREPO/gooserver/$KERNELFILE $GOOSERVER/galaxycam
    rm -R $KERNELREPO/gooserver/$KERNELFILE
    cp -r output/boot.tar output/boot.tar.md5
    if cat /etc/issue | grep Ubuntu; then
        md5sum -r output/boot.tar.md5 >> output/boot.tar.md5
    else
        md5 -r output/boot.tar.md5 >> output/boot.tar.md5
    fi
    gzip output/boot.tar.md5 -c -v > output/boot.tar.md5.gz
    cp -r output/boot.tar.md5.gz $KERNELREPO/camera/boot.tar.md5.gz
    cp -r $KERNELREPO/camera/boot.tar.md5.gz $KERNELREPO/gooserver/$KERNELFILE.md5.gz
    scp -P 2222 $KERNELREPO/gooserver/$KERNELFILE.md5.gz $GOOSERVER/galaxycam
    rm -R $KERNELREPO/gooserver/$KERNELFILE.md5.gz
fi

cd $KERNELSPEC
