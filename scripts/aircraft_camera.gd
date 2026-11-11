extends Node3D
class_name CameraController

@export var aircraft: AircraftPhysics
@export var speed_lines: GPUParticles3D

@export var cameras : Array[Camera3D]
var current_camera_index : int = 0

@export_group("Dynamic FOV")
@export var base_fov: float = 75.0
@export var max_fov: float = 100.0
@export var speed_for_max_fov: float = 80.0 
@export var fov_lerp_speed: float = 3.0

@export_group("Speed Turbulence")
@export var shake_intensity: float = 0.03
@export var speed_for_shake: float = 40.0 


var _base_position: Vector3

@export_group("Camera Rotation")
@export var max_look_angle_deg: float = 90.0 # Angolo massimo (90 gradi)
@export var smooth_speed: float = 12.0

var default_rotation: Vector3

func _ready() -> void:
	default_rotation = rotation
	_base_position = position
	cameras[current_camera_index].fov = base_fov

func _process(delta: float) -> void:
	if not aircraft:
		return
	
	var c = cameras[current_camera_index]
	var speed = aircraft.linear_velocity.length()
	
	# --- 1. Effetto Tunnel (Dynamic FOV) ---
	# Calcoliamo quanto stiamo andando veloci rispetto al nostro limite (da 0.0 a 1.0)
	var speed_factor = clamp(speed / speed_for_max_fov, 0.0, 1.0)
	
	# Applichiamo una curva per rendere l'effetto più evidente alle alte velocità
	speed_factor = pow(speed_factor, 1.5) 
	
	var target_fov = lerp(base_fov, max_fov, speed_factor)
	c.fov = lerp(c.fov, target_fov, delta * fov_lerp_speed)
	
	# --- 2. Turbolenza / Vibrazione (Camera Shake) ---
	# La vibrazione inizia solo dopo aver superato 'speed_for_shake'
	var shake_factor = clamp((speed - speed_for_shake) / (speed_for_max_fov - speed_for_shake), 0.0, 1.0)
	
	if shake_factor > 0.0:
		var random_offset = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			0.0
		) * shake_intensity * shake_factor
		
		position = _base_position + random_offset
	else:
		# Se rallentiamo, la camera torna fluidamente alla posizione di riposo
		position = position.lerp(_base_position, delta * 10.0)

	if speed_lines:
		if speed_factor > 0.2:
			speed_lines.emitting = true
			speed_lines.amount_ratio = speed_factor
		else:
			speed_lines.emitting = false

	# switch camera
	if Input.is_action_just_pressed("switch_camera"):
		cycle_cameras()

	# camera rotation
	var camera_x = Input.get_axis("camera_left","camera_right")
	# var camera_y = Input.get_axis("camera_up","camera_down")

	var target_yaw = default_rotation.y
	var target_pitch = default_rotation.x

	# lateral
	target_yaw = default_rotation.y + deg_to_rad(-max_look_angle_deg * camera_x)
	# down (retro)
	
	# up (look terrain)
	if Input.is_action_pressed("camera_up"):
		target_pitch = default_rotation.x - (PI / 2.0)

	rotation.y = lerp_angle(rotation.y, target_yaw, smooth_speed * delta)
	rotation.x = lerp_angle(rotation.x, target_pitch, smooth_speed * delta)
	
	if Input.is_action_pressed("camera_down"):
		rotation.y = default_rotation.y + PI

	

func cycle_cameras() -> void:
	if cameras.is_empty(): 
		return
	
	
	current_camera_index = (current_camera_index + 1) % cameras.size()

	cameras[current_camera_index].make_current()
