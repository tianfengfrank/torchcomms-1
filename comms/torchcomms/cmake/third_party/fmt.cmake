# Copyright (c) Meta Platforms, Inc. and affiliates.

include_guard(GLOBAL)

# We need static fmt — shared libs can't be shipped in wheels.
# Check for static library first (e.g., installed by build_ncclx.sh).
# This avoids find_package creating SHARED IMPORTED targets that can't be
# rejected without a duplicate-target conflict in the FetchContent fallback.
if(EXISTS "${CONDA_LIB}/libfmt.a" AND EXISTS "${CONDA_INCLUDE}/fmt/format.h")
    add_library(fmt::fmt STATIC IMPORTED GLOBAL)
    set_target_properties(fmt::fmt PROPERTIES
        IMPORTED_LOCATION "${CONDA_LIB}/libfmt.a"
        INTERFACE_INCLUDE_DIRECTORIES "${CONDA_INCLUDE}"
    )
    message(STATUS "Using static fmt: ${CONDA_LIB}/libfmt.a")
else()
    find_package(fmt 11.2.0 QUIET CONFIG NO_CMAKE_PACKAGE_REGISTRY)
    if(fmt_FOUND)
        message(STATUS "Found system fmt: ${fmt_VERSION}")
    else()
        message(STATUS "System fmt not found, fetching 11.2.0 via FetchContent")
        include(FetchContent)
        FetchContent_Declare(
            fmt
            GIT_REPOSITORY https://github.com/fmtlib/fmt.git
            GIT_TAG 11.2.0
        )
        FetchContent_Populate(fmt)
        # Keep build artifacts in the build tree, not the source/install dir
        set(_save_archive_dir ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY})
        set(_save_lib_dir ${CMAKE_LIBRARY_OUTPUT_DIRECTORY})
        set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
        set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
        add_subdirectory(${fmt_SOURCE_DIR} ${fmt_BINARY_DIR} EXCLUDE_FROM_ALL)
        set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${_save_archive_dir})
        set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${_save_lib_dir})
    endif()
endif()
