#!/bin/sh

# Copyright (C) 2011 Twisted Playground

# This script is designed by Twisted Playground for use on MacOSX 10.7 but can be modified for other distributions of Mac and Linux

HANDLE=TwistedZero
KERNELSPEC=$(pwd)
KERNELREPO=/Users/TwistedZero/Public/Dropbox/TwistedServer/Playground/kernels
#TOOLCHAIN_PREFIX=/Volumes/android/android-toolchain-eabi-4.6/bin/arm-eabi-
TOOLCHAIN_PREFIX=/Volumes/android/android-tzb_ics4.0.1/prebuilt/darwin-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-
GOOSERVER=upload.goo.im:public_html
PUNCHCARD=`date "+%m-%d-%Y_%H.%M"`

echo "1. Wifi"
echo "2. AT&T"
echo "3. VZW"
echo "4. All"
echo "Please Choose: "
read profile

case $profile in
1)
TYPE=wifi
;;
2)
TYPE=att
;;
3)
TYPE=vzw
;;
4)
zipfile=$HANDLE"_StarKissed-EKGC.zip"
KENRELZIP="StarKissed-EKGC_$PUNCHCARD.zip"
cp -R buildatt/boot.img starkissed/kernel/att
cp -R buildwifi/boot.img starkissed/kernel/wifi
cp -R buildvzw/boot.img starkissed/kernel/vzw
cd starkissed
rm *.zip
zip -r $zipfile *
cd ../
cp -R $KERNELSPEC/starkissed/$zipfile $KERNELREPO/$zipfile

if [ -e $KERNELREPO/$zipfile ]; then
    cp -R $KERNELREPO/$zipfile ~/.goo/$KENRELZIP
    scp -P 2222 ~/.goo/$KENRELZIP  $GOOSERVER/galaxycam/kernel
    rm -R ~/.goo/$KENRELZIP
fi
exit 1
;;
*)
exit 1
;;
esac

PROPER=`echo $TYPE | sed 's/\([a-z]\)\([a-zA-Z0-9]*\)/\u\1\2/g'`
MODULEOUT=$KERNELSPEC/build$TYPE/boot.img-ramdisk
IMAGEFILE=boot.$PUNCHCARD-$PROPER.img
KERNELFILE=boot.$PUNCHCARD-$PROPER.tar

# CPU_JOB_NUM=`grep processor /proc/cpuinfo|wc -l`
CORES=`sysctl -a | grep machdep.cpu | grep core_count | awk '{print $2}'`
THREADS=`sysctl -a | grep machdep.cpu | grep thread_count | awk '{print $2}'`
CPU_JOB_NUM=$((($CORES * $THREADS) / 2))

# Copy the passed config to default
cp -R config/$1_config arch/arm/configs/gc1pq_00_defconfig

if [ -e $KERNELSPEC/build$TYPE/boot.img ]; then
    rm -R $KERNELSPEC/build$TYPE/boot.img
fi
if [ -e $KERNELSPEC/build$TYPE/newramdisk.cpio.gz ]; then
    rm -R $KERNELSPEC/build$TYPE/newramdisk.cpio.gz
fi
if [ -e $KERNELSPEC/build$TYPE/zImage ]; then
    rm -R $KERNELSPEC/build$TYPE/zImage
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

    cp -R arch/arm/boot/zImage build$TYPE

    cd build$TYPE
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

    cp -r  output/boot.img $KERNELREPO/camera/boot-$PROPER.img

    if cat /etc/issue | grep Ubuntu; then
        tar -H ustar -c output/boot.img > output/boot.tar
    else
        tar --format ustar -c output/boot.img > output/boot.tar
    fi
    cp -r output/boot.tar $KERNELREPO/camera/boot-$PROPER.tar
    cp -r output/boot.tar output/boot.tar.md5
    if cat /etc/issue | grep Ubuntu; then
        md5sum -t output/boot.tar.md5 >> output/boot.tar.md5
    else
        md5 -r output/boot.tar.md5 >> output/boot.tar.md5
    fi
    cp -r output/boot.tar.md5 $KERNELREPO/camera/boot-$PROPER.tar.md5

    cp -r  $KERNELREPO/camera/boot-$PROPER.img ~/.goo/$IMAGEFILE
    scp ~/.goo/$IMAGEFILE $GOOSERVER/galaxycam/kernel
    rm -R ~/.goo/$IMAGEFILE
    cp -r $KERNELREPO/camera/boot-$PROPER.tar ~/.goo/$KERNELFILE
    scp ~/.goo/$KERNELFILE $GOOSERVER/galaxycam/kernel
    rm -R ~/.goo/$KERNELFILE
    cp -r $KERNELREPO/camera/boot-$PROPER.tar.md5 ~/.goo/$KERNELFILE.md5
    scp ~/.goo/$KERNELFILE.md5 $GOOSERVER/galaxycam/kernel
    rm -R ~/.goo/$KERNELFILE.md5
fi

cd $KERNELSPEC
