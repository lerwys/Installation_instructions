#!/bin/bash

# this Script is resolve mux_server error while building ltib on 11.10 host

# CMC LTD --2012
# GPL
# vijaykumar.pulluri@gmail.com

# Please go through the Readme file provided in the directory before running these Script files.

# variables

ltibPath=".../ltib"
FILE="mux_server.spec"
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
specPath="$ltibPath/dist/lfs-5.1/mux_server"
# Replacing the specfiles
sudo rm -rf $specPath/mux_server.spec
cp $FILE $specPath/mux_server.spec
echo "SPEC FILES DONE"
echo "Please delete mux_server folder if any present in /opt/freescale/ltib/usr/src/rpm/BUILD/ "

# Provides link if running on a 64bit host
if uname -a|grep -sq 'x86_64'; then
	if [ ! -e /usr/include/sys ]; then
		sudo ln -s /usr/include/x86_64-linux-gnu/sys /usr/include/sys
	fi
fi


