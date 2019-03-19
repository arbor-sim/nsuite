# Wrap FindPkgConfig to make an NetCDF interface target netcdf::netcdf.

find_package(PkgConfig REQUIRED)

foreach(dir "$ENV{NETCDF_DIR}" "$ENV{HDF5_DIR}")
    set(ENV{PKG_CONFIG_PATH} "${dir}/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}")
endforeach()

pkg_check_modules(netcdf netcdf)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(netcdf
  FOUND_VAR netcdf_FOUND
  REQUIRED_VARS netcdf_LDFLAGS
  VERSION_VAR netcdf_VERSION
)

if(netcdf_FOUND AND NOT TARGET netcdf::netcdf)
    # Create interface library directly from recorded pkgconfig output
    # to help avoid issues with 1) FindPkgConfig's use of find_library
    # and 2) the 'GLOBAL' flag only being a very recent addition to
    # pkg_check_modules().

    add_library(netcdf::netcdf INTERFACE IMPORTED GLOBAL)
    target_link_libraries(netcdf::netcdf INTERFACE ${netcdf_LDFLAGS})
    target_include_directories(netcdf::netcdf INTERFACE ${netcdf_INCLUDE_DIRS})
    target_compile_options(netcdf::netcdf INTERFACE ${netcdf_CFLAGS_OTHER})
endif()

