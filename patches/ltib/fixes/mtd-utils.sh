#!/bin/bash

# this Script is resolve mtd-utils error.during building ltib  on Ubuntu 11.10 host
# this error is due to provided newer mtd-utils.spec which are the reason for error so switch back to older one

# CMC LTD --2012
#GPL
# vijaykumar.pulluri@gmail.com 

# Please go through the Readme file provided in the directory before running these Script files. 

# variables

ltibPath="..../ltib"
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
# making use of old spec
mv $ltibPath/dist/lfs-5.1/mtd-utils/mtd-utils.spec $ltibPath/dist/lfs-5.1/mtd-utils/mtd-utils-201006.spec
ln -s $ltibPath/dist/lfs-5.1/mtd-utils/mtd-utils-20060302.spec $ltibPath/dist/lfs-5.1/mtd-utils/mtd-utils.spec
echo "DONE"
echo "Please delete mtd-utils folder if any present in /opt/freescale/ltib/usr/src/rpm/BUILD/ "

# Provides link if running on a 64bit host
if uname -a|grep -sq 'x86_64'; then
	if [ ! -e /usr/include/sys ]; then
		sudo ln -s /usr/include/x86_64-linux-gnu/sys /usr/include/sys
	fi
fi


