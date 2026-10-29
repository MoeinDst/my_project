#!/bin/bash                                                                                                                                      

source ~/.my_bashrc
echo $PATH
echo $LD_LIBRARY_PATH

mkdir -p log_files

./jobcomp --jobs 16 | tee log_files/compile_swash2DV_dx1cm_B2_Rog_frequent.log

mkdir -p PISCES
mv namelist_* kRGB61.txt* PISCES/
