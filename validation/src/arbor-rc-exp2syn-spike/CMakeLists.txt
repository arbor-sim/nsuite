cmake_minimum_required(VERSION 3.9)
project(arbor-rc-exp2syn-spike LANGUAGES CXX)

find_package(PkgConfig REQUIRED)
pkg_check_modules(netcdf REQUIRED IMPORTED_TARGET GLOBAL netcdf)

find_package(arbor REQUIRED)
add_executable(arbor-rc-exp2syn-spike arbor-rc-exp2syn-spike.cpp)
target_link_libraries(arbor-rc-exp2syn-spike arbor::arbor PkgConfig::netcdf)

install(TARGETS arbor-rc-exp2syn-spike DESTINATION bin)

