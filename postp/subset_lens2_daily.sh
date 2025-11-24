i=0
j=0
while read mem; do
    while read year; do
	((i++))
	if [[ $i == 11 || $i == 1 ]]; then
	    i=1
	    ((j++))
	    num=$(printf %03d $j)
	    job="cesm2.foco.daily."$num".job"
	    sed 's/num/'$num'/g' subset_lens2_daily.template > $job
	fi
	line="python lens2_subset_foco_daily.py "$year" "$mem
	echo $line >> $job
	if [[ $i == 10 ]]; then
	    qsub $job
	fi
    done < lens2.years
done < lens2.mems
