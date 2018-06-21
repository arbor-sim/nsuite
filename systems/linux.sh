# fragile tests to see whether MPI compiler is available

export with_mpi=false

which mpicc &> /dev/null
if [ $? = 0 ]
then
    which mpic++ &> /dev/null
    if [ $? = 0 ]
    then
        export with_mpi=true
        export CC=`which mpicc`
        export CXX=`which mpic++`
        msg "Compiling with MPI"
        msg "  MPI C  : $CC"
        msg "  MPI C++: $CXX"
    fi
fi

