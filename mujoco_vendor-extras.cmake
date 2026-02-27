# Create imported target mujoco::mujoco
if(NOT TARGET mujoco::mujoco)
  add_library(mujoco::mujoco SHARED IMPORTED)
  set_target_properties(mujoco::mujoco PROPERTIES
    IMPORTED_LOCATION "${mujoco_vendor_DIR}/../../../opt/mujoco_vendor/lib/libmujoco.so"
    INTERFACE_INCLUDE_DIRECTORIES "${mujoco_vendor_DIR}/../../../opt/mujoco_vendor/include"
    INTERFACE_LINK_OPTIONS "LINKER:-rpath,${mujoco_vendor_DIR}/../../../opt/mujoco_vendor/lib"
  )
endif()

set(mujoco_vendor_LIBRARIES mujoco::mujoco)
set(mujoco_vendor_LIBRARY_DIRS "${mujoco_vendor_DIR}/../../../opt/mujoco_vendor/lib")
