cmake_minimum_required(VERSION 3.9)
project(arbor-rc-exp2syn-spike LANGUAGES CXX)

find_package(arbor REQUIRED)

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/../cmake")
find_package(netcdf REQUIRED)

add_executable(arbor-rc-exp2syn-spike arbor-rc-exp2syn-spike.cpp)
target_link_libraries(arbor-rc-exp2syn-spike arbor::arbor PkgConfig::netcdf)

install(TARGETS arbor-rc-exp2syn-spike DESTINATION bin)

