# Custom CMakeLists.txt for FabricHTMLTextSpec
# This file is copied over the codegen-generated CMakeLists.txt to add the log library
# for Android NDK logging support (__android_log_print)

cmake_minimum_required(VERSION 3.13)
set(CMAKE_VERBOSE_MAKEFILE on)

# Shared C++ sources (cross-platform HTML parser)
set(SHARED_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../../cpp")
file(GLOB shared_cpp_SRCS CONFIGURE_DEPENDS ${SHARED_CPP_DIR}/*.cpp)

file(GLOB react_codegen_SRCS CONFIGURE_DEPENDS *.cpp react/renderer/components/FabricHTMLTextSpec/*.cpp)

add_library(
  react_codegen_FabricHTMLTextSpec
  OBJECT
  ${react_codegen_SRCS}
  ${shared_cpp_SRCS}
)

target_include_directories(react_codegen_FabricHTMLTextSpec PUBLIC . react/renderer/components/FabricHTMLTextSpec ${SHARED_CPP_DIR})

target_link_libraries(
  react_codegen_FabricHTMLTextSpec
  fbjni
  jsi
  reactnative
  log  # Android NDK log library for __android_log_print
)

target_compile_reactnative_options(react_codegen_FabricHTMLTextSpec PRIVATE)
