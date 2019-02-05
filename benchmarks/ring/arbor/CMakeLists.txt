cmake_minimum_required(VERSION 3.9)
project(arbor-ring LANGUAGES CXX)

# When arbor PR is in, this will become find_package(arbor REQUIRED MPI)
find_package(arbor REQUIRED)

add_executable(ring ring.cpp)
target_link_libraries(ring PRIVATE arbor::arbor arbor::arborenv)
target_include_directories(ring PRIVATE ../../../common/cpp/include)

set_target_properties(ring PROPERTIES OUTPUT_NAME run)

install(TARGETS ring DESTINATION ${CMAKE_INSTALL_PREFIX})
