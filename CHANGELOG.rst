^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Changelog for package mujoco_vendor
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

0.1.0 (2026-08-26)
------------------
* Remove Sergi from the maintainers
* Bump MuJoCo to 3.12.0
* Contributors: Sai Kishor Kothakota

0.0.9 (2026-07-22)
------------------
* Export simulate, lodepng, and path variables for downstream packages (`#10 <https://github.com/pal-robotics/mujoco_vendor/issues/10>`_)
* Add support for the AMENT_VENDOR_POLICY variable to support unvendoring (`#9 <https://github.com/pal-robotics/mujoco_vendor/issues/9>`_)
* Contributors: Erik Holum, Silvio Traversaro

0.0.8 (2026-03-08)
------------------
* Fix the build tree mujoco binary directory (`#8 <https://github.com/pal-robotics/mujoco_vendor/issues/8>`_)
* Contributors: Sai Kishor Kothakota

0.0.7 (2026-02-27)
------------------
* Update readme (`#6 <https://github.com/pal-robotics/mujoco_vendor/issues/6>`_)
* Add symlinks to be able to find executables (`#5 <https://github.com/pal-robotics/mujoco_vendor/issues/5>`_)
* Package prebuilt mujoco binaries (`#4 <https://github.com/pal-robotics/mujoco_vendor/issues/4>`_)
* Contributors: Sai Kishor Kothakota, Erik Holum

0.0.6 (2025-12-23)
------------------
* Merge branch 'bump/mujoco_vendor/3.4.0' into 'master'
  Bump mujoco_vendor to 3.4.0
  See merge request third-party/mujoco_vendor!5
* set the -flto flag to auto
* switch to wayland-dev rosdep
* add wayland dependency as exec depend
* Add libwayland-dev libxkbcommon-dev dependencies
* add libx11-dev dependency
* add pkg-config as build depend
* Update description
* Bump mujoco_vendor to 3.4.0
* Contributors: Sai Kishor Kothakota

0.0.5 (2025-10-21)
------------------
* Merge branch 'sma/add_install_simulate_project' into 'master'
  Add install rule for simulate folder
  See merge request third-party/mujoco_vendor!4
* Add install rule for simulate folder
* Contributors: Sai Kishor Kothakota, sergiacosta

0.0.4 (2025-10-12)
------------------
* Merge branch 'update/license_and_release_information' into 'master'
  Update maintainers + authors + license information
  See merge request third-party/mujoco_vendor!3
* Update maintainers + authors + license information
* Contributors: Sai Kishor Kothakota

0.0.3 (2025-07-25)
------------------
* add libxrandr dependency
* Contributors: Sai Kishor Kothakota

0.0.2 (2025-07-24)
------------------
* Merge branch 'fix/vendor/build' into 'master'
  Fix vendor build issue on CI
  See merge request third-party/mujoco_vendor!2
* Bump MuJoCo version
* Add missing dependencies for compiling MuJoCo
* Contributors: Sai Kishor Kothakota

0.0.1 (2025-03-25)
------------------
* Merge branch 'update-version' into 'master'
  updated mujoco version to 3.3.0
  See merge request third-party/mujoco_vendor!1
* updated mujoco version to 3.3.0
* Added changes to mujoco_vendor for linking and headers
* added readme
* dded package info
* added cmake instructions
* Initial commit
* Contributors: Sai Kishor Kothakota, sergiacosta
