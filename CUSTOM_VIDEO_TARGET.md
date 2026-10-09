# Video target

In Fly View, a left-click on the video measures a point on the ground. Holding `A` for one second arms a throw. The click sends that point to the vehicle only while the arm is still held.

The UI lives in `src/FlyView/FlightDisplayViewVideo.qml`. The geometry lives in `custom/src/CameraCalculator`. See [custom/src/CUSOTMCAMEARCALC.md](custom/src/CUSOTMCAMEARCALC.md).

## Measure

Click the video with the left button. You do not need to hold `A`.

The click position inside the video widget is normalized to `0..1`, then scaled onto the 3088 × 2076 sensor image. `CameraCalculator` turns that pixel, plus altitude, vehicle position, and heading, into:

- **Ground** — horizontal distance from the vehicle to the point, in meters
- **Distance** — slant range, in meters
- **altitude** — height used for the projection, in meters
- **Time to Impact** — free-fall time from that height, `sqrt(2h / 9.81)`
- **GEO coords** — WGS84 latitude and longitude

A red dot stays on the click. The numbers sit in a box at the lower left of the video. Clicking again moves the dot and refreshes the numbers.

Altitude comes from `activeVehicle.altitudeRelative.value * 0.3048`. Fact `value` is the cooked display value. The `0.3048` factor converts feet to meters, so this path is correct when QGC is showing altitude in feet.

## Throw

The video widget takes keyboard focus. To arm:

1. Press and hold `A`.
2. Keep it down for one second. The log line is `THROW!`, and `acceptedThrow` becomes true.
3. Left-click the video while `A` is still down.

Releasing `A` disarms immediately, including after the one-second mark. A key repeat does not restart or cancel the timer.

While armed, the number box turns red (`#FD1818`). While disarmed it stays dark.

A click sends only when all of these are true:

- `A` is still held and the one-second timer has already fired
- a vehicle is connected
- the computed coordinate is valid

Then the click:

1. Stores the point with `Vehicle::doSetTargetPoint`.
2. Builds the body-FRD observation with `CameraCalculator::calculateTargetRelative` (forward, right, down, position std, yaw std, `q_target`, `q_sensor`). Down is the same altitude used for the projection. Roll, pitch, and heading come from the vehicle.
3. Sends MAVLink `TARGET_RELATIVE` (message id 511) through `Vehicle::sendTargetRelative`. The link is forced to MAVLink 2, because id 511 does not fit in a v1 frame. The frame is `TARGET_OBS_FRAME_BODY_FRD` and the type is `LANDING_TARGET_TYPE_VISION_FIDUCIAL`.

A toast, **Target sent**, shows for two seconds when the send succeeds. A click with no vehicle, an invalid coordinate, or without the `A` hold still updates the dot and the numbers, and does not send.
