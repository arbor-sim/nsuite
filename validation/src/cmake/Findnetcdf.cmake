find_package(PkgConfig REQUIRED)

foreach(dir "$ENV{NETCDF_DIR}" "$ENV{HDF5_DIR}")
    set(ENV{PKG_CONFIG_PATH} "${dir}/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}")
endforeach()

pkg_check_modules(netcdf REQUIRED IMPORTED_TARGET netcdf)
