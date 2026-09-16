from pymavlink import mavutil
print("Starting MAVLINK listener")
master = mavutil.mavlink_connection('udpin:0.0.0.0:14540')

print("wainting for mavlink...")

while True:
	msg = master.recv_match(blocking=True)
	if msg:
		print(msg)
