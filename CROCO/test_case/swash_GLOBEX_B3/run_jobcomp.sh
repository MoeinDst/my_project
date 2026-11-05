#! /bin/bash                                                                    

source ~/.my_bashrc
echo $PATH
echo $LD_LIBRARY_PATH

mkdir -p log_files PISCES_NAMELIST/

MAKEFLAGS="-j10" ./jobcomp tee log_files/compile_swash_GLOBEX_B3.log

rm -rf  kRGB61.txt* namelist_* PISCES_NAMELIST MUSTANG_NAMELIST               
#mv kRGB61.txt* namelist_* PISCES_NAMELIST/
