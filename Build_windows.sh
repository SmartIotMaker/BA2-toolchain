#!/bin/bash

REVISION=r36379

BUILDDIR=/tmp/ba-elf-ba2-$REVISION


echo "Building for Windows in $BUILDDIR"
./Build.sh $BUILDDIR i686-pc-mingw32
if [ "$?" -ne "0" ]; then  echo "Build failed!"; exit 1; fi

echo "Removing Linux specific files"
rm -f $BUILDDIR/bin/jp3

echo "Copying Windows dependencies"

LIBS_DIR=`i686-pc-mingw32-gcc -print-search-dirs | grep install | cut -d " " -f 2`

cp $LIBS_DIR/*.dll $BUILDDIR/ba-elf/bin/

rsync -av ba-elf-ba2-win32/ $BUILDDIR

cd /tmp && zip -r ba-elf-ba2-$REVISION.zip ba-elf-ba2-$REVISION


