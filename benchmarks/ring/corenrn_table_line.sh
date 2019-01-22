fid="$1"
if [ ! -f "$fid" ]; then
    echo !!!! ERROR: file $fid does not exist
else
    tts=`grep "Solver Time" $fid | awk '{print $4}'`
    ncell=`grep "Number of cells" $fid | awk '{print $4}'`
    ncomp=`grep "Number of compartments" $fid | awk '{print $4}'`
    cell_rate=`echo "$ncell/$tts" | bc -l`
    rankmem_start=`grep "After MPI_Init" $fid | awk '{print $12}'`
    rankmem_end=`grep "After nrn_finitialize" $fid | awk '{print $12}'`
    rankmem=`echo $rankmem_end-$rankmem_start | bc -l`
    ranks=`grep "num_mpi" $fid -m1 | tr -dc '0-9'`
    totalmem=`echo $rankmem*$ranks | bc -l`
    cellmem=`echo $totalmem/$ncell | bc -l`

    printf "%7d%12d%12.3f%12.1f%12.1f%12.3f\n" $ncell $ncomp $tts $cell_rate $totalmem $cellmem
fi
