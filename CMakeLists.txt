cmake_minimum_required(VERSION 3.25.1)

project(
    Foo
)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(AbsPath)

add_subdirectory(src)
