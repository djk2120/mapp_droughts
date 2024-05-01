#!/bin/bash
#PBS -N jobname
#PBS -q regular
#PBS -l walltime=1:00:00
#PBS -A P93300641
#PBS -j oe
#PBS -k eod
#PBS -l select=1:ncpus=1
#PBS -W depend=afterok:jobid

wd=$(pwd)
exp='nudge2020era5_i04_s2010to2030'
pdir='/glade/u/home/djk2120/mapp_droughts/cce/params/paramfiles/'
pkey='zqz'

filename=$(basename $pdir$pkey*)
extension="${filename##*.}"
pfile=$pdir$filename

basecases='/glade/u/home/djk2120/mapp_droughts/cce/2020/runs/nudge2020era5_i04_s2010to2030/'
cases='/glade/u/home/djk2120/mapp_droughts/cce/params/runs/'$pkey'/'
CESMROOT="/glade/work/islas/cesm2.1.4-rc.08/"

cd $basecases
i=0
for c0 in *; do 
    ((i++))
    c1=$(echo $c0 | sed 's/'$exp'/'$exp'.'$pkey'/g')

    oldcase=$basecases$c0
    newcase=$cases$c1

    cd $CESMROOT/cime/scripts
    ./create_clone --clone $oldcase --case $newcase --project P93300041 --keepexe

    cd $newcase
    ./case.setup

    if [ $extension == 'txt' ]; then
	#param is controlled via namelist directly
	cat $pfile >> user_nl_clm
    else
	#param is on the paramfile
	#echo "paramfile='"$pfile"'" >> user_nl_clm
	sed -i 's/base.nc/'$filename'/g' user_nl_clm
    fi

    ./xmlchange PROJECT="P93300041"
    ./xmlchange JOB_QUEUE="economy"
    ./xmlchange JOB_WALLCLOCK_TIME="6:00:00" --subgroup=case.run
    ./case.submit

    if [[ $i -eq 20 ]]; then
	X=$(./xmlquery JOB_IDS)
	arrX=(${X//:/ })
	j=${arrX[-1]} #save the last jobid
    fi

done


#tack on another submission, if desired
cd $wd
nx=$(wc -l < plist.txt)
if [[ $nx -gt 0 ]]; then
    p=$(head -n 1 plist.txt)
    tail -n +2 plist.txt > plist.tmp
    mv plist.tmp plist.txt
    
    f=$p".sh"

    sed '0,/jobname/{s/jobname/'$p'/}' psetup.sh > $f
    sed -i '0,/zqz/{s/zqz/'$p'/}' $f
    sed -i '0,/jobid/{s/jobid/'$j'/}' $f
else
    rm plist.txt
fi
