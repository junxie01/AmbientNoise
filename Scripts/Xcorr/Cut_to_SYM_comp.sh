#!/bin/bash

#----------------------------------------------
# RMS 2017
#----------------------------------------------
#Runs the Cut to Sym comps C code


#Directory where the month stacks can be found
stackdir=/data/dna/rmartin/Ambient_noise/Alaska/DATA/COR/STACK_TEST

cwd=(`pwd`)
echo $cwd

#Go to the directry and generate a list of all the SAC files there
cd $stackdir
ls *SAC > filelist.cut

#Cut the symmetric XC and fold so that we produce a one sided XC
/data/dna/rmartin/Ambient_noise/CODES/src/Cut_to_sym_comp/bin/Cut_To_Sym_Comps.exe filelist.cut

mkdir TWO_SIDED
mkdir SYM

mv *_s SYM
mv *.SAC TWO_SIDED

cd $cwd