add_custom_command(
    OUTPUT bar.h
    COMMAND cp "${CMAKE_CURRENT_SOURCE_DIR}/bar.h.in" "${CMAKE_CURRENT_BINARY_DIR}/bar.h"
)

add_library(
    foo
    bar.h
    bar.cpp
)

is_generated(_gen_cpp bar.cpp foo)
message(STATUS "bar.cpp is generated: ${_gen_cpp}")

is_generated(_gen_h bar.h foo)
message(STATUS "bar.h is generated: ${_gen_h}")
