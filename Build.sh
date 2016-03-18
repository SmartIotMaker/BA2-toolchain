#!/bin/bash
#
#
#set -x
#
# Build script for BA2 toolchain
#
#note you need to modify the prefixes in the script to your particular folder layout for it to 
#work and add in the relevant cd to each folder between each component etc.. 
#also unless you have a dual quad core dev machine i suggest that you take 
#the '-j5' option out of the make command
#
#running order for x-compilers is
#1. make binutils so that you can build your stuff
#2. make newlibs as they need to be incorporated into gcc when you build it in part 3
#3. build gcc
#4. build gdb
#
#the basim and bamon have their own instructions which are found in the relevant readme file
#
#all you have to do then is extract it to wherever you see fit and stick it in your environment path.. 
#


# build/release no. of toolchain
RELEASENO=r36379
export RELEASENO


function usage {
    echo "Build script usage"
    echo "./Build <Prefix to installation directory> <Optional chost that the toolchain will run on>"
}

PREFIX=$1
HOST=$2

if [ "$PREFIX" = "" ]; then
    echo "You must specify the prefix to the installation directory"
    usage
    exit 1
fi

if [ -n $HOST ]; then
	echo "Building for host system type $HOST"
	HOST=--host=$HOST
fi


# Number of make processes. This should typically be set to num processors + 1
MAKEJOBS=3

# Remember where we were started
RUNDIR=`pwd`

# Export the path so that gcc can find binutils, etc
export PATH=$PREFIX/bin/:$PATH

# Initialise build log.
BUILDSTART=`date`
echo "Build started at $BUILDSTART" > $RUNDIR/build.log

###############################
# Set version numbers of components
#
BINUTILSVERSION=2.22

GCCVERSION=4.7.4

GDBVERSION=7.5.1

NEWLIBVERSION=2.0.0

GMPVERSION=4.3.2

MPFRVERSION=2.4.2

MPCVERSION=0.8.1


###############################
# Names of components

BINUTILSNAME=binutils-$BINUTILSVERSION-ba-r33675

GCCNAME=gcc-$GCCVERSION-ba-r36379

GDBNAME=gdb-$GDBVERSION-ba-r34135

JTAGNAME=jtag-r34432

NEWLIBNAME=newlib-$NEWLIBVERSION-ba-r33675

GMPNAME=gmp-$GMPVERSION

MPFRNAME=mpfr-$MPFRVERSION

MPCNAME=mpc-$MPCVERSION

LIBFTDINAME=libftdi_0.20_devkit_mingw32_08April2012

###############################
# Filenames for components

BINUTILSFILE=./$BINUTILSNAME.tar.gz

GCCFILE=./$GCCNAME.tar.gz

GDBFILE=./$GDBNAME.tar.gz

JTAGFILE=./$JTAGNAME.tar.gz

NEWLIBFILE=./$NEWLIBNAME.tar.gz

GMPFILE=./$GMPNAME.tar.bz2

MPFRFILE=./$MPFRNAME.tar.bz2

MPCFILE=./$MPCNAME.tar.gz

LIBFTDIFILE=./$LIBFTDINAME.zip

###############################
# Build direcotry names for components

BINUTILSBUILD=./$BINUTILSNAME-build

GCCBUILD=./$GCCNAME-build

NEWLIBBUILD=./$NEWLIBNAME

GDBBUILD=./$GDBNAME

JTAGBUILD=./$JTAGNAME

###############################
# Utility functions

# Clean up build directories and installation direcotry for a clean build
function build_clean {
    # Remove old source files and builds
    echo "Removing old build directories"
    rm -rf $BINUTILSBUILD $NEWLIBBUILD $GCCBUILD $GDBNAME $GDBBUILD $GCCNAME $BINUTILSNAME $JTAGNAME

    # Remove old output directory
    echo "Removing contents of installation directory"
    #rm -rf $PREFIX/*

    # Check if target prefix directory exists and create if not
    if [ ! -e "$PREFIX" ]
    then
        echo "Creating installation directory", $PREFIX    
        mkdir -p $PREFIX/bin
    fi
}

# Ensure that the installation bin directory is added to the path.
PATH=$PATH:$PREFIX/bin


# Utility function to extract an archive file.
function extract {
    FILENAME=$1
    echo $FILENAME
    
    if [ `echo $FILENAME | grep ".zip" -` ]; then
        echo "Extracting zip $FILENAME"
        unzip -o $FILENAME

    elif [ `echo $FILENAME | grep ".tar.gz" -` ]; then
        echo "Extracting gzipd tar $FILENAME"
        tar -xzvf $FILENAME

    elif [ `echo $FILENAME | grep ".tar.bz2" -` ]; then
        echo "Extracting bzipd tar $FILENAME"
        tar -xjvf $FILENAME

    fi
}


# Function to apply patches from a directory given as first parameter
function apply_patches {
    PATCH_DIR=$1
    if [ -d "$PATCH_DIR" ]; then
        status "Applying patches from $PATCH_DIR"
        for f in `ls "$PATCH_DIR"`; do
            p="$PATCH_DIR/$f"
            echo "Applying patch $p"
            patch -p0 < $p
        done
    fi
}


# Function to display status and update xterm window title as appropriate
function status {
    STATUS=$1
    echo -ne "\033]0;${STATUS}\007"
    echo $STATUS
    echo $STATUS >> $RUNDIR/build.log
}


###############################
# binutils:

function build_binutils {
    status "Extracting Binutils $BINUTILSVERSION Release $RELEASENO"
    extract $BINUTILSFILE
   
    cd $BINUTILSNAME
    # Fix up broken zip permissions
    chmod +x ./configure ./config ./missing ./mkdep ./mkinstalldirs
    chmod 660 ./config/*

    # Apply any patches
    apply_patches "../$BINUTILSNAME-patches"

    cd $RUNDIR
    rm -rf $BINUTILSBUILD
    mkdir -p $BINUTILSBUILD
    cd $BINUTILSBUILD
    
    status "Configuring Binutils $BINUTILSVERSION Release $RELEASENO in $BINUTILSBUILD"
    ../$BINUTILSNAME/configure $HOST --target=ba-elf --prefix=$PREFIX --disable-werror
    if [ "$?" -ne "0" ]; then  echo "Configure failed!"; exit 1; fi

    status "Building Binutils $BINUTILSVERSION Release $RELEASENO in $BINUTILSBUILD"
    make -j$MAKEJOBS all
    if [ "$?" -ne "0" ]; then  echo "Build failed!"; exit 1; fi

    status "Installing Binutils $BINUTILSVERSION Release $RELEASENO in $BINUTILSBUILD"
    make install
    if [ "$?" -ne "0" ]; then  echo "Install failed!"; exit 1; fi

    echo "Completed binutils build in $BINUTILSBUILD"
    cd $RUNDIR
}


###############################
# Gcc + newlib:

function build_gcc {
    status "Using Newlib version $NEWLIBVERSION"
    status "Using GMP version $GMPVERSION"
    status "Using MPFR version $MPFRVERSION"
    status "Using MPC version $MPCVERSION"
    status "Extracting GCC $GCCVERSION Release $RELEASENO"

    extract $GCCFILE
    extract $NEWLIBFILE
    extract $GMPFILE
    extract $MPFRFILE
    extract $MPCFILE
    
    # Move newlib and libgloss into gcc directory
    rm -rf $GCCNAME/newlib
    rm -rf $GCCNAME/libgloss
    rm -rf $GCCNAME/gmp
    rm -rf $GCCNAME/mpfr
    rm -rf $GCCNAME/mpc

    mv -f ./$NEWLIBNAME/newlib $GCCNAME
    mv -f ./$NEWLIBNAME/libgloss $GCCNAME
    mv -f ./$GMPNAME $GCCNAME/gmp
    mv -f ./$MPFRNAME $GCCNAME/mpfr
    mv -f ./$MPCNAME $GCCNAME/mpc
    
    cd $GCCNAME
    # Fix up broken zip permissions
    chmod +x ./configure ./config ./missing ./mkdep ./mkinstalldirs ./move-if-change
    chmod 660 ./config/*

    # Apply any patches
    apply_patches "../$GCCNAME-patches"

    cd $RUNDIR

    status "Configuring GCC $GCCVERSION Release $RELEASENO in $GCCBUILD"

    rm -rf $GCCBUILD
    mkdir -p $GCCBUILD
    cd $GCCBUILD
    ../$GCCNAME/configure $HOST --target=ba-elf --prefix=$PREFIX --enable-languages=c,c++,lto --with-gnu-as \
        --with-gnu-ld --with-newlib --enable-target-optspace --disable-libssp --disable-__cxa_atexit \
        --with-gxx-include-dir=$PREFIX/ba-elf/include
    if [ "$?" -ne "0" ]; then  echo "Configure failed!"; exit 1; fi

    status "Building GCC $GCCVERSION Release $RELEASENO in $GCCBUILD"
    make -j$MAKEJOBS all
    if [ "$?" -ne "0" ]; then  echo "Build failed!"; exit 1; fi

    status "Installing GCC $GCCVERSION Release $RELEASENO in $GCCBUILD"
    make install
    if [ "$?" -ne "0" ]; then  echo "Install failed!"; exit 1; fi

    status "Completed GCC build in $GCCBUILD"
    cd $RUNDIR
}


###############################
# GDB:

function build_gdb {
    status "Extracting GDB $GDBVERSION Release $RELEASENO"

    extract $GDBFILE
    cd $GDBNAME/

    # Apply any patches
    apply_patches "../$GDBNAME-patches"

    status "Configuring GDB $GDBVERSION Release $RELEASENO"
    ./configure $HOST --target=ba-elf --prefix=$PREFIX
    if [ "$?" -ne "0" ]; then  echo "Configure failed!"; exit 1; fi

    status "Building GDB $GDBVERSION Release $RELEASENO"
    make -j$MAKEJOBS all
    if [ "$?" -ne "0" ]; then  echo "Build failed!"; exit 1; fi

    status "Installing GDB $GDBVERSION Release $RELEASENO"
    make install
    if [ "$?" -ne "0" ]; then  echo "Install failed!"; exit 1; fi

    status "Completed GDB build"
    cd $RUNDIR
}


###############################
# JTAG:

function build_jtag {
    if uname | grep -q MINGW
    then
        status "Set up libFTDI"
        extract $LIBFTDIFILE
        cp ./$LIBFTDINAME/bin/*.dll $PREFIX/bin/
    fi
    
    status "Extracting JTAG Release $RELEASENO"

    extract $JTAGFILE
    cd $JTAGNAME/

    # Apply any patches
    apply_patches "../$JTAGNAME-patches"

    status "Configuring JTAG Release $RELEASENO"
    if uname | grep -q MINGW
    then
        CFLAGS="-I../$LIBFTDINAME/include/"
        LDFLAGS="-L../$LIBFTDINAME/lib/"
        CONFIG_ARGS=" --enable-staticlibs"
    fi

    CFLAGS=$CFLAGS LDFLAGS=$LDFLAGS ./configure --prefix=$PREFIX $CONFIG_ARGS

    if [ "$?" -ne "0" ]; then  echo "Configure failed!"; exit 1; fi

    status "Building JTAG Release $RELEASENO"
    make -j$MAKEJOBS all
    if [ "$?" -ne "0" ]; then  echo "Build failed!"; exit 1; fi

    status "Installing JTAG Release $RELEASENO"
    make install
    if [ "$?" -ne "0" ]; then  echo "Install failed!"; exit 1; fi

    status "Completed JTAG build"
    cd $RUNDIR
}


###############################
# Build each component of the toolchain:

build_clean
build_binutils
build_gcc
build_gdb
build_jtag

echo "Toolchain built successfully and installed to $PREFIX"




