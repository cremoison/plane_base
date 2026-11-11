@tool
extends RigidBody3D
class_name AircraftPhysics

@export var thrust : float = 3000.0 # N
@export var max_thrust : float = 50000.0 # N
@export var air_density : float = 1.225 # kg/m^3
@export var is_engine_on : bool = true
@export var _mass : float = 1000.0 # kg

signal warning_triggered(message: String)

var environment_wind: Vector3 = Vector3.ZERO

var base_mass: float 
var base_com: Vector3
var current_cargo: CargoConfig

@export var airbrake_strength: float = 2.0
var is_airbrake_deployed = false

@export var ground_steering_torque: float = 4000.0
var current_yaw_input: float = 0.0

@export var slip_alignment_factor : float = 1.5 # k_aderenza

var aero_surfaces : Array[AeroSurface] = []

# Variabile per il gizmo
var _com_gizmo: MeshInstance3D

func _ready() -> void:
	#thrust = 30000
	base_mass = _mass
	mass = base_mass

	base_com = center_of_mass
	#linear_velocity = -global_transform.basis.z * 50.0
	if Engine.is_editor_hint():
		_setup_com_gizmo()
	else:
		if _com_gizmo:
			_com_gizmo.queue_free() 
		find_aero_surfaces(self)

		# mission manager
		MissionManager.order_started.connect(_on_order_started)
		MissionManager.order_completed.connect(_on_order_ended)
		MissionManager.order_abandoned.connect(_on_order_ended)

func load_cargo(cargo: CargoConfig) -> void:
	current_cargo = cargo

	if current_cargo:
		mass = base_mass + current_cargo.added_mass
		center_of_mass = base_com + current_cargo.com_shift
	else:
		mass = base_mass
		center_of_mass = base_com

func _process(_delta: float) -> void:
	# Aggiorna la posizione della pallina nell'editor in tempo reale
	if Engine.is_editor_hint():
		if center_of_mass_mode == RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM:
			if not _com_gizmo:
				_setup_com_gizmo()
			_com_gizmo.position = center_of_mass
			_com_gizmo.visible = true
		else:
			if _com_gizmo:
				_com_gizmo.visible = false

func _setup_com_gizmo() -> void:
	if not _com_gizmo:
		_com_gizmo = MeshInstance3D.new()
		
		var sphere = SphereMesh.new()
		sphere.radius = 0.1 # Dimensione della sfera (puoi regolarla)
		sphere.height = 0.2
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.5, 0.0, 0.8) # Arancione traslucido
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

		mat.no_depth_test = true

		sphere.surface_set_material(0, mat)
		
		_com_gizmo.mesh = sphere
		add_child(_com_gizmo)
		# Nascondiamo la Mesh dalla gerarchia dell'editor
		_com_gizmo.owner = null

func find_aero_surfaces(node: Node):
	for child in node.get_children():
		if child is AeroSurface:
			aero_surfaces.append(child)
		find_aero_surfaces(child)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var forward_dir = -global_transform.basis.z
	if Engine.is_editor_hint():
		return

	if is_engine_on:
		state.apply_central_force(forward_dir * thrust)

	for surface in aero_surfaces:
		var origin_offset = surface.global_position - global_position
		var point_velocity = state.linear_velocity + state.angular_velocity.cross(origin_offset) - environment_wind

		var aero_data = surface.calculate_forces(point_velocity, air_density)

		if aero_data.force.length_squared() > 0.01:
			state.apply_force(aero_data.force, origin_offset)

	var current_velocity = state.linear_velocity
	var speed = current_velocity.length()

	if speed > 2.0:
		var target_velocity = forward_dir * speed
		state.linear_velocity = current_velocity.lerp(target_velocity, slip_alignment_factor * state.step)

	if state.get_contact_count() > 0 and current_yaw_input != 0.0:
		var _speed = state.linear_velocity.length()
		var steering_damping = clamp(15.0 / (_speed+ 1.0),0.1, 1.0)

		var up_direction = global_transform.basis.y

		state.apply_torque(up_direction * -current_yaw_input * ground_steering_torque * steering_damping)

	if is_airbrake_deployed:
		state.linear_velocity = state.linear_velocity.lerp(Vector3.ZERO, airbrake_strength * state.step)

func trigger_warning(message: String) -> void:
	warning_triggered.emit(message)

func _on_order_started(order) -> void:
	if order and order.cargo:
		load_cargo(order.cargo)
		print("[!] Order loaded! New mass: ", mass)

func _on_order_ended(_order = null) -> void:
	load_cargo(null)
	print("[!] Order unloaded! New mass: ", mass)
