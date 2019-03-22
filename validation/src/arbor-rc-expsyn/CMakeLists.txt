cmake_minimum_required(VERSION 3.9)
project(arbor-rc-expsyn LANGUAGES CXX)

set (CMAKE_CXX_STANDARD 14)

find_package(PkgConfig REQUIRED)
pkg_check_modules(netcdf REQUIRED IMPORTED_TARGET netcdf)

find_package(arbor REQUIRED)
find_package(netcdf REQUIRED)

add_executable(arbor-rc-expsyn arbor-rc-expsyn.cpp)
target_link_libraries(arbor-rc-expsyn arbor::arbor netcdf::netcdf)

install(TARGETS arbor-rc-expsyn DESTINATION bin)

