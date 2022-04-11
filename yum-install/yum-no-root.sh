#!/bin/bash

########################################################
# install package without root privilege in centos
# fork from https://gist.github.com/StoneMoe/3f82320ce365068ef289b7bd1876c84e
# it's logic source https://stackoverflow.com/questions/36651091/how-to-install-packages-in-linux-centos-without-root-user-with-automatic-depen
######################################s##################

# - Usage:  
# ./yum-no-root.sh package

# - Example:  
# ./yum-no-root.sh httping  
# ./yum-no-root.sh glances  

# - After install, update envs to effective:  
# source ~/.bash_profile

# - The install log in file install.log.

# - How to modify the default installed values?  
# search comments "modify according to" in the shell and do your modify.  
# e.g. package install base dir is hold by the var BUILD_DIR (default is $HOME/root-free)

# - How to add source repositories without root privilege?  
# add your soruce repositories to yum.conf in dir of the shell

# - Install success but unable to run or output error?  
# check if source ~/.bash_profile executed  
# check PATH (can add more path modify the shell)  
# check LD_LIBRARY_PATH  
# check PYTHONPATH  
# check need to set more env about paths  

pkgname=$1

if [ -z $pkgname ]; then
	echo "Usage: ./yum-no-root.sh <package>"
	exit 1
fi

## modify according to your intention
BUILD_DIR=$HOME/root-free
HOME_BIN=$BUILD_DIR/bin
HOME_SBIN=$BUILD_DIR/sbin

## modify according to your package's dependencies
HOME_PYTHON_PATH=$BUILD_DIR/usr/lib/python3/dist-packages

HOME_USR_BIN=$BUILD_DIR/usr/bin
HOME_USR_SBIN=$BUILD_DIR/usr/sbin
HOME_USR_SHARE=$BUILD_DIR/usr/share
HOME_USR_LIB=$BUILD_DIR/usr/lib
HOME_USR_LIB64=$BUILD_DIR/usr/lib64
HOME_LIB=$BUILD_DIR/lib
HOME_LIB64=$BUILD_DIR/lib64

PROFILE_FILE=$HOME/.bash_profile

LOG_FILE=install.log


# update env to $PROFILE_FILE
PATH_EXPORTED=`grep $HOME_USR_BIN $PROFILE_FILE | grep "export PATH"`
if [[ $PATH_EXPORTED == "" ]]; then
  echo export PATH=\$PATH:$HOME_BIN:$HOME_SBIN:$HOME_USR_BIN:$HOME_USR_SBIN:$HOME_USR_SHARE: >>  $PROFILE_FILE
fi

LD_LIBRARY_PATH_EXPORTED=`grep $HOME_USR_LIB $PROFILE_FILE | grep "export LD_LIBRARY_PATH"`
if [[ $LD_LIBRARY_PATH_EXPORTED == "" ]]; then
  echo export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$HOME_USR_LIB:$HOME_USR_LIB64:$HOME_LIB:$HOME_LIB64 >>  $PROFILE_FILE
fi

PYTHON_PATH_EXPORTED=`grep $HOME_PYTHON_PATH $PROFILE_FILE | grep "export PYTHONPATH"`
if [[ $PYTHON_PATH_EXPORTED == "" ]]; then
  echo export PYTHONPATH=$PYTHONPATH:$HOME_PYTHON_PATH: >>  $PROFILE_FILE
fi


rand=$(openssl rand -base64 6)

# Download RPM pkg
mkdir -p /tmp/rpmpkgs_$rand
yumdownloader -c ./yum.conf --destdir /tmp/rpmpkgs_$rand --resolve $pkgname

# Extract
mkdir -p $BUILD_DIR
cd $BUILD_DIR
for rpmfile in `ls /tmp/rpmpkgs_${rand}`; do
	rpm2cpio /tmp/rpmpkgs_${rand}/${rpmfile} | cpio -idv
done

# start logging
echo "building logfile"
echo "-------START NEW INSTALL-----" >> ./$LOG_FILE
echo "install date:" >> ./$LOG_FILE
date >> ./$LOG_FILE
echo "system:"
uname -a >> ./$LOG_FILE
echo "user:"
echo "$USER" >> ./$LOG_FILE
echo "user home:"
echo "$HOME" >> ./$LOG_FILE
echo "install details" >> ./$LOG_FILE
echo "package:" >> ./$LOG_FILE
echo "$pkgname" >> ./$LOG_FILE
echo "build dir:"  >> ./$LOG_FILE
echo "$BUILD_DIR"  >> ./$LOG_FILE
echo "cahche_dir:" >> ./$LOG_FILE
echo "$APT_CACHE_DIR" >> ./$LOG_FILE
echo "source list dir:" >> ./$LOG_FILE
echo "$APT_SOURCELIST_DIR" >> ./$LOG_FILE
echo "-------END NEW INSTALL------" >> ./$LOG_FILE
echo "install details saved to logfile"
echo "TIP: to see the log file type cat $LOG_FILE"
echo " All done :-)"
