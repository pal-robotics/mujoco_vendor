
cmake_minimum_required(VERSION 3.8)
project(mujoco_vendor)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(ament_cmake_vendor_package REQUIRED)
include(ExternalProject)

set(MUJOCO_BUILD_BRANCH 3.3.4)
ament_vendor(mujoco_vendor
  VCS_URL https://github.com/google-deepmind/mujoco.git
  VCS_VERSION ${MUJOCO_BUILD_BRANCH}
  CMAKE_ARGS
    "-DCMAKE_BUILD_TYPE=Release"
    GLOBAL_HOOK
)
ExternalProject_Get_Property(mujoco_vendor SOURCE_DIR)

install(DIRECTORY ${SOURCE_DIR}/simulate/
  DESTINATION opt/${PROJECT_NAME}/simulate
)

ament_package(
  CONFIG_EXTRAS_POST "mujoco_vendor-extra.cmake.in"
)
