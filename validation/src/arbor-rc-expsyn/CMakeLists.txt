cmake_minimum_required(VERSION 3.9)
project(arbor-rc-expsyn LANGUAGES CXX)

find_package(arbor REQUIRED)

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/../cmake")
find_package(netcdf REQUIRED)

add_executable(arbor-rc-expsyn arbor-rc-expsyn.cpp)
target_link_libraries(arbor-rc-expsyn arbor::arbor PkgConfig::netcdf)

install(TARGETS arbor-rc-expsyn DESTINATION bin)

