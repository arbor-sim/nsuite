fid=$1

tts=`grep ^model-run $fid | awk '{print $2}'`
ncell=`grep ^cell $fid | awk '{print $3}'`
ncomp=`grep ^cell $fid | awk '{print $7}'`
comp_sec=`echo "$ncomp / 10" | bc -l`
comp_rate=`echo "$comp_sec / $tts" | bc -l`

printf "%7d%12d%12.3f%12.1f\\n" $ncell $ncomp $tts $comp_rate
