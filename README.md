# mujoco_vendor

Vendor package for [MuJoCo](https://mujoco.org/) (Multi-Joint dynamics with Contact) physics simulator.

Downloads the official prebuilt MuJoCo binary at build time and exposes it as a CMake imported target (`mujoco::mujoco`) for use by other ROS 2 packages.

## Building

```bash
colcon build --packages-select mujoco_vendor
```

MuJoCo is fetched automatically from GitHub releases during the build — no manual download required.

## Using in another package

In your `CMakeLists.txt`:

```cmake
find_package(mujoco_vendor REQUIRED)

target_link_libraries(my_target mujoco::mujoco)
```

In your `package.xml`:

```xml
<depend>mujoco_vendor</depend>
```

The installed layout under `opt/mujoco_vendor/` mirrors the upstream MuJoCo release tarball:

```
opt/mujoco_vendor/
  include/   # MuJoCo headers
  lib/       # libmujoco.so
  bin/       # simulate, basic, compile, record, testspeed, dependencies
```

## Running the MuJoCo interactive simulator

After sourcing the workspace, all MuJoCo binaries are available via `ros2 run`:

```bash
source install/setup.bash
ros2 run mujoco_vendor simulate
```

Other available executables:

| Command                                   | Description                          |
|-------------------------------------------|--------------------------------------|
| `ros2 run mujoco_vendor simulate`         | Interactive viewer / simulator       |
| `ros2 run mujoco_vendor basic`            | Minimal headless simulation example  |
| `ros2 run mujoco_vendor compile`          | Compile an MJCF/URDF model to binary |
| `ros2 run mujoco_vendor record`           | Record a simulation to video         |
| `ros2 run mujoco_vendor testspeed`        | Benchmark simulation speed           |
| `ros2 run mujoco_vendor dependencies`     | Print model file dependencies        |
