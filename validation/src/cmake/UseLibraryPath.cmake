# Append LIBRARY_PATH environment variable paths to CMAKE_LIBRARY_PATH
# so that find_library() will Do The Right Thing.

file(TO_CMAKE_PATH "$ENV{LIBRARY_PATH}" env_lib_path_)
list(APPEND CMAKE_LIBRARY_PATH ${env_lib_path_})

