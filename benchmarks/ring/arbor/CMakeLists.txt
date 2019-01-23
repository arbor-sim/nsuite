cmake_minimum_required(VERSION 3.9)
project(arbor-ring LANGUAGES CXX)

# When arbor PR is in, this will become find_package(arbor REQUIRED MPI)
find_package(arbor REQUIRED)

add_executable(ring ring.cpp)
target_link_libraries(ring PRIVATE arbor::arbor)

find_library(sup_lib_path
             NAMES arborsup
             PATHS ${CMAKE_PREFIX_PATH}
             PATH_SUFFIXES lib)
if (NOT sup_lib_path)
    message(FATAL_ERROR "Unable to find Arbor sup library")
endif()
target_link_libraries(ring PUBLIC ${sup_lib_path})

set_target_properties(ring PROPERTIES OUTPUT_NAME run)

install(TARGETS ring DESTINATION ${CMAKE_INSTALL_PREFIX})
