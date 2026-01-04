# Custom CMakeLists.txt for react-native-fabric-html-text
#
# This file is referenced via react-native.config.js cmakeListsPath.
# It includes codegen-generated sources, custom ShadowNodes, and shared C++ code.

cmake_minimum_required(VERSION 3.13)
set(CMAKE_VERBOSE_MAKEFILE on)

# Paths relative to this file's location (android/jni/)
set(CODEGEN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../build/generated/source/codegen/jni")
set(CUSTOM_JNI_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../src/main/jni")
set(SHARED_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../cpp")

# Codegen-generated sources (excluding ShadowNodes and States which we override)
file(GLOB codegen_root_SRCS CONFIGURE_DEPENDS "${CODEGEN_DIR}/*.cpp")
file(GLOB codegen_component_SRCS CONFIGURE_DEPENDS
    "${CODEGEN_DIR}/react/renderer/components/FabricHTMLTextSpec/*.cpp"
)

# Filter out files we're replacing with custom implementations
set(codegen_SRCS ${codegen_root_SRCS} ${codegen_component_SRCS})
list(FILTER codegen_SRCS EXCLUDE REGEX ".*ShadowNodes\\.cpp$")
list(FILTER codegen_SRCS EXCLUDE REGEX ".*States\\.cpp$")

# Custom ShadowNode implementation (overrides codegen)
set(custom_SRCS
    "${CUSTOM_JNI_DIR}/react/renderer/components/FabricHTMLTextSpec/ShadowNodes.cpp"
    "${CUSTOM_JNI_DIR}/react/renderer/components/FabricHTMLTextSpec/FabricHTMLTextState.cpp"
)

# Shared cross-platform C++ sources (HTML parser)
file(GLOB shared_cpp_SRCS CONFIGURE_DEPENDS "${SHARED_CPP_DIR}/*.cpp")

# Combine all sources
set(ALL_SRCS ${codegen_SRCS} ${custom_SRCS} ${shared_cpp_SRCS})

add_library(
    react_codegen_FabricHTMLTextSpec
    OBJECT
    ${ALL_SRCS}
)

target_include_directories(react_codegen_FabricHTMLTextSpec
    PUBLIC
    # Custom directories MUST come first to override codegen ShadowNodes.h
    ${CUSTOM_JNI_DIR}
    ${CUSTOM_JNI_DIR}/react/renderer/components/FabricHTMLTextSpec
    # Then codegen directories
    ${CODEGEN_DIR}
    ${CODEGEN_DIR}/react/renderer/components/FabricHTMLTextSpec
    # Shared C++ code
    ${SHARED_CPP_DIR}
)

target_link_libraries(
    react_codegen_FabricHTMLTextSpec
    log
    fbjni
    jsi
    reactnative
)

target_compile_reactnative_options(react_codegen_FabricHTMLTextSpec PRIVATE)
