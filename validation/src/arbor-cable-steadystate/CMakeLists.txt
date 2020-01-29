cmake_minimum_required(VERSION 3.9)
project(arbor-cable-steadystate LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 14)

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/../cmake")
include(UseLibraryPath)

find_package(arbor REQUIRED)
find_package(netcdf REQUIRED)

add_executable(arbor-cable-steadystate arbor-cable-steadystate.cpp)
target_link_libraries(arbor-cable-steadystate arbor::arbor netcdf::netcdf)
target_include_directories(arbor-cable-steadystate PRIVATE ${CMAKE_SOURCE_DIR}/../include)

install(TARGETS arbor-cable-steadystate DESTINATION bin)

