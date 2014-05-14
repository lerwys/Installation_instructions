#!/bin/bash

# this Script is resolve pme_tools error while building ltib on 12.04 host

ltibPath=".../ltib"
FILE="pme_tools.spec.in"
# look for the ltib path provided or not if provided re assinging to ltibPath
if [ -n "$1" ]
then
   ltibPath=$1
fi

usage()
{
   echo "USE IN THIS WAY : ./`basename $0` <provide correct ltib path>"
   exit -1
}


# checking for the ltib directory
if [ ! -d $ltibPath ]; then
    echo "Path Not found"
    usage
fi

#defining specPath variable
specPath="$ltibPath/dist/lfs-5.1/pme_tools"
# Replacing the specfiles
sudo rm -rf $specPath/$FILE
cp $FILE $specPath/$FILE
echo "SPEC FILES DONE"

echo "PATCHING "
pkgPath="/opt/freescale/pkgs"
if [ ! -d $pkgPath ]; then
    echo "ENTERED TO CREATE DIRECTORY"
    sudo mkdir -p $pkgPath
    sudo chmod -R 777 /opt/freescale
fi
FILES="pme_tools-1.0.0-a6-pm_defs_priv.h-double-unused.patch
pme_tools-1.0.0-a6-pm_defs_priv.h-double-unused.patch.md5"
for file in $FILES
do
    cp -v $file $pkgPath
done
echo "DONE"
echo "Please delete sparse folder if any present in /opt/freescale/ltib/usr/src/rpm/BUILD/ "



