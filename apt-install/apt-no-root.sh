#!/bin/bash

########################################################
# install package without root privilege in debian
# fork from https://github.com/0x00009b/pkget
######################################s##################

# - Prepare  
# cp /etc/apt/sources.list path_of_apt-no-root.sh  
# cd path_of_apt-no-root.sh ; chmod +x apt-no-root.sh  

# - Usage:  
# ./apt-no-root.sh package

# - Example:  
# ./apt-no-root.sh httping  
# ./apt-no-root.sh dstat  
# ./apt-no-root.sh glances  

# - After install, update envs to effective:  
# source ~/.profile

# - The install logs in file apt-no-root.log.

# - How to modify the default installed values?  
# search comments "modify according to" in the shell and do your modify.  
# e.g. package install base dir is hold by the var BUILD_DIR (default is $HOME/root-free)

# - How to add source repositories without root privilege?  
# add your soruce repositories to local sources.list in dir of the shell

# - How to add gpg key without root privilege?  
# gpg --keyserver key_server --recv-keys keyid  
# gpg --export keyid > trusted.gpg (place it to dir same as the shell in)  
# or download key file (e.g. wget https://mariadb.org/mariadb_release_signing_key.asc)  
# gpg --import mariadb_release_signing_key.asc  
# example (add mariadb source repository gpg key):  
# gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xF1656F24C74CD1D8  
# gpg --export 0xF1656F24C74CD1D8 > ./trusted.gpg  

# - Install success but unable to run or output error?  
# check if source ~/.profile executed  
# check PATH (can add more path modify the shell)  
# check LD_LIBRARY_PATH  
# check PYTHONPATH  
# check need to set more env about paths  

# define constants
CACHE_DIR=/tmp

## modify according to your intention
BUILD_DIR=$HOME/root-free
HOME_BIN=$BUILD_DIR/bin
HOME_SBIN=$BUILD_DIR/sbin

## modify accordig to your OS arch
HOME_LIB_GNU=$BUILD_DIR/lib/x86_64-linux-gnu
# HOME_LIB_GNU=$BUILD_DIR/lib/aarch64-linux-gnu

## modify accordig to your OS arch
HOME_USR_LIB_GNU=$BUILD_DIR/usr/lib/x86_64-linux-gnu
#HOME_USR_LIB_GNU=$BUILD_DIR/usr/lib/aarch64-linux-gnu

## modify according to your package's dependencies
HOME_PYTHON_PATH=$BUILD_DIR/usr/lib/python3/dist-packages


HOME_USR_BIN=$BUILD_DIR/usr/bin
HOME_USR_SBIN=$BUILD_DIR/usr/sbin
HOME_USR_SHARE=$BUILD_DIR/usr/share
HOME_USR_LIB=$BUILD_DIR/usr/lib

PROFILE_FILE=$HOME/.profile

APT_CACHE_DIR=$CACHE_DIR/apt/cache
APT_STATE_DIR=$CACHE_DIR/apt/state

LOG_FILE=apt-no-root.log

# prepare dir
mkdir $HOME_BIN -p

# update env to .profile
PATH_EXPORTED=`grep $HOME_USR_BIN $PROFILE_FILE | grep "export PATH"`
if [[ $PATH_EXPORTED == "" ]]; then
  echo export PATH=\$PATH:$HOME_BIN:$HOME_SBIN:$HOME_USR_BIN:$HOME_USR_SBIN:$HOME_USR_SHARE:$HOME_USR_LIB: >>  $PROFILE_FILE
fi

LD_LIBRARY_PATH_EXPORTED=`grep $HOME_USR_LIB_GNU $PROFILE_FILE | grep "export LD_LIBRARY_PATH"`
if [[ $LD_LIBRARY_PATH_EXPORTED == "" ]]; then
  echo export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$HOME_USR_LIB:$HOME_USR_LIB_GNU:$HOME_LIB_GNU: >>  $PROFILE_FILE
fi

PYTHON_PATH_EXPORTED=`grep $HOME_PYTHON_PATH $PROFILE_FILE | grep "export PYTHONPATH"`
if [[ $PYTHON_PATH_EXPORTED == "" ]]; then
  echo export PYTHONPATH=$PYTHONPATH:$HOME_PYTHON_PATH: >>  $PROFILE_FILE
fi

# install specify package
echo "starting install..."
echo curent user is "$USER"
echo "---------------------"

set -e

function error() {
  echo " !     $*" >&2
  exit 1
}

function topic() {
  echo ">>> $*"
}

function indent() {
  c='s/^/       /'
  case $(uname) in
    Darwin) sed -l "$c";;
    *)      sed -u "$c";;
  esac
}

APT_OPTIONS="-o debug::nolocking=true -o dir::cache=$APT_CACHE_DIR -o dir::state=$APT_STATE_DIR"
APT_OPTIONS="$APT_OPTIONS -o dir::etc::sourcelist=./sources.list -o dir::etc::trusted=./trusted.gpg"

rm -rf $APT_CACHE
mkdir -p $APT_CACHE_DIR/archives/partial
mkdir -p $APT_STATE_DIR/lists/partial

topic "Updating apt caches"
apt $APT_OPTIONS update | indent

for PACKAGE in $*; do
  if [[ $PACKAGE == *deb ]]; then
    PACKAGE_NAME=$(basename $PACKAGE .deb)
    PACKAGE_FILE=$APT_CACHE_DIR/archives/$PACKAGE_NAME.deb

    topic "Fetching $PACKAGE"
    curl -s -L -z "$PACKAGE_FILE" -o "$PACKAGE_FILE" "$PACKAGE" 2>&1 | indent
  else
    topic "Fetching .debs for $PACKAGE"
    apt $APT_OPTIONS -y --force-yes -d install --reinstall $PACKAGE | indent
  fi
done

for DEB in $(ls -1 $APT_CACHE_DIR/archives/*.deb); do
  topic "Installing $(basename $DEB)"
  dpkg -x $DEB $BUILD_DIR
done

topic "Rewrite package-config files"
find $BUILD_DIR -type f -ipath '*/pkgconfig/*.pc' | xargs --no-run-if-empty -n 1 sed -i -e 's!^prefix=\(.*\)$!prefix='$BUILD_DIR'\1!g'

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
echo "$PACKAGE" >> ./$LOG_FILE
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
