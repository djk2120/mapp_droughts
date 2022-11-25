#!/bin/bash

ps=('p03' 'p08' 'p09' 'p10' 'p11')
i=0
:> plist.txt
for p in ${ps[@]}; do
    ((i++))
    if [[ $i -eq 1 ]]; then
	#remove afterok for first submission
	f=$p".sh"
	sed '9d' psetup.sh > $f  
	sed -i 's/zqz/'$p'/g' $f
	sed -i 's/jobname/'$p'/g' $f
    else
	#queue up subsequent submissions
	echo $p >> plist.txt
    fi
done

qsub $f
