# Camera calculator

`CameraCalculator` (`custom/src/CameraCalculator.h`, `custom/src/CameraCalculator.cc`) turns a click on a nadir camera image into a ground point. The fly-view video calls it from `src/FlyView/FlightDisplayViewVideo.qml` after mapping the click onto the sensor image. The class does not know about the widget size. It only sees native-image pixels, altitude, and vehicle pose.

The camera looks straight down. Roll and pitch are not used to tilt the ground intersection. They are used only when building the attitude quaternions for `TARGET_RELATIVE`.

## Sensor

The sensor is fixed in the source:

| | |
| --- | --- |
| Image | 3088 × 2076 px |
| Horizontal FOV | 25.4° |
| Vertical FOV | 17.7° |

Image X grows right. Image Y grows down. The origin of the body frame used here is FRD: forward, right, down.

## Click to body meters

`imageToBodyFrdMeters` is the shared projection.

1. Normalize the click about the image center, so the result is in `[-1, 1]`:

   `nx = (targetX - width/2) / (width/2)`

   `ny = (targetY - height/2) / (height/2)`

2. Scale by altitude and the tangent of half the field of view:

   `rightMeters   = altitude * nx * tan(horizontalFOV / 2)`

   `forwardMeters = -altitude * ny * tan(verticalFOV / 2)`

The minus sign on forward is because image Y grows downward. A click above the center has a negative `ny` and is in front of the vehicle. A click right of center is to the right.

Altitude at or below zero returns `0, 0`. There is no ground intersection.

## Public results

`calculateGroundDistance` is the horizontal offset, `sqrt(forward² + right²)`.

`calculateDistanceToTarget` is the slant range from the camera to that ground point, `sqrt(altitude² + groundDistance²)`. Altitude at or below zero returns `0`.

`calculateTimeInSeconds` is free-fall time from that altitude, `sqrt(2 * altitude / 9.81)`. No drag, no horizontal speed. Altitude at or below zero returns `0`. The time does not depend on where in the image you clicked.

`calculateTargetCoordinate` walks the ground offset out from the vehicle:

1. Bearing of the click in the body frame is `atan2(right, forward)`.
2. Absolute bearing is vehicle heading plus that relative bearing, wrapped to `[0, 360)`.
3. `QGeoCoordinate::atDistanceAndAzimuth` moves `groundDistance` meters along that bearing.

An invalid vehicle coordinate returns an invalid `QGeoCoordinate`. With altitude at or below zero the offset is zero, so a valid vehicle coordinate is returned unchanged.

## Uncertainty and attitude

`calculateTargetRelative` is the observation sent as MAVLink `TARGET_RELATIVE`. The map it returns:

| Key | Meaning |
| --- | --- |
| `forwardMeters`, `rightMeters` | Body-FRD offset of the click. Down is the altitude passed in by the caller, not computed here. |
| `posStd` | `[forward, right, down]` standard deviation in meters. |
| `yawStd` | Yaw standard deviation in radians. |
| `qSensor` | Quaternion, body FRD to NED, from roll, pitch, and yaw. Hamilton order `(w, x, y, z)`. |
| `qTarget` | Conjugate of `qSensor`. |

Position noise:

- A click is treated as `CLICK_SIGMA_PIXELS = 2` native pixels. The video widget is scaled, so one screen pixel is more than one sensor pixel, and 2 px is the allowance for that.
- Meters per pixel is `altitude * tan(half FOV) / (imageSize / 2)` on each axis.
- That is stretched by `slantRange / altitude`, because a click error grows along the ray, not only on the flat ground plane.
- Down noise is `0.15 m + 5% of altitude`.
- Each axis is at least `0.05 m`.

Yaw noise is at least 5°. A click is not a fiducial heading, so yaw stays loose. The only extra term is the horizontal angle of those same 2 pixels, and the 5° floor wins unless that angle is larger.

`qSensor` is the ZYX aircraft quaternion (yaw, then pitch, then roll) that rotates body FRD into NED. `qTarget` is its conjugate. The message convention is `q_in_ned = q_sensor * q_target`. For a level, north-aligned mark on the ground, `q_in_ned` should be identity, which is what the conjugate gives.
