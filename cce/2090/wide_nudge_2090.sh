#!/bin/bash
CURDIR=$(pwd)
COMPSET=FHIST_BGC # note switching out SSP370 forcing with namelist
GRID=f09_f09_mg17
CESMROOT="/glade/work/islas/cesm2.1.4-rc.08/"
SSTFILE="/glade/u/home/djk2120/droughts/data/sstice_OBSplusLENS2_2nd50anoms_diddled_ts.nc" ##SST obs + LENS climate change
INITDIR="/glade/scratch/islas/MAPP/" #where I put all the initial conditions
ATMICDIR="/glade/scratch/islas/MAPP/initdir/atmosphere/b.e21.BSSP370.f09_g17.generaterestarts_2090.001.cam.i."

CASEROOTBASE="/glade/u/home/djk2120/mapp_droughts/cce/2090/runs/nudge2020era5_wide_i04_s2080to2100/" # where I'm storing all the case directories
SCRATCHBASE="/glade/scratch/djk2120/"

for imem in `seq 1 30` ; do
    memstr=`printf %03d $imem`
    casename='f.e21.FHIST_BGC.nudge2020era5_wide_i04_s2080to2100_sstera5.'$memstr

    echo "--------------------------------------------------------------"
    echo $casename
    echo "--------------------------------------------------------------"

    #----logic to set up initialization dates
    #----For the first 100 members choosing dates very 2nd year from
    #----2080 to 2100
    group=$(( ($imem - 1) /10 ))
    startyear=$(( 2080 + $((2*$group)) + 1 ))
    atmic=$(( 2085 + $group ))
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
    
    
    cd $CESMROOT/cime/scripts
    caseroot=$CASEROOTBASE$casename
    echo $caseroot



    if [ $imem == 1 ] ; then
      ./create_newcase --case $caseroot --compset $COMPSET --res $GRID --mach cheyenne --project P93300641
      firstcase=$caseroot
    else
      ./create_clone --clone $firstcase --case $caseroot --project P93300641 --keepexe 
    fi

    cd $caseroot
    ./case.setup
    ./xmlchange RUN_TYPE="hybrid"
    ./xmlchange RUN_STARTDATE="2090-04-01"
    ./xmlchange RUN_REFCASE=$refcase
    ./xmlchange RUN_REFDATE=$startyear'-04-01'
    ./xmlchange RUN_REFDIR="/glade/scratch/islas/MAPP/initdir/"$initmem'/'$startyear'-04-01-00000/'
    ./xmlchange STOP_N=9
    ./xmlchange STOP_OPTION=nmonths
    ./xmlchange JOB_QUEUE='regular'
    ./xmlchange JOB_WALLCLOCK_TIME='03:00:00' --subgroup=case.run
    
    ./xmlchange SSTICE_YEAR_ALIGN='2090'
    ./xmlchange SSTICE_YEAR_START='2090'
    ./xmlchange SSTICE_YEAR_END='2090'
    ./xmlchange SSTICE_DATA_FILENAME=$SSTFILE
    ./xmlchange PROJECT=P93300641


    atmicfile=$ATMICDIR$atmic'-04-01-00000.nc'
    sed 's:XNCDATAX:'$atmicfile':g' $CURDIR/namelists/user_nl_cam.wide > user_nl_cam
    cp $CURDIR/namelists/user_nl_clm $caseroot/user_nl_clm

    cp $CURDIR/SourceMods/src.clm/* $caseroot/SourceMods/src.clm/
    cp $CURDIR/SourceMods/src.cam/* $caseroot/SourceMods/src.cam/

    if [ $imem == 1 ] ; then
        ./case.build 
    fi


    ./case.submit
    
done
