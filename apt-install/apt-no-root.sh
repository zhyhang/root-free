#!/usr/bin/env bash

########################################################
# install package without root privilege in debian
# fork from https://github.com/0x00009b/pkget
######################################s##################

# - Usage:  
# ./apt-no-root.sh <package>

# - Example:  
# ./apt-no-root.sh httping  
# ./apt-no-root.sh dstat  
# ./apt-no-root.sh glances  

# - After install, update envs to effective:  
# source ~/.profile

# - How to modify the default installed values?  
# search comments "modify according to" in the script and do your modify.  
# e.g. package install base dir is hold by the var BUILD_DIR (default is $HOME/root-free)

# - How to add source repositories without root privilege?  
# copy /etc/apt/sources.list to the same dir as this script in  
# add your soruce repositories to it.

# - How to add gpg key without root privilege?  
# gpg --keyserver <key server> --recv-keys <keyid>  
# gpg --export keyid > trusted.gpg (place it to dir same as this script in)  
# or download key file (e.g. wget https://mariadb.org/mariadb_release_signing_key.asc)  
# gpg --import mariadb_release_signing_key.asc  
# example (add mariadb source repository gpg key):  
# gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xF1656F24C74CD1D8  
# gpg --export 0xF1656F24C74CD1D8 > ./trusted.gpg  

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
mkdir -p $APT_SOURCELIST_DIR

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
echo "-------START NEW INSTALL-----" >> apt-no-root.log
echo "install date:" >> apt-no-root.log
date >> apt-no-root.log
echo "system:"
uname -a >> apt-no-root.log
echo "user:"
echo "$USER" >> apt-no-root.log
echo "user home:"
echo "$HOME" >> apt-no-root.log
echo "install details" >> apt-no-root.log
echo "package:" >> apt-no-root.log
echo "$PACKAGE" >> apt-no-root.log
echo "build dir:"  >> apt-no-root.log
echo "$BUILD_DIR"  >> apt-no-root.log
echo "cahche_dir:" >> apt-no-root.log
echo "$APT_CACHE_DIR" >> apt-no-root.log
echo "source list dir:" >> apt-no-root.log
echo "$APT_SOURCELIST_DIR" >> apt-no-root.log
echo "-------END NEW INSTALL------" >> apt-no-root.log
echo "install details saved to logfile"
echo "TIP: to see the log file type cat apt-no-root.log"
echo " All done :-)"
