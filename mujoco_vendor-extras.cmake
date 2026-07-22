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

if(NOT TARGET lodepng::lodepng)
  add_library(lodepng::lodepng STATIC IMPORTED)
  set_target_properties(lodepng::lodepng PROPERTIES
    IMPORTED_LOCATION "${MUJOCO_LIB_DIR}/liblodepng.a"
    INTERFACE_INCLUDE_DIRECTORIES "${MUJOCO_INCLUDE_DIR}"
  )
endif()

if(NOT TARGET mujoco::simulate)
  add_library(mujoco::simulate STATIC IMPORTED)
  set_target_properties(mujoco::simulate PROPERTIES
    IMPORTED_LOCATION "${MUJOCO_LIB_DIR}/libmujoco_simulate.a"
    INTERFACE_INCLUDE_DIRECTORIES "${MUJOCO_INCLUDE_DIR};${MUJOCO_SIMULATE_DIR}"
    INTERFACE_LINK_LIBRARIES "mujoco::mujoco;lodepng::lodepng"
  )
endif()
