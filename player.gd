extends CharacterBody3D

@export var speed:float = 40

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var pitch_input = Input.get_axis("pitch_up", "pitch_down")
	var roll_input = Input.get_axis("roll_left", "roll_right")
	var yaw_input = Input.get_axis("yaw_left", "yaw_right")
	
	
