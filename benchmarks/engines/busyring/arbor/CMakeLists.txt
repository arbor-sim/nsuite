cmake_minimum_required(VERSION 3.9)
project(arbor-ring LANGUAGES CXX)

find_package(CUDAToolkit)
set (CMAKE_CXX_STANDARD 17)

enable_language(CUDA)

find_package(arbor REQUIRED)

add_executable(ring ring.cpp)
target_link_libraries(ring PRIVATE ${CUDA_LIBRARIES})
target_link_libraries(ring PRIVATE arbor::arbor arbor::arborenv)

target_include_directories(ring PRIVATE ../../../../common/cpp/include)

set_target_properties(ring PROPERTIES OUTPUT_NAME arbor-busyring)

install(TARGETS ring DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
