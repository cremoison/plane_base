extends Area3D
class_name Airport

@export var airport_data: AirportConfig
@export var terminal_ui_scene: PackedScene
@export var prompt_ui_scene: PackedScene
@export_range(0.1, 5.0, 0.1) var confirm_hold_duration: float = 1.0

var is_player_inside: bool = false
var active_terminal: TerminalUI = null # current terminal ui istance
var prompt_ui: AirportPrompt = null
var confirm_hold_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if is_player_inside and not is_instance_valid(prompt_ui):
		_create_prompt()

	if not is_player_inside or is_instance_valid(active_terminal):
		return

	if is_instance_valid(prompt_ui) and not prompt_ui.visible:
		prompt_ui.show_prompt()

	if Input.is_action_pressed("confirm"):
		confirm_hold_time = min(confirm_hold_time + delta, confirm_hold_duration)
	else:
		confirm_hold_time = 0.0
	
	if is_instance_valid(prompt_ui):
		prompt_ui.set_progress(confirm_hold_time / confirm_hold_duration)

	if confirm_hold_time >= confirm_hold_duration:
		confirm_hold_time = 0.0
		if is_instance_valid(prompt_ui):
			prompt_ui.hide_prompt()
		if terminal_ui_scene == null:
			push_error("Terminal UI scene is not assigned on %s." % name)
			return

		active_terminal = terminal_ui_scene.instantiate() as TerminalUI
		if active_terminal == null:
			push_error("Terminal UI scene must instantiate a TerminalUI.")
			return

		get_tree().root.add_child(active_terminal)
		active_terminal.setup_terminal(airport_data)
		active_terminal.tree_exited.connect(_on_terminal_closed)

func _create_prompt() -> void:
	if prompt_ui_scene == null:
		push_error("Prompt UI scene is not assigned on %s." % name)
		return

	prompt_ui = prompt_ui_scene.instantiate() as AirportPrompt
	if prompt_ui == null:
		push_error("Prompt UI scene must instantiate an AirportPrompt.")
		return

	get_tree().root.add_child(prompt_ui)
	prompt_ui.setup(confirm_hold_duration)
	if is_player_inside:
		prompt_ui.show_prompt()
	else:
		prompt_ui.hide_prompt()

func _on_body_entered(body: Node3D) -> void:
	if body is AircraftPhysics:
		is_player_inside = true
		confirm_hold_time = 0.0
		if is_instance_valid(prompt_ui):
			prompt_ui.show_prompt()

func _on_body_exited(body: Node3D) -> void:
	if body is AircraftPhysics:
		is_player_inside = false
		confirm_hold_time = 0.0
		if is_instance_valid(prompt_ui):
			prompt_ui.hide_prompt()
		if is_instance_valid(active_terminal):
			active_terminal.queue_free()

func _on_terminal_closed():
	active_terminal = null

func _exit_tree() -> void:
	if is_instance_valid(prompt_ui):
		prompt_ui.queue_free()
