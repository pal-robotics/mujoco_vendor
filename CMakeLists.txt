
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
  set(MUJOCO_ASSET_NAME "mujoco-${MUJOCO_VERSION}-macos-universal2.dmg")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  set(MUJOCO_ASSET_NAME "mujoco-${MUJOCO_VERSION}-windows-x86_64.zip")
else()
  message(FATAL_ERROR "Unsupported operating system: ${CMAKE_SYSTEM_NAME}")
endif()

set(MUJOCO_ASSET_URL "${MUJOCO_DOWNLOAD_URL}/${MUJOCO_ASSET_NAME}")

message(STATUS "Downloading MuJoCo prebuilt binary: ${MUJOCO_ASSET_NAME}")

FetchContent_Declare(
  mujoco_binary
  URL ${MUJOCO_ASSET_URL}
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
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

# Export includes and library path
ament_export_targets(export_${PROJECT_NAME} HAS_LIBRARY_TARGET)
ament_export_include_directories(opt/${PROJECT_NAME}/include)

# Install environment hook to set LD_LIBRARY_PATH
ament_environment_hooks("${CMAKE_CURRENT_SOURCE_DIR}/env-hooks/${PROJECT_NAME}.dsv")

ament_package(
  CONFIG_EXTRAS_POST "mujoco_vendor-extras.cmake"
)
