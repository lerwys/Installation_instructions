#!/bin/bash

# this Script is resolve imx-lib error while building ltib on 11.10 host

# CMC LTD --2012
# GPL
# vijaykumar.pulluri@gmail.com


# Please go through the Readme file provided in the directory before running these Script files.

# variables

ltibPath=".../ltib"
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

#defining ipuPath variable
ipuPath="$ltibPath/rpm/BUILD/imx-lib-11.05.01/ipu"
FILES="mxc_ipu_hl_lib.c
mxc_ipu_lib.c"
for file in $FILES
do
    cp $file $ipuPath
done
echo "DONE"
echo "Please delete imx-lib folder if any present in /opt/freescale/ltib/usr/src/rpm/BUILD/ "

# Provides link if running on a 64bit host
if uname -a|grep -sq 'x86_64'; then
	if [ ! -e /usr/include/sys ]; then
		sudo ln -s /usr/include/x86_64-linux-gnu/sys /usr/include/sys
	fi
fi


