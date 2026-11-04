get_filename_component(_MUJOCO_VENDOR_PREFIX "${mujoco_vendor_DIR}/../../.." ABSOLUTE)
set(MUJOCO_VENDOR_ROOT "${_MUJOCO_VENDOR_PREFIX}/opt/mujoco_vendor")

# Set the following for downstream packages
set(MUJOCO_INCLUDE_DIR  "${MUJOCO_VENDOR_ROOT}/include")
set(MUJOCO_LIB_DIR      "${MUJOCO_VENDOR_ROOT}/lib")
set(MUJOCO_BIN_DIR      "${MUJOCO_VENDOR_ROOT}/bin")
set(MUJOCO_PLUGIN_DIR   "${MUJOCO_VENDOR_ROOT}/bin/mujoco_plugin")
set(MUJOCO_SIMULATE_DIR "${MUJOCO_VENDOR_ROOT}/include/simulate")

if(NOT TARGET mujoco::mujoco)
  add_library(mujoco::mujoco SHARED IMPORTED)
  set_target_properties(mujoco::mujoco PROPERTIES
    IMPORTED_LOCATION "${MUJOCO_LIB_DIR}/libmujoco.so"
    INTERFACE_INCLUDE_DIRECTORIES "${MUJOCO_INCLUDE_DIR}"
    INTERFACE_LINK_OPTIONS "LINKER:-rpath,${MUJOCO_LIB_DIR}"
  )
endif()
set(mujoco_vendor_LIBRARIES mujoco::mujoco)
set(mujoco_vendor_LIBRARY_DIRS "${MUJOCO_LIB_DIR}")

# We rely on the same target names as upstream MuJoCo and conda-forge (`lodepng`,
# `mujoco::libmujoco_simulate`). This enables consumers to use one set of names.
if(NOT TARGET lodepng)
  add_library(lodepng STATIC IMPORTED)
  set_target_properties(lodepng PROPERTIES
    IMPORTED_LOCATION "${MUJOCO_LIB_DIR}/liblodepng.a"
    INTERFACE_INCLUDE_DIRECTORIES "${MUJOCO_INCLUDE_DIR}"
  )
endif()

if(NOT TARGET mujoco::libmujoco_simulate)
  add_library(mujoco::libmujoco_simulate STATIC IMPORTED)
  set_target_properties(mujoco::libmujoco_simulate PROPERTIES
    IMPORTED_LOCATION "${MUJOCO_LIB_DIR}/libmujoco_simulate.a"
    INTERFACE_INCLUDE_DIRECTORIES "${MUJOCO_INCLUDE_DIR};${MUJOCO_SIMULATE_DIR}"
    INTERFACE_LINK_LIBRARIES "mujoco::mujoco;lodepng"
  )
endif()

# Deprecated aliases for the previous names.
# TODO: Remove after the next release.
if(NOT TARGET lodepng::lodepng)
  add_library(lodepng::lodepng ALIAS lodepng)
endif()
if(NOT TARGET mujoco::simulate)
  add_library(mujoco::simulate ALIAS mujoco::libmujoco_simulate)
endif()
