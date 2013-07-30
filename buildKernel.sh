#!/bin/sh

# Copyright (C) 2011 Twisted Playground

# This script is designed by Twisted Playground for use on MacOSX 10.7 but can be modified for other distributions of Mac and Linux

PROPER=`echo $2 | sed 's/\([a-z]\)\([a-zA-Z0-9]*\)/\u\1\2/g'`

HANDLE=TwistedZero
KERNELSPEC=/Volumes/android/EK-GC100_Galaxy_Cam
KERNELREPO=/Users/TwistedZero/Public/Dropbox/TwistedServer/Playground/kernels
#TOOLCHAIN_PREFIX=/Volumes/android/android-toolchain-eabi/bin/arm-eabi-
TOOLCHAIN_PREFIX=/Volumes/android/android-tzb_ics4.0.1/prebuilt/darwin-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-
MODULEOUT=$KERNELSPEC/buildimg/boot.img-ramdisk
GOOSERVER=loungekatt@upload.goo.im:public_html
PUNCHCARD=`date "+%m-%d-%Y_%H.%M"`

CPU_JOB_NUM=8

# Copy the passed config to default
cp -R config/$2_config arch/arm/configs/gc1pq_00_defconfig

if [ -e $KERNELSPEC/buildimg/boot.img ]; then
    rm -R $KERNELSPEC/buildimg/boot.img
fi
if [ -e $KERNELSPEC/buildimg/newramdisk.cpio.gz ]; then
    rm -R $KERNELSPEC/buildimg/newramdisk.cpio.gz
fi
if [ -e $KERNELSPEC/buildimg/zImage ]; then
    rm -R $KERNELSPEC/buildimg/zImage
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

cp -R arch/arm/boot/zImage buildimg

cd buildimg
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

if cat /etc/issue | grep Ubuntu; then
    tar -H ustar -c output/boot.img > output/boot.tar
else
    gnutar -H ustar -c output/boot.img > output/boot.tar
fi
# Create an md5 kernel image
if [ "$1" == "1" ]; then
    KERNELFILE=$KERNELFILE.md5.gz
    cp -r output/boot.tar output/boot.tar.md5
    if cat /etc/issue | grep Ubuntu; then
        md5sum -r output/boot.tar.md5 >> output/boot.tar.md5
    else
        md5 -r output/boot.tar.md5 >> output/boot.tar.md5
    fi
    gzip output/boot.tar.md5 -c -v > output/boot.tar.md5.gz
    cp -r output/boot.tar.md5.gz $KERNELREPO/boot.tar.md5.gz
    cp -r $KERNELREPO/boot.tar.md5.gz $KERNELREPO/gooserver/$KERNELFILE
# Skip md5 hash generation
else
    cp -r output/boot.tar $KERNELREPO/boot.tar
    cp -r $KERNELREPO/boot.tar $KERNELREPO/gooserver/$KERNELFILE
fi
scp -P 2222 $KERNELREPO/gooserver/$KERNELFILE $GOOSERVER/galaxycam
rm -R $KERNELREPO/gooserver/$KERNELFILE
fi

cd $KERNELSPEC
