option(TRIGGER_WRONG_SEARCH "Trick CMake into searching in the wrong directory" OFF)

# -------------------------------------
# Helper to check for genexes in a path
# -------------------------------------

# contains_genex(VAR SOURCE)
#
# Check if a given file path SOURCE contains generator expressions
# and store the result in variable VAR.
#
# Arguments:
# - VAR: the output variable holding the result of the check
#        ON, iff SOURCE contains a genex
#        OFF otherwise
# - SOURCE: the file path to check
function(contains_genex var source)

    string(GENEX_STRIP "${source}" _no_genex)

    if(source STREQUAL _no_genex)
        set(${var} OFF PARENT_SCOPE)
    else()
        set(${var} ON PARENT_SCOPE)
    endif()
endfunction()

# -------------------------------------
# Helper to check for genexes in a path
# -------------------------------------

# absolutify_source(VAR SOURCE TARGET)
#
# Turn the given SOURCE file path (which belongs to TARGET) into an absolute one.
# The absolute path is returned in variable VAR.
#
# Arguments:
# - VAR:    the output variable to return the absolute path in
# - SOURCE: the file path to convert
# - TARGET: the target to which SOURCE belongs. For generated files, the
#           GENERATED source file property of SOURCE has to be visible from
#           within the directory that introduced TARGET.
#           See https://cmake.org/cmake/help/latest/command/set_source_files_properties.html
#           and https://cmake.org/cmake/help/latest/prop_sf/GENERATED.html for details.
function(absolutify_source var source target)
    list(APPEND CMAKE_MESSAGE_CONTEXT "absolutify_source")

    get_target_property(_target_source_dir ${target} SOURCE_DIR)
    get_target_property(_target_binary_dir ${target} BINARY_DIR)

    # There are several possibilities of what we get as input in `source`.
    # See https://cmake.org/cmake/help/latest/prop_tgt/SOURCES.html for details.
    # All in all, we employ the following steps:
    # 1. If `source` contains a genex, leave it as is. Genexes are expected to evaluate to absolute paths.
    # 2. If `source` is an absolute path, leave it as is.
    # 3. For everything else (i.e. relative paths):
    # 3.1 Check for the file being known to CMake in the binary dir. If it is known and it has the GENERATED
    #     property set, this file takes precedence. Return the absolute path to the
    #     found file (relative paths for generated files are always considered to be relative to the binary dir).
    #     If not, continue with 3.2.
    # 3.2 Check for the file being present in the source dir and the binary dir (in this
    #     order). Return the absolute path to the first location that points to an existing file.
    #     The GENERATED property does not matter.

    set(_source_abs)

    # check for genexes
    contains_genex(_has_genex "${source}")

    if(_has_genex)
        # there is a genex in source, according to the documentation we
        # may assume it evaluates to an absolute path
        # (see https://cmake.org/cmake/help/latest/prop_tgt/SOURCES.html)
        set(_source_abs "${source}")
    else()
        # no genex in source, path can be both relative and absolute
        cmake_path(IS_ABSOLUTE source _is_absolute)

        if(_is_absolute)
            # source is absolute path, nothing to do except normalization
            cmake_path(NORMAL_PATH source OUTPUT_VARIABLE _source_abs)
        else()

            message(WARNING "Relative path detected: ${source}. Consider using absolute paths to silence this warning. For basic use-cases it is sufficient to prepend \"\${CMAKE_CURRENT_SOURCE_DIR}/\".")

            # Check for a generated file
            # Note: the GENERATED property has some known unexpected behaviours and maybe even bugs.
            # See the following for a discussion:
            #
            # - https://discourse.cmake.org/t/unexpected-behavior-of-the-generated-source-file-property-and-cmp0118/3821/3
            # - https://discourse.cmake.org/t/behavior-of-where-cmp0118s-value-is-used-is-ambiguous/4045
            # - https://gitlab.kitware.com/cmake/cmake/-/issues/18399
            #
            # All in all, the current way to query the GENERATED property is to use `get_source_file_property` with
            # - the absolute path the generated file (the file does not have to exist on disc yet)
            # - the absolute path to the directory in which the file is introduced to CMake (i.e. the directory in
            #   which the introducing `CMakeLists.txt` lives - out of convenience, we assume this directory is equal to
            #   the TARGET_DIRECTORY of TARGET).

            cmake_path(ABSOLUTE_PATH source BASE_DIRECTORY "${_target_binary_dir}" NORMALIZE OUTPUT_VARIABLE _generated_candidate)

            set(_generated)

            if(TRIGGER_WRONG_SEARCH)
                # Query the GENERATED property to determine, whether the given file is a generated one.
                # This is the line that should go into absolutify_source's implementation eventually.
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

            message(DEBUG "Processing ${source}")
            message(DEBUG "  candidate location for generated file: ${_generated_candidate}")

            if(_generated)
                message(DEBUG "  File is GENERATED")
                set(_source_abs "${_generated_candidate}")
            else()

                message(DEBUG "  File is NOT GENERATED.")
                # the path can be relative both to the target's source and binary directory,
                # hence we use `find_file` to search for the file
                cmake_path(GET source PARENT_PATH _source_relative)
                cmake_path(GET source FILENAME _source_filename)

                cmake_path(ABSOLUTE_PATH _source_relative BASE_DIRECTORY "${_target_source_dir}" NORMALIZE OUTPUT_VARIABLE _source_source_dir)
                cmake_path(ABSOLUTE_PATH _source_relative BASE_DIRECTORY "${_target_binary_dir}" NORMALIZE OUTPUT_VARIABLE _source_binary_dir)

                find_file(
                    _source_abs
                    "${_source_filename}"
                    PATHS "${_source_source_dir}" "${_source_binary_dir}"
                    NO_CACHE
                    REQUIRED
                    NO_DEFAULT_PATH
                )
            endif()
        endif()
    endif()

    set(${var} "${_source_abs}" PARENT_SCOPE)
endfunction()
