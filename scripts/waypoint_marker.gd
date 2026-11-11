extends Control
class_name WaypointMarker

var target_position: Vector3
var is_active : bool = false

func _ready() -> void:
	hide()

	MissionManager.order_started.connect(_on_order_started)
	MissionManager.order_completed.connect(_on_order_ended)
	MissionManager.order_abandoned.connect(_on_order_ended)

func _process(_delta: float) -> void:
	if not is_active:
		return
	var camera = get_viewport().get_camera_3d()
	if not camera: return

	if camera.is_position_behind(target_position): hide()
	else:
		show()
		var screen_pos = camera.unproject_position(target_position)
		position = screen_pos - (size/2.0)


func _on_order_started(order) -> void:
	if order and "destination_position" in order:
		target_position = order.destination_position
		is_active = true
		show()

func _on_order_ended(_order = null) -> void:
	is_active = false
	hide()

