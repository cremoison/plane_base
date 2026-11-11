extends Node
class_name AircraftController

@export var aircraft_physics: AircraftPhysics
@export var pitch_surfaces: Array[AeroSurface]  # coda
@export var roll_surfaces: Array[AeroSurface]   # ali
@export var yaw_surfaces: Array[AeroSurface]    # timone

@export var throttle_step : float = 50000

@export var max_deflection: float = 40.0 # maximum flap rotation degrees

func _process(delta):
	if not aircraft_physics : return
	
	var pitch_input = Input.get_axis("pitch_up", "pitch_down")
	var roll_input = Input.get_axis("roll_left", "roll_right")
	var yaw_input = Input.get_axis("yaw_left", "yaw_right")

	aircraft_physics.current_yaw_input = yaw_input

	var speed = aircraft_physics.linear_velocity.length()
	var speed_damping = clamp(60.0 / speed, 0.1, 1.0) if speed > 60.0 else 1.0
	var current_deflection = max_deflection * speed_damping

	for surface in pitch_surfaces:
		surface.set_flap_angle(pitch_input * current_deflection)
	for surface in roll_surfaces:
		surface.set_flap_angle(roll_input * current_deflection)
	for surface in yaw_surfaces:
		surface.set_flap_angle(yaw_input * current_deflection)

	if Input.is_action_pressed("throttle_up"):
		aircraft_physics.thrust += throttle_step * delta
	elif Input.is_action_pressed("throttle_down"):
		aircraft_physics.thrust -= throttle_step * delta
	else : 
		if aircraft_physics.thrust < aircraft_physics.base_thrust:
			aircraft_physics.thrust+=throttle_step/2*delta
		if aircraft_physics.thrust > aircraft_physics.base_thrust:
			aircraft_physics.thrust-=throttle_step/2*delta
	aircraft_physics.thrust = clamp(aircraft_physics.thrust, 0.0, aircraft_physics.max_thrust) # 15000.0 is max_thrust
	
	if Input.is_action_pressed("airbrake"):
		aircraft_physics.is_airbrake_deployed = true
	else: 
		aircraft_physics.is_airbrake_deployed = false
