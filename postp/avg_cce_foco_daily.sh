indir='/glade/derecho/scratch/djk2120/postp/cce/daily/'
outdir='/glade/derecho/scratch/djk2120/postp/cce/daily_avg/'

for year in 2020 1850 2090; do
    job='avg_foco_'$year'.job'
    sed 's/year/'$year'/g' avg_cce_foco.template > $job
    sed -i 's:indir:'$indir':g' $job
    sed -i 's:outdir:'$outdir':g' $job
    qsub $job
done
