
cmake_minimum_required(VERSION 3.10)
project(mujoco_vendor)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
include(FetchContent)

set(MUJOCO_VERSION "3.4.0")
set(MUJOCO_DOWNLOAD_URL "https://github.com/google-deepmind/mujoco/releases/download/${MUJOCO_VERSION}")

# Detect system and architecture for appropriate asset selection
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|ARM64")
    set(MUJOCO_ASSET_NAME "mujoco-${MUJOCO_VERSION}-linux-aarch64.tar.gz")
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
    set(MUJOCO_ASSET_NAME "mujoco-${MUJOCO_VERSION}-linux-x86_64.tar.gz")
  else()
    message(FATAL_ERROR "Unsupported Linux architecture: ${CMAKE_SYSTEM_PROCESSOR}")
  endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  message(FATAL_ERROR "mujoco_vendor: macOS (Darwin) is not supported!.")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  set(MUJOCO_ASSET_NAME "mujoco-${MUJOCO_VERSION}-windows-x86_64.zip")
else()
  message(FATAL_ERROR "Unsupported operating system: ${CMAKE_SYSTEM_NAME}")
endif()

set(MUJOCO_ASSET_URL "${MUJOCO_DOWNLOAD_URL}/${MUJOCO_ASSET_NAME}")

message(STATUS "Downloading MuJoCo prebuilt binary: ${MUJOCO_ASSET_NAME}")

if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.24")
  set(_mujoco_timestamp DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
endif()

FetchContent_Declare(
  mujoco_binary
  URL "${MUJOCO_ASSET_URL}"
  ${_mujoco_timestamp}
)
FetchContent_MakeAvailable(mujoco_binary)

set(MUJOCO_ROOT_DIR "${mujoco_binary_SOURCE_DIR}")
set(MUJOCO_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/opt/${PROJECT_NAME}")

# Install prebuilt binaries (copy actual files, resolve symlinks)
install(DIRECTORY ${MUJOCO_ROOT_DIR}/
  DESTINATION opt/${PROJECT_NAME}
  USE_SOURCE_PERMISSIONS
  FILES_MATCHING
  PATTERN "*"
)

# The MuJoCo plugins ship with a hardcoded build-time RPATH
# (/tmpfs/src/git/mujoco_internal/build/lib) that does not exist on target
# machines. Rewrite it to a $ORIGIN-relative path so that:
#   1. dpkg-shlibdeps can locate libmujoco.so.3.4.0 when analysing the plugins
#      in the Debian staging area (it expands $ORIGIN to the directory of the
#      file under analysis, landing in opt/mujoco_vendor/lib/ where
#      libmujoco.so.3.4.0 is installed by this same package), and
#   2. plugins can find libmujoco.so at runtime without relying solely on
#      LD_LIBRARY_PATH.
find_program(PATCHELF_EXECUTABLE patchelf)
if(NOT PATCHELF_EXECUTABLE)
  message(WARNING
    "patchelf not found. MuJoCo plugin RPATHs will not be fixed; "
    "Debian packaging will fail with 'cannot find libmujoco.so.3.4.0'.")
else()
  install(CODE "
    file(GLOB _mujoco_plugins
      \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/opt/${PROJECT_NAME}/bin/mujoco_plugin/*.so\")
    foreach(_plugin IN LISTS _mujoco_plugins)
      execute_process(
        COMMAND \"${PATCHELF_EXECUTABLE}\" --set-rpath \"\$ORIGIN/../../lib\" \"\${_plugin}\"
        RESULT_VARIABLE _rc
      )
      if(NOT _rc EQUAL 0)
        message(WARNING \"patchelf failed for \${_plugin}\")
      endif()
    endforeach()
  ")
endif()

# Create symlinks in lib/${PROJECT_NAME}/ pointing to the real binaries in
# opt/${PROJECT_NAME}/bin/ so that `ros2 run mujoco_vendor <exe>` works
# without duplicating files on disk.
install(CODE "
  file(GLOB _mujoco_exes
    \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/opt/${PROJECT_NAME}/bin/*\")
  file(MAKE_DIRECTORY \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/lib/${PROJECT_NAME}\")
  foreach(_exe IN LISTS _mujoco_exes)
    if(NOT IS_DIRECTORY \"\${_exe}\")
      get_filename_component(_name \"\${_exe}\" NAME)
      execute_process(
        COMMAND \${CMAKE_COMMAND} -E create_symlink
          \"../../opt/${PROJECT_NAME}/bin/\${_name}\"
          \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/lib/${PROJECT_NAME}/\${_name}\"
      )
    endif()
  endforeach()
")

add_library(mujoco INTERFACE)
# add alias mujoco::mujoco mujoco
add_library(mujoco::mujoco ALIAS mujoco)
add_dependencies(mujoco mujoco_binary)
target_include_directories(mujoco INTERFACE
  $<BUILD_INTERFACE:${MUJOCO_ROOT_DIR}/include>
  $<INSTALL_INTERFACE:opt/${PROJECT_NAME}/include>
)
target_link_libraries(mujoco INTERFACE
  $<BUILD_INTERFACE:${MUJOCO_ROOT_DIR}/lib/libmujoco.so>
  $<INSTALL_INTERFACE:opt/${PROJECT_NAME}/lib/libmujoco.so>
)

install(TARGETS mujoco
  EXPORT export_${PROJECT_NAME}
  LIBRARY DESTINATION opt/${PROJECT_NAME}/lib
  ARCHIVE DESTINATION opt/${PROJECT_NAME}/lib
  RUNTIME DESTINATION opt/${PROJECT_NAME}/bin
)

# Pinned lodepng version from:
# https://github.com/google-deepmind/mujoco/blob/3.4.0/simulate/CMakeLists.txt#L26
set(MUJOCO_DEP_VERSION_lodepng "b4ed2cd7ecf61d29076169b49199371456d4f90b")
FetchContent_Declare(lodepng
  GIT_REPOSITORY https://github.com/lvandeve/lodepng.git
  GIT_TAG ${MUJOCO_DEP_VERSION_lodepng}
)
FetchContent_GetProperties(lodepng)
if(NOT lodepng_POPULATED)
  FetchContent_Populate(lodepng)
  add_library(lodepng STATIC ${lodepng_SOURCE_DIR}/lodepng.cpp)
  set_target_properties(lodepng PROPERTIES POSITION_INDEPENDENT_CODE ON)
  target_include_directories(lodepng PUBLIC $<BUILD_INTERFACE:${lodepng_SOURCE_DIR}>)
endif()
install(TARGETS lodepng ARCHIVE DESTINATION opt/${PROJECT_NAME}/lib)
install(FILES ${lodepng_SOURCE_DIR}/lodepng.h DESTINATION opt/${PROJECT_NAME}/include)

# Setup the simulate library for mujoco_ros2_control
find_package(glfw3 REQUIRED)

set(_SIM_DIR "${MUJOCO_ROOT_DIR}/simulate")
if(NOT EXISTS "${_SIM_DIR}/simulate.h")
  set(_SIM_DIR "${MUJOCO_ROOT_DIR}/include/simulate")
endif()

add_library(mujoco_simulate STATIC
  ${_SIM_DIR}/platform_ui_adapter.cc
  ${_SIM_DIR}/glfw_adapter.cc
  ${_SIM_DIR}/glfw_dispatch.cc
  ${_SIM_DIR}/simulate.cc
)
set_target_properties(mujoco_simulate PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(mujoco_simulate PUBLIC
  $<BUILD_INTERFACE:${_SIM_DIR}>
  $<BUILD_INTERFACE:${MUJOCO_ROOT_DIR}/include>
)
target_link_libraries(mujoco_simulate PUBLIC mujoco glfw PRIVATE lodepng)
target_compile_options(mujoco_simulate PRIVATE
  -Wno-missing-field-initializers -Wno-unused-parameter -Wno-sign-compare -Wno-psabi
)
install(TARGETS mujoco_simulate ARCHIVE DESTINATION opt/${PROJECT_NAME}/lib)
install(DIRECTORY ${_SIM_DIR}/ DESTINATION opt/${PROJECT_NAME}/include/simulate
  FILES_MATCHING PATTERN "*.h"
)

# Export includes and library path
ament_export_targets(export_${PROJECT_NAME} HAS_LIBRARY_TARGET)
ament_export_include_directories(opt/${PROJECT_NAME}/include)

# Install environment hook to set LD_LIBRARY_PATH
ament_environment_hooks("${CMAKE_CURRENT_SOURCE_DIR}/env-hooks/${PROJECT_NAME}.dsv")

ament_package(
  CONFIG_EXTRAS_POST "mujoco_vendor-extras.cmake"
)
