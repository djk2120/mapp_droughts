#!/bin/bash
CURDIR=$(pwd)
COMPSET=FHIST_BGC # note switching out SSP370 forcing with namelist
GRID=f09_f09_mg17
CESMROOT="/glade/work/islas/cesm2.1.4-rc.08/"
SSTFILE="/glade/work/islas/inputdata/MAPP/SSTs/sstice_LENS2_second50_clim2010to2030_diddled_ts.nc"  # new for this script
INITDIR="/glade/scratch/islas/MAPP/" #where I put all the initial conditions
ATMICDIR="\/glade\/scratch\/islas\/MAPP\/initdir\/atmosphere\/b.e21.BSSP370.f09_g17.generaterestarts.001.cam.i." # where I put the atmosphere IC's
#----sort out the initialization here

#-------------------------------------

CASEROOTBASE="/glade/u/home/djk2120/droughts/cce/2020/runs/nudge2020era5_i04_s2010to2030/" # where I'm storing all the case directories
SCRATCHBASE="/glade/scratch/djk2120/"

#for imem in `seq 1 20`; do
#for imem in `seq 1 1` ; do
#for imem in `seq 31 50` ; do
for imem in `seq 1 1` ; do
    memstr=`printf %03d $imem`
    casename='f.e21.FHIST_BGC.nudge2020era5_i04_s2010to2030.'$memstr
    echo $casename


    #----logic to set up initialization dates
    #----For the first 100 members choosing dates very 2nd year from
    #----2010 to 2028
    group=$(( ($imem - 1) /10 ))
    startyear=$(( 2010 + $((2*$group)) + 1 ))
    atmic=$(( 2015 + $group ))
    echo $startyear $atmic

    if [ $startyear -ge 2015 ] ; then
        expname='BSSP370smbb'
    else
        expname='BHISTsmbb'
    fi

    n10=$(( $(( $imem -1 )) /10 ))
    imem2=$(( $imem - $((10*$n10)) ))
    imem2str=`printf %03d $imem2`
    initmem=$(( 1000 + $((20*$imem2)) -9 ))'.'$imem2str
    refcase="b.e21."$expname".f09_g17.LE2-"$initmem
    echo $refcase
    #----end logic to set up initialization dates




    cd $CESMROOT/cime/scripts
    caseroot=$CASEROOTBASE$casename
    echo $caseroot



    if [ $imem == 1 ] ; then
      ./create_newcase --case $caseroot --compset $COMPSET --res $GRID --mach cheyenne --project P04010022
    else
      ./create_clone --clone $CASEROOTBASE'f.e21.FHIST_BGC.nudge2020era5_i04_s2010to2030.001' --case $caseroot --project P04010022 --keepexe 
    fi

    cd $caseroot
    ./case.setup
    ./xmlchange RUN_TYPE="hybrid"
    ./xmlchange RUN_STARTDATE="2020-04-01"
    ./xmlchange RUN_REFCASE=$refcase
    ./xmlchange RUN_REFDATE=$startyear'-04-01'
    ./xmlchange RUN_REFDIR="/glade/scratch/islas/MAPP/initdir/"$initmem'/'$startyear'-04-01-00000/'
    ./xmlchange STOP_N=9
    ./xmlchange STOP_OPTION=nmonths
    ./xmlchange JOB_QUEUE='economy'
    ./xmlchange JOB_WALLCLOCK_TIME='02:00:00' --subgroup=case.run
    
    ./xmlchange SSTICE_YEAR_ALIGN='2020'
    ./xmlchange SSTICE_YEAR_START='0'
    ./xmlchange SSTICE_YEAR_END='0'
    ./xmlchange SSTICE_DATA_FILENAME=$SSTFILE
    ./xmlchange PROJECT=P04010022


    atmicfile=$ATMICDIR$atmic'-04-01-00000.nc'
    sed s/XNCDATAX/$atmicfile/g $CURDIR/namelists/user_nl_cam > user_nl_cam
    cp $CURDIR/namelists/user_nl_clm $caseroot/user_nl_clm

    cp $CURDIR/SourceMods/src.clm/* $caseroot/SourceMods/src.clm/
    cp $CURDIR/SourceMods/src.cam/* $caseroot/SourceMods/src.cam/

    # qcmd -- ./case.build 

    # ./case.submit



done 


#cd $CESMROOT/cime/scripts

