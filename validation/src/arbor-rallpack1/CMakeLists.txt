cmake_minimum_required(VERSION 3.9)
project(arbor-rallpack1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 14)

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/../cmake")
include(UseLibraryPath)

find_package(arbor REQUIRED)
find_package(netcdf REQUIRED)

add_executable(arbor-rallpack1 arbor-rallpack1.cpp)
target_link_libraries(arbor-rallpack1 arbor::arbor netcdf::netcdf)
target_include_directories(arbor-rallpack1 PRIVATE ${CMAKE_SOURCE_DIR}/../include)

install(TARGETS arbor-rallpack1 DESTINATION bin)

