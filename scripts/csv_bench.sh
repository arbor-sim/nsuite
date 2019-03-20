usage() {
    cat <<_end_
Usage: csv-bench.sh --path=PATH [--coreneuron]

Generate CSV file summarising a set of benchmark runs.

Options:
    --path=PATH      Path containing the output
    --coreneuron     If the path contains CoreNeuron output.
_end_
    exit 1
}

parse_coreneuron=false
path=

while [ "$1" != "" ]
do
    case $1 in
        --coreneuron )
            parse_coreneuron=true
            ;;
        --path=* )
            path="${1#--path=}"
            ;;
        --path )
            shift
            path=$1
            ;;
        * )
            echo "unknown option '$1'"
            usage
    esac
    shift
done

if [ "$path" == "" ]
then
    usage
    exit 1
fi

if [ ! -d "$path" ]
then
    echo "error: path \"$path\" does not exist"
    exit 1
fi

table_line() {
    fid="$1"
    line=

    tts=$(awk '/^model-run/ {print $2}' "$fid")
    ncell=$(awk '/^cell stats/ {print $3}' "$fid")

    line=$(printf %9d,%12.3f, $ncell $tts)
    nranks=$(awk '/^ranks:/ {print $2}' "$fid")

    mempos=$(awk '/^meter / {j=-1; for(i=1; i<=NF; ++i) if($i =="memory(MB)") j=i; print j}' "$fid")
    if [ "$mempos" != "-1" ]
    then
        rankmem=$(awk "/^meter-total/ {print \$$mempos}" "$fid")
        totalmem=$(echo $rankmem*$nranks | bc -l)
        line="$line"$(printf %12.3f, $totalmem)
    else
        line="$line"$(printf %12s, '')
    fi

    nthreads=$(awk '/^threads:/ {print $2}' "$fid")
    hasgpu=$(awk '/^gpu:/ {print $2}' "$fid")
    line="$line"$(printf %7d,%7d,%7s $nranks $nthreads $hasgpu)
}

# NOTE: this is very fragile and will almost certainly break from version to
# version of CoreNeuron. There is not much we can do about that, because the
# only information we have available is whatever CoreNeuron outputs to stdout.
table_line_cnr() {
    fid="$1"

    tts=$(awk '/Solver Time/ {print $4}' "$fid")
    ncell=$(awk '/Number of cells/ {print $4}' "$fid")

    rankmem_start=$(awk '/After MPI_Init/ {print $12}' "$fid")
    rankmem_end=$(awk '/After nrn_finitialize/ {print $12}' "$fid")
    rankmem=$(echo $rankmem_end-$rankmem_start | bc -l)
    # num_mpi and num_omp_thread are printed more than once (for redundancy?)
    # So use awk to discard all but the last occurence of each variable
    nranks=$(awk -F= '/num_mpi/ {x=$2} END{print x}' "$fid")
    nthreads=$(awk -F= '/num_omp_thread/ {x=$2} END{print x}' "$fid")
    totalmem=$(echo $rankmem*$nranks | bc -l)
    # we can't run CoreNeuron with GPU for now, so always no.
    hasgpu="no"

    line=$(printf %9d,%12.3f,%12.3f,%7d,%7d,%7s $ncell $tts $totalmem $nranks $nthreads $hasgpu)
}

# Use tmp file to generate unsorted table.
tmp="$path/tmp"
results="$path/results.csv"
rm -f "$tmp"
for f in "$path"/*.out
do
    [[ "$parse_coreneuron" == "false" ]] && table_line $f
    [[ "$parse_coreneuron" == "true" ]]  && table_line_cnr $f
    echo "$line" >> "$tmp"
done
printf %9s,%12s,%12s,%7s,%7s,%7s\n \
       "cells" "wall time(s)" "memory (MB)" "ranks" "threads" "gpu" \
       > "$results"

# Sorting in ascending order of the number of cells (the first column in the output).
# The output does not have to be sorted; however sorting by the number of cells will usuall
# match the natural order of scaling benchmarks.
sort -n "$tmp" >> "$results"
rm -f "$tmp"
