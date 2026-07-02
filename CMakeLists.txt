
cmake_minimum_required(VERSION 3.10)
project(mujoco_vendor)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)

# Handle the case in which mujoco should not vendored, for example in conda-forge/robostack where a recent enough
# mujoco package is available in the distribution, and there is no need to vendor it
# We use the AMENT_VENDOR_POLICY option proposed in https://github.com/ament/ament_cmake/pull/592 and that will
# be introduced at some point in ament_vendor for this purpouse
if(DEFINED AMENT_VENDOR_POLICY AND (AMENT_VENDOR_POLICY STREQUAL "NEVER_VENDOR" OR AMENT_VENDOR_POLICY STREQUAL "NEVER_VENDOR_IGNORE_SATISFIED_CHECK"))
  ament_export_dependencies(mujoco)
  ament_package()
  return()
endif()

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

# Copy the FetchContent download to a stable, version-named directory in the
# build tree so that cmake_install.cmake does not reference the
# FetchContent-internal _deps/ path, which may not exist when cmake re-checks
# the build system during the Debian dh_auto_install step.
# The version suffix ensures a fresh copy whenever MUJOCO_VERSION changes.
set(MUJOCO_ROOT_DIR "${CMAKE_BINARY_DIR}/mujoco_prebuilt_${MUJOCO_VERSION}")
if(NOT EXISTS "${MUJOCO_ROOT_DIR}")
  file(COPY "${mujoco_binary_SOURCE_DIR}/" DESTINATION "${MUJOCO_ROOT_DIR}")
endif()
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
# On UNIX, `simulate` is excluded: it instead gets a wrapper script that 
# preloads the plugin-path shim before executing the real binary.
if(UNIX)
  set(symlink_exclude "simulate")
else()
  set(symlink_exclude "")
endif()
install(CODE "
  file(GLOB _mujoco_exes
    \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/opt/${PROJECT_NAME}/bin/*\")
  file(MAKE_DIRECTORY \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/lib/${PROJECT_NAME}\")
  foreach(_exe IN LISTS _mujoco_exes)
    if(NOT IS_DIRECTORY \"\${_exe}\")
      get_filename_component(_name \"\${_exe}\" NAME)
      if(NOT \"\${_name}\" STREQUAL \"${symlink_exclude}\")
        execute_process(
          COMMAND \${CMAKE_COMMAND} -E create_symlink
            \"../../opt/${PROJECT_NAME}/bin/\${_name}\"
            \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/lib/${PROJECT_NAME}/\${_name}\"
        )
      endif()
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

# LD_PRELOAD shim that loads MuJoCo plugins from an additional directory before main() runs.
# Since plugin registration is process-global inside libmujoco.so,
# a preloaded constructor can add plugins from anywhere.
# The wrapper script replaces the lib/${PROJECT_NAME}/simulate symlink so that
# `ros2 run mujoco_vendor simulate` picks up the shim transparently.
if(UNIX)
  find_package(ament_index_cpp REQUIRED)
  add_library(mujoco_plugin_shim SHARED src/plugin_path_shim.cc)
  target_link_libraries(mujoco_plugin_shim PRIVATE
    mujoco
    ament_index_cpp::ament_index_cpp
  )
  target_compile_features(mujoco_plugin_shim PRIVATE cxx_std_17)
  # Installed next to libmujoco.so so the shim finds it via $ORIGIN.
  set_target_properties(mujoco_plugin_shim PROPERTIES INSTALL_RPATH "\$ORIGIN")
  install(TARGETS mujoco_plugin_shim
    LIBRARY DESTINATION opt/${PROJECT_NAME}/lib
  )
  install(PROGRAMS scripts/simulate DESTINATION lib/${PROJECT_NAME})
endif()

# Export includes and library path
ament_export_targets(export_${PROJECT_NAME} HAS_LIBRARY_TARGET)
ament_export_include_directories(opt/${PROJECT_NAME}/include)

# Install environment hook to set LD_LIBRARY_PATH
ament_environment_hooks("${CMAKE_CURRENT_SOURCE_DIR}/env-hooks/${PROJECT_NAME}.dsv")

ament_package(
  CONFIG_EXTRAS_POST "mujoco_vendor-extras.cmake"
)
