# MAVLink submodules

This tree talks to the vehicle with a Godwit fork of MAVLink so `TARGET_RELATIVE` (message id 511) is available. Stock QGC pins `https://github.com/mavlink/mavlink.git` and the `all` dialect. That message lives in the `development` dialect, so the custom build points CMake at a local checkout instead.

The checkout list is `.gitmodules` in the repository root (`qgroundcontrol/.gitmodules`), next to `CMakeLists.txt`. Git reads that file. It is not under `libs/`.

```ini
[submodule "libs/mavlink-custom"]
	path = libs/mavlink-custom
	url = https://github.com/Godwit-systems/c_library_v2.git
[submodule "libs/mavlink-def"]
	path = libs/mavlink-def
	url = https://github.com/Godwit-systems/mavlink.git
```

| Path | Remote | What it is |
| --- | --- | --- |
| `libs/mavlink-def` | `https://github.com/Godwit-systems/mavlink.git` | XML message definitions and the mavgen tooling. `TARGET_RELATIVE` is in `message_definitions/v1.0/development.xml`. |
| `libs/mavlink-custom` | `https://github.com/Godwit-systems/c_library_v2.git` | C headers already generated from that dialect set. |

A fresh clone leaves both directories empty until you install them. The build needs `libs/mavlink-def` filled in. If it is empty, generation of the dialect headers fails.

## Install

From the repository root:

```bash
git submodule update --init --recursive

and the repos are going to clone into the folders and install submoules if the repos have submodules themselves.