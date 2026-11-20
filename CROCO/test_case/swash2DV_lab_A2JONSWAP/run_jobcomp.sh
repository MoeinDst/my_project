#! /bin/bash

source ~/.my_bashrc
echo $PATH
echo $LD_LIBRARY_PATH

#mkdir log_files Output

MAKEFLAGS="-j10" ./jobcomp tee log_files/compile_swash2DV_dx1cm_B2.log

rm -rf  kRGB61.txt* namelist_* PISCES_NAMELIST MUSTANG_NAMELIST
