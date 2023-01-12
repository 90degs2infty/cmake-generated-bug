option(TRIGGER_WRONG_SEARCH "Trick CMake into searching in the wrong directory" OFF)

function(is_generated var source target)
    get_target_property(_target_source_dir ${target} SOURCE_DIR)
    get_target_property(_target_binary_dir ${target} BINARY_DIR)

    set(_generated)

    cmake_path(ABSOLUTE_PATH source BASE_DIRECTORY "${_target_binary_dir}" NORMALIZE OUTPUT_VARIABLE _generated_candidate)
    if(TRIGGER_WRONG_SEARCH)
        # Query the GENERATED property to determine, whether the given file is a generated one.
        get_source_file_property(_generated "${_generated_candidate}" TARGET_DIRECTORY "${target}" GENERATED)
    else()
        # To avoid querying the GENERATED property, hard-code the distinction between generated
        # and non-generated files for this toy-example.
        if(source STREQUAL "bar.h")
            set(_generated TRUE)
        else()
            set(_generated FALSE)
        endif()
    endif()

    set(${var} "${_generated}" PARENT_SCOPE)
endfunction()
