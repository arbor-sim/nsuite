cmake_minimum_required(VERSION 3.9)
project(arbor-rc-expsyn LANGUAGES CXX)

find_package(PkgConfig REQUIRED)
pkg_check_modules(netcdf REQUIRED IMPORTED_TARGET GLOBAL netcdf)

find_package(arbor REQUIRED)
add_executable(arbor-rc-expsyn arbor-rc-expsyn.cpp)
target_link_libraries(arbor-rc-expsyn arbor::arbor PkgConfig::netcdf)

install(TARGETS arbor-rc-expsyn DESTINATION bin)

