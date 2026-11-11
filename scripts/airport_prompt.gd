extends Control
class_name AirportPrompt

@onready var icon: TextureRect = $VBoxContainer/PromptRow/Progress/HoldProgress/Icon
@onready var hold_progress: TextureProgressBar = $VBoxContainer/PromptRow/Progress/HoldProgress
@onready var prompt_label: Label = $VBoxContainer/PromptRow/Label

func setup(_hold_duration: float) -> void:
	prompt_label.text = "Activate Terminal"
	hold_progress.value = 0.0

func set_progress(progress: float) -> void:
	hold_progress.value = clampf(progress, 0.0, 1.0) * 100.0

func show_prompt() -> void:
	show()

func hide_prompt() -> void:
	hide()
	set_progress(0.0)
