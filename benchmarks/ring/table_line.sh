fid="$1"
echo =========== fid is $fid
if [ ! -f "$fid" ]; then
    echo !!!! ERROR: file $fid does not exist
else
    tts=`grep ^model-run $fid | awk '{print $2}'`
    ncell=`grep "^cell stats" $fid | awk '{print $3}'`
    ncomp=`grep "^cell stats" $fid | awk '{print $7}'`
    cell_rate=`echo "($ncell / 10) / $tts" | bc -l`
    echo "=== $ncell / 10 / $tts"
    echo "=== $ncell"
    echo "=== $ncomp"
    echo "=== tts $tts"
    echo "=== rate $cell_rate"

    printf "%7d%12d%12.3f%12.1f%12.1f\n" $ncell $ncomp $tts $cell_rate
fi
