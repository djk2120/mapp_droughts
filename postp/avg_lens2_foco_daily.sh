indir='/glade/derecho/scratch/djk2120/postp/lens2/daily/'
outdir='/glade/derecho/scratch/djk2120/postp/lens2/daily_avg/'

while read year; do
    job='avg_foco_'$year'.job'
    echo $year
done<lens2.years
