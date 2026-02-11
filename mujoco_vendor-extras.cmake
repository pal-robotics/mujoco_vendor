# Create imported target mujoco::mujoco
if(NOT TARGET mujoco::mujoco)
  add_library(mujoco::mujoco SHARED IMPORTED)
  set_target_properties(mujoco::mujoco PROPERTIES
    IMPORTED_LOCATION "${mujoco_vendor_DIR}/../../../opt/mujoco_vendor/lib/libmujoco.so"
    INTERFACE_INCLUDE_DIRECTORIES "${mujoco_vendor_DIR}/../../../opt/mujoco_vendor/include"
  )
endif()

set(mujoco_vendor_LIBRARIES mujoco::mujoco)
