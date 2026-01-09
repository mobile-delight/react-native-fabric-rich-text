# Custom CMakeLists.txt for react-native-fabric-rich-text
#
# This file is referenced via react-native.config.js cmakeListsPath.
# It includes codegen-generated sources, custom ShadowNodes, shared C++ code,
# and libxml2 for HTML parsing.

cmake_minimum_required(VERSION 3.13)
set(CMAKE_VERBOSE_MAKEFILE on)

# ============================================================================
# libxml2 Configuration
# ============================================================================

include(FetchContent)

# Fetch libxml2 source from GitHub (more reliable than GNOME servers)
FetchContent_Declare(
  libxml2
  GIT_REPOSITORY https://github.com/GNOME/libxml2.git
  GIT_TAG v2.12.3
  GIT_SHALLOW TRUE
)

# Minimal build config for HTML parsing only
set(LIBXML2_WITH_ICONV OFF CACHE BOOL "" FORCE)
set(LIBXML2_WITH_LZMA OFF CACHE BOOL "" FORCE)
set(LIBXML2_WITH_PYTHON OFF CACHE BOOL "" FORCE)
set(LIBXML2_WITH_ZLIB OFF CACHE BOOL "" FORCE)
set(LIBXML2_WITH_TESTS OFF CACHE BOOL "" FORCE)
set(LIBXML2_WITH_PROGRAMS OFF CACHE BOOL "" FORCE)
set(LIBXML2_WITH_HTML ON CACHE BOOL "" FORCE)
set(LIBXML2_WITH_SAX1 ON CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(libxml2)

# ============================================================================
# Project Configuration
# ============================================================================

# Paths relative to this file's location (android/jni/)
set(CODEGEN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../build/generated/source/codegen/jni")
set(CUSTOM_JNI_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../src/main/jni")
set(SHARED_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../cpp")

# Codegen-generated sources (excluding ShadowNodes and States which we override)
file(GLOB codegen_root_SRCS CONFIGURE_DEPENDS "${CODEGEN_DIR}/*.cpp")
file(GLOB codegen_component_SRCS CONFIGURE_DEPENDS
    "${CODEGEN_DIR}/react/renderer/components/FabricRichTextSpec/*.cpp"
)

# Filter out files we're replacing with custom implementations
set(codegen_SRCS ${codegen_root_SRCS} ${codegen_component_SRCS})
list(FILTER codegen_SRCS EXCLUDE REGEX ".*ShadowNodes\\.cpp$")
list(FILTER codegen_SRCS EXCLUDE REGEX ".*States\\.cpp$")

# Custom ShadowNode implementation (overrides codegen)
set(custom_SRCS
    "${CUSTOM_JNI_DIR}/react/renderer/components/FabricRichTextSpec/ShadowNodes.cpp"
    "${CUSTOM_JNI_DIR}/react/renderer/components/FabricRichTextSpec/FabricRichTextState.cpp"
)

# Shared cross-platform C++ sources (HTML parser)
file(GLOB shared_cpp_SRCS CONFIGURE_DEPENDS "${SHARED_CPP_DIR}/*.cpp")

# Combine all sources
set(ALL_SRCS ${codegen_SRCS} ${custom_SRCS} ${shared_cpp_SRCS})

add_library(
    react_codegen_FabricRichTextSpec
    OBJECT
    ${ALL_SRCS}
)

target_include_directories(react_codegen_FabricRichTextSpec
    PUBLIC
    # Custom directories MUST come first to override codegen ShadowNodes.h
    ${CUSTOM_JNI_DIR}
    ${CUSTOM_JNI_DIR}/react/renderer/components/FabricRichTextSpec
    # Then codegen directories
    ${CODEGEN_DIR}
    ${CODEGEN_DIR}/react/renderer/components/FabricRichTextSpec
    # Shared C++ code
    ${SHARED_CPP_DIR}
    # libxml2 headers
    ${libxml2_SOURCE_DIR}/include
    ${libxml2_BINARY_DIR}
)

target_link_libraries(
    react_codegen_FabricRichTextSpec
    log
    fbjni
    jsi
    reactnative
    LibXml2::LibXml2
)

target_compile_reactnative_options(react_codegen_FabricRichTextSpec PRIVATE)
