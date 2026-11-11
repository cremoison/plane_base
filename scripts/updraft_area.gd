@tool
extends Area3D
class_name UpdraftArea

@export var wind_velocity: Vector3 = Vector3(0, 15.0, 0)
@export var is_visible_ingame: bool = true
@export var message : String 

@onready var csg_box: CSGBox3D = $Visual
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	if not Engine.is_editor_hint():
		# in game:
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)

		csg_box.visible = is_visible_ingame

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and csg_box and collision_shape:
		if collision_shape.shape is BoxShape3D:
			collision_shape.shape.size = csg_box.size
			collision_shape.position = csg_box.position

func _on_body_entered(body: Node3D) -> void:
	if body is AircraftPhysics:
		body.environment_wind += wind_velocity
		body.trigger_warning(message)

func _on_body_exited(body: Node3D) -> void:
	if body is AircraftPhysics:
		body.environment_wind -= wind_velocity
