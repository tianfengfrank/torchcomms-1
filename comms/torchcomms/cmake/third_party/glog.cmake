# Copyright (c) Meta Platforms, Inc. and affiliates.

include_guard(GLOBAL)

# When CONDA_INCLUDE has glog, use it as an INTERFACE (header-only) target.
# The NCCLX build installs glog into CONDA_PREFIX; libtorchcomms.so links it
# privately and consumer extensions resolve symbols via DT_NEEDED.
#
# Otherwise, find_package or FetchContent-build glog as a static library.
if(EXISTS "${CONDA_INCLUDE}/glog/logging.h")
    add_library(glog::glog INTERFACE IMPORTED GLOBAL)
    set_target_properties(glog::glog PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${CONDA_INCLUDE}"
        INTERFACE_LINK_LIBRARIES "${CONDA_LIB}/libglog.a"
    )
else()
    find_package(glog 0.7.1 QUIET CONFIG NO_CMAKE_PACKAGE_REGISTRY)
    if(glog_FOUND)
        message(STATUS "Found system glog: ${glog_VERSION}")
    else()
        message(STATUS "System glog not found, fetching v0.7.1 via FetchContent")
        include(FetchContent)
        # Use v0.7.1 which has proper CMake support (v0.4.0 uses autoconf).
        set(WITH_GFLAGS OFF CACHE BOOL "" FORCE)
        set(WITH_GTEST OFF CACHE BOOL "" FORCE)
        set(WITH_UNWIND OFF CACHE BOOL "" FORCE)
        set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
        set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
        FetchContent_Declare(
            glog
            GIT_REPOSITORY https://github.com/google/glog.git
            GIT_TAG v0.7.1
            EXCLUDE_FROM_ALL
        )
        FetchContent_MakeAvailable(glog)
        message(STATUS "Built glog v0.7.1 from source (static)")
    endif()
endif()
