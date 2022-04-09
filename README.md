# root-free
Execute operations without root privilege in linux.

## apt install without root
- Shell is in file [apt-no-root.sh](apt-install/apt-no-root.sh)

- Usage:  
./apt-no-root.sh <package>

- Example:  
./apt-no-root.sh httping  
./apt-no-root.sh dstat  
./apt-no-root.sh glances  

- After install, update envs to effective:  
source ~/.profile

- How to modify the default installed values?  
search comments "modify according to" in the script and do your modify.  
e.g. package install base dir is hold by the var BUILD_DIR (default is $HOME/root-free)

- How to add source repositories without root privilege?  
copy /etc/apt/sources.list to the same dir as this script in  
add your soruce repositories to it.

- How to add gpg key without root privilege?  
gpg --keyserver <key server> --recv-keys <keyid>  
gpg --export keyid > trusted.gpg (place it to dir same as this script in)  
or download key file (e.g. wget https://mariadb.org/mariadb_release_signing_key.asc)  
gpg --import mariadb_release_signing_key.asc  
example (add mariadb source repository gpg key):  
gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xF1656F24C74CD1D8  
gpg --export 0xF1656F24C74CD1D8 > ./trusted.gpg  


## yum install without root
