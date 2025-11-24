indir='/glade/derecho/scratch/djk2120/postp/lens2/daily/'
outdir='/glade/derecho/scratch/djk2120/postp/lens2/daily_avg/'

while read year; do
    job='avg_foco_'$year'.job'
    sed 's/year/'$year'/g' avg_foco.template > $job
    sed -i 's:indir:'$indir':g' $job
    sed -i 's:outdir:'$outdir':g' $job
    qsub $job
done<lens2.years
