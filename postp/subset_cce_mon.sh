
for year in "2020" "1850" "2090"; do
    for i in {0..29}; do
        job="cce.foco."$year"."$i".job"
        sed "s/year/"$year"/g" subset_cce_mon.template > $job
        sed -i "s/mem/"$i"/g" $job
	qsub $job
    done
done
