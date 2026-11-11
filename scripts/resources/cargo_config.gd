extends Resource
class_name CargoConfig

@export var cargo_name: String = "Cassa Standard"
@export var added_mass: float = 300.0 # kg added to plane _mass

@export var com_shift: Vector3 = Vector3.ZERO
@export var is_fragile: bool = false
