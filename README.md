# root-free
Execute operations without root privilege in linux.

## apt install without root
- Download the shell [apt-no-root.sh](apt-install/apt-no-root.sh)

- Prepare  
cp /etc/apt/sources.list path_of_apt-no-root.sh  
cd path_of_apt-no-root.sh ; chmod +x apt-no-root.sh  

- Usage:  
./apt-no-root.sh package-list

- Example:  
./apt-no-root.sh httping  dstat  
./apt-no-root.sh glances  

- After install, update envs to effective:  
source ~/.profile

- The install log in file install.log.

- How to modify the default installed values?  
search comments "modify according to" in the shell and do your modify.  
e.g. package install base dir is hold by the var BUILD_DIR (default is $HOME/root-free)

- How to add source repositories without root privilege?  
add your soruce repositories to local sources.list in dir of the shell

- How to add gpg key without root privilege?  
gpg --keyserver key_server --recv-keys keyid  
gpg --export keyid > trusted.gpg (place it to dir same as the shell in)  
or download key file (e.g. wget https://mariadb.org/mariadb_release_signing_key.asc)  
gpg --import mariadb_release_signing_key.asc  
example (add mariadb source repository gpg key):  
gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xF1656F24C74CD1D8  
gpg --export 0xF1656F24C74CD1D8 > ./trusted.gpg  

- Install success but unable to run or output error?  
check if source ~/.profile executed  
check PATH (can add more path modify the shell)  
check LD_LIBRARY_PATH  
check PYTHONPATH  
check need to set more env about paths  

## yum install without root
