extends Control

@export var aircraft: AircraftPhysics # Riferimento al nuovo script dell'aereo

signal ui_shown
signal ui_hidden

# Valori di riferimento usati per i calcoli della UI
@export var max_thrust: float = 15000.0 # Deve combaciare con il max_thrust del Controller
@export var stall_speed_ms: float = 25.0 # Circa 48 nodi. Velocità sotto la quale scatta l'allarme

@onready var label_warning : Label = $label_warning
@onready var label_tas: Label = $label_tas
@onready var label_ground_speed: Label = $label_ground_speed

func _ready() -> void:
	label_warning.hide()
	label_warning.modulate.a = 0.0

	if aircraft:
		aircraft.warning_triggered.connect(show_warning)

func show_ui() -> void:
	if visible:
		return

	show()
	ui_shown.emit()

func hide_ui() -> void:
	if not visible:
		return

	hide()
	ui_hidden.emit()

func toggle_ui() -> void:
	if visible:
		hide_ui()
	else:
		show_ui()

func _process(_delta: float) -> void:
	if not aircraft:
		return

	# Cache delle variabili fisiche attuali
	var vel = aircraft.linear_velocity
	var pos = aircraft.global_position
	var current_throttle = aircraft.thrust / max_thrust
	var air_velocity = vel - aircraft.environment_wind
	var ground_velocity = Vector3(vel.x, 0.0, vel.z)

	# Nodo label_debug
	var debug_label = $label_debug as Label
	var info = "fps: %d\nposition: %s\nvelocity: %sm/s\nthrottle: %d%%\n" % [
		Engine.get_frames_per_second(), 
		pos, 
		vel, 
		int(current_throttle * 100.0)
	]
	debug_label.text = info

	# Velocita' rispetto all'aria e velocita' orizzontale rispetto al terreno
	label_tas.text = "TAS: %3d m/s" % [roundi(air_velocity.length())]
	label_ground_speed.text = "GS: %3d m/s" % [roundi(ground_velocity.length())]
	
	# Nodo label_vspeed 
	var vspeed_label = $label_vspeed as Label
	vspeed_label.text = "Vertical Speed: %3d m/s" % [vel.y] 

	# Nodo label_throttle
	var throttle_label = $label_throttle as Label
	throttle_label.text = "Throttle: %d%%" % [int(current_throttle * 100.0)]

	# Nodo label_alt
	var alt_label = $label_alt as Label
	alt_label.text = "Altitude: %5d m" % [pos.y]

	# Nodo label_stall
	var stall_label = $label_stall as Label
	# Mostra lo stallo solo se si è lenti E si è staccati da terra (es. > 10 metri)
	if vel.length() < stall_speed_ms and pos.y > 10.0:
		stall_label.visible = true
	else:
		stall_label.visible = false

func show_warning(message: String, duration: float = 3.0) -> void:
	label_warning.text = message
	label_warning.show()

	var tween = create_tween()

	tween.tween_property(label_warning, "modulate:a", 1.0, 0.1)
	tween.tween_property(label_warning, "modulate:a", 0.0, 0.5).set_delay(duration)
	tween.tween_callback(label_warning.hide)
