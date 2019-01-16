fid="$1"
if [ ! -f "$fid" ]; then
    echo !!!! ERROR: file $fid does not exist
else
    tts=`awk '/^model-run/ {print $2}' $fid`
    ncell=`awk '/^cell stats/ {print $3}' $fid`
    ncomp=`awk '/^cell stats/ {print $7}' $fid`
    cell_rate=`echo "$ncell/$tts" | bc -l`

    printf "%7d%12d%12.3f%12.1f" $ncell $ncomp $tts $cell_rate

    mempos=`awk '/^meter / {j=-1; for(i=1; i<=NF; ++i) if($i =="memory(MB)") j=i; print j}' $fid`
    nranks=`awk '/^ranks:/ {print $2}' $fid`
    if [ "$mempos" != "-1" ]
    then
        rankmem=$(awk "/^meter-total/ {print \$$mempos}" $fid)
        totalmem=`echo $rankmem*$nranks | bc -l`
        cellmem=`echo $totalmem/$ncell | bc -l`
        printf "%12.3f%12.3f" $totalmem $cellmem
    else
        printf "%12s%12s" '-' '-'
    fi

    printf "\n"
fi
