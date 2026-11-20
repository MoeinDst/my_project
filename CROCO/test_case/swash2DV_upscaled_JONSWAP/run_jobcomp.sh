#! /bin/bash

source ~/.my_bashrc
echo $PATH
echo $LD_LIBRARY_PATH

mkdir log_files Output

./jobcomp --jobs 16 | tee log_files/compile_swash2DV_upscaled_corrected_JONSWAP.log

rm -rf kRGB61.txt* namelist_* MUSTANG_NAMELIST
