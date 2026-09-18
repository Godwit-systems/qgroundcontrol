from pymavlink import mavutil

print("Starting MAVLINK listener on 127.0.0.1:14445")
master = mavutil.mavlink_connection(
    "udpin:127.0.0.1:14445",
    dialect="development",
)

print("waiting for mavlink...")

# High-rate vehicle telemetry we skip so GCS-outbound / custom messages stand out.
_SKIP_TYPES = {
    "HEARTBEAT",
    "SYS_STATUS",
    "SYSTEM_TIME",
    "GPS_RAW_INT",
    "GLOBAL_POSITION_INT",
    "ATTITUDE",
    "ATTITUDE_QUATERNION",
    "LOCAL_POSITION_NED",
    "VFR_HUD",
    "RC_CHANNELS",
    "SERVO_OUTPUT_RAW",
    "BATTERY_STATUS",
    "EXTENDED_SYS_STATE",
    "HOME_POSITION",
    "VIBRATION",
    "NAMED_VALUE_FLOAT",
    "DISTANCE_SENSOR",
    "ADSB_VEHICLE",
    "OPEN_DRONE_ID_ARM_STATUS",
    "AVAILABLE_MODES_MONITOR",
    "HIGHRES_IMU",
    "SCALED_IMU",
    "SCALED_PRESSURE",
    "TIMESYNC",
    "PING",
}

_seen_live = False

while True:
    msg = master.recv_match(blocking=True)
    if not msg:
        continue

    msg_type = msg.get_type()
    if not _seen_live:
        _seen_live = True
        print(f"link is live ({msg_type})")

    if msg_type == "TARGET_RELATIVE" or msg_type not in _SKIP_TYPES:
        print(msg)
