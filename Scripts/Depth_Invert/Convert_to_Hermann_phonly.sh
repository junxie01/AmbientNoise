#!/bin/bash

#RMS 2017
#This should be inside the dispersion curves directory

datadir=/home/rmartinshort/Documents/Berkeley/Ambient_Noise/Depth_invert/phase_data/400

if [ ! -d $datadir ]; then
    echo "Directory $datadir does not exist!"
    exit 1
fi


cwd=`pwd`
cd $datadir

dbname=Alaska_ALL.db
odir=../../ForHermannInvert_ALL_grid_final

if [ -d $odir ]; then

	echo 'Deleting existing output dir'
	rm -r $odir
fi

mkdir -p $odir

echo $dbname > params_herm.in
echo $odir >> params_herm.in


/home/rmartinshort/Documents/Berkeley/Ambient_Noise/AmbientNoise/src/To_Hermann/bin/dispersion_db_to_hermann_phv.exe params_herm.in


#Compress the full directory for ease of copying -takes a long time!
#cd ../
#echo "Compressing grid point directory"
#tar -zcvf ForHermanInvert.tar.gz ForHermannInvert
#echo "Done!"

cd $cwd
